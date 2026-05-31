import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../app.dart';
import '../faq/faq_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Logout from your shop?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final shopCode = auth.user?.shopId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Shop $shopCode'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: kOrange,
          labelColor: kOrange,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'FAQ & References',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const FAQScreen(),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OrdersTab(shopCode: shopCode),
          const _AnalyticsTab(),
          _MenuTab(shopCode: shopCode),
          _SettingsTab(shopCode: shopCode),
        ],
      ),
    );
  }
}

// ─────────────────────────── ORDERS TAB ────────────────────────────────────

class _OrdersTab extends StatelessWidget {
  final String shopCode;
  const _OrdersTab({required this.shopCode});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final today = DateTime.now();
    final todayOrders = orders.orders.where((o) {
      final d = o.createdAt;
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).toList();
    final activeOrders = orders.orders
        .where((o) => o.status == 'pending' || o.status == 'preparing')
        .toList();
    final reservations = orders.orders
        .where((o) => o.isReservation && o.status == 'pending')
        .toList()
      ..sort((a, b) => a.scheduledFor!.compareTo(b.scheduledFor!));
    final revenue = todayOrders
        .where((o) => o.status != 'cancelled')
        .fold<double>(0, (s, o) => s + o.total);

    return RefreshIndicator(
      onRefresh: orders.fetchOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _StatCard(
                label: "Today's Orders",
                value: '${todayOrders.length}',
                icon: Icons.receipt,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _StatCard(
                label: 'Active',
                value: '${activeOrders.length}',
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _StatCard(
                label: 'Revenue',
                value: '\$${revenue.toStringAsFixed(2)}',
                icon: Icons.attach_money,
                color: kGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (reservations.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Colors.purple),
                const SizedBox(width: 6),
                const Text('Upcoming Reservations',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple)),
              ],
            ),
            const SizedBox(height: 8),
            ...reservations.map((o) => _OrderCard(order: o)),
            const SizedBox(height: 16),
          ],
          if (activeOrders.isNotEmpty) ...[
            const Text('Active Orders',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...activeOrders
                .where((o) => !o.isReservation)
                .map((o) => _OrderCard(order: o)),
            const SizedBox(height: 16),
          ],
          const Text('All Orders',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (orders.orders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No orders yet',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ...orders.orders.map((o) => _OrderCard(order: o)),
        ],
      ),
    );
  }
}

// ─────────────────────────── MENU TAB ──────────────────────────────────────

class _MenuTab extends StatefulWidget {
  final String shopCode;
  const _MenuTab({required this.shopCode});

  @override
  State<_MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<_MenuTab> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _shopUuid; // resolved from shop_code

  @override
  void initState() {
    super.initState();
    _resolveShopThenFetch();
  }

  // shopCode may be a UUID (from user_metadata.shop_id) or a shop_code like "A1"
  Future<void> _resolveShopThenFetch() async {
    setState(() => _loading = true);
    try {
      final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-').hasMatch(widget.shopCode);
      final col = isUuid ? 'id' : 'shop_code';
      final shop = await _db
          .from('shops')
          .select('id')
          .eq(col, widget.shopCode)
          .single();
      _shopUuid = shop['id'] as String;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not find shop: $e')));
      }
    }
    _fetch();
  }

  Future<void> _fetch() async {
    if (_shopUuid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await _db
          .from('menu_items')
          .select()
          .eq('shop_id', _shopUuid!)
          .order('name');
      setState(() => _items = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading menu: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await _db.from('menu_items').delete().eq('id', id);
    _fetch();
  }

  Future<void> _toggle(String id, bool current) async {
    await _db
        .from('menu_items')
        .update({'is_available': !current})
        .eq('id', id);
    _fetch();
  }

  void _openForm([Map<String, dynamic>? item]) async {
    if (_shopUuid == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MenuItemForm(
        shopUuid: _shopUuid!,
        item: item,
        onSaved: _fetch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: kOrange,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: _items.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No menu items yet',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  final available =
                      item['is_available'] as bool? ?? true;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: kBeige,
                        child: Text(
                          item['name']
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                          style: TextStyle(
                              color: kOrange,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(item['name'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '\$${(item['price'] as num).toStringAsFixed(2)}  ·  ${item['category'] ?? ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: available,
                            activeThumbColor: kGreen,
                            onChanged: (_) =>
                                _toggle(item['id'] as String,
                                    available),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 20, color: Colors.grey),
                            onPressed: () => _openForm(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 20, color: Colors.red),
                            onPressed: () =>
                                _delete(item['id'] as String),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ─────────────────── MENU ITEM FORM + DISCOUNT MANAGEMENT ──────────────────

class _MenuItemForm extends StatefulWidget {
  final String shopUuid;
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;

  const _MenuItemForm(
      {required this.shopUuid, this.item, required this.onSaved});

  @override
  State<_MenuItemForm> createState() => _MenuItemFormState();
}

class _MenuItemFormState extends State<_MenuItemForm> {
  final _db = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _cal;
  late final TextEditingController _prepTime;
  String _category = 'Main Course';
  bool _healthy = false;
  bool _special = false;
  bool _hideHealthyBadge = false;
  bool _hideUnhealthyBadge = false;
  bool _saving = false;
  List<Map<String, dynamic>> _discounts = [];
  bool _loadingDiscounts = false;

  static const _categories = [
    'Main Course',
    'Snacks',
    'Drinks',
    'Desserts',
    'Breakfast',
    'Salads',
  ];

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _name = TextEditingController(text: i?['name'] as String? ?? '');
    _desc =
        TextEditingController(text: i?['description'] as String? ?? '');
    _price = TextEditingController(
        text: i != null
            ? (i['price'] as num).toStringAsFixed(2)
            : '');
    _cal = TextEditingController(
        text: i?['calories']?.toString() ?? '');
    _prepTime = TextEditingController(
        text: i?['preparation_time']?.toString() ?? '15');
    _category = i?['category'] as String? ?? 'Main Course';
    _healthy = i?['is_healthy'] as bool? ?? false;
    _special = i?['is_special'] as bool? ?? false;
    _hideHealthyBadge = i?['hide_healthy_badge'] as bool? ?? false;
    _hideUnhealthyBadge = i?['hide_unhealthy_badge'] as bool? ?? false;
    if (widget.item != null) _loadDiscounts();
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _cal.dispose();
    _prepTime.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'shop_id': widget.shopUuid,
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'price': double.parse(_price.text),
      'category': _category,
      'calories': int.tryParse(_cal.text) ?? 0,
      'preparation_time': int.tryParse(_prepTime.text) ?? 15,
      'is_healthy': _healthy,
      'is_special': _special,
      'hide_healthy_badge': _hideHealthyBadge,
      'hide_unhealthy_badge': _hideUnhealthyBadge,
      'is_available': true,
    };
    try {
      if (widget.item != null) {
        await _db
            .from('menu_items')
            .update(data)
            .eq('id', widget.item!['id'] as String);
      } else {
        await _db.from('menu_items').insert(data);
      }
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadDiscounts() async {
    setState(() => _loadingDiscounts = true);
    try {
      final list =
          await ApiService.getItemDiscounts(widget.item!['id'] as String);
      if (mounted) setState(() => _discounts = list);
    } finally {
      if (mounted) setState(() => _loadingDiscounts = false);
    }
  }

  Future<void> _addDiscount() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _DiscountDialog(),
    );
    if (result == null) return;
    try {
      await ApiService.addItemDiscount(
        menuItemId: widget.item!['id'] as String,
        label: result['label'] as String,
        discountPercent: result['percent'] as double,
        daysOfWeek: result['days'] as List<int>,
        startTime: result['start'] as String,
        endTime: result['end'] as String,
      );
      _loadDiscounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteDiscount(String id) async {
    await ApiService.deleteItemDiscount(id);
    _loadDiscounts();
  }

  Future<void> _toggleDiscount(String id, bool current) async {
    await ApiService.toggleItemDiscount(id, isActive: !current);
    _loadDiscounts();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editing ? 'Edit Item' : 'Add Menu Item',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration:
                    const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      decoration:
                          const InputDecoration(labelText: 'Price * (\$)'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cal,
                      decoration:
                          const InputDecoration(labelText: 'Calories'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _category,
                      decoration:
                          const InputDecoration(labelText: 'Category'),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _category = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _prepTime,
                      decoration: const InputDecoration(
                          labelText: 'Prep time (min)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Healthy',
                    style: TextStyle(fontSize: 13)),
                value: _healthy,
                activeThumbColor: kGreen,
                onChanged: (v) => setState(() => _healthy = v),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 24),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('Badge overrides',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ),
              SwitchListTile(
                title: const Text('Hide Healthy badge',
                    style: TextStyle(fontSize: 13)),
                subtitle: const Text(
                    'Suppress the green leaf even if item is marked Healthy.',
                    style: TextStyle(fontSize: 11)),
                value: _hideHealthyBadge,
                activeThumbColor: Colors.grey,
                onChanged: (v) => setState(() => _hideHealthyBadge = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Hide Unhealthy badge',
                    style: TextStyle(fontSize: 13)),
                subtitle: const Text(
                    "Suppress the auto-classifier's orange label for this item.",
                    style: TextStyle(fontSize: 11)),
                value: _hideUnhealthyBadge,
                activeThumbColor: Colors.grey,
                onChanged: (v) => setState(() => _hideUnhealthyBadge = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(editing ? 'Save Changes' : 'Add to Menu',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),

              if (editing) ...[
                const SizedBox(height: 24),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_offer, size: 16, color: kOrange),
                        SizedBox(width: 6),
                        Text('Promotion Schemes',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _addDiscount,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style:
                          TextButton.styleFrom(foregroundColor: kOrange),
                    ),
                  ],
                ),
                if (_loadingDiscounts)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_discounts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No promotion schemes yet. Add one to offer time-limited deals.',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                  )
                else
                  ..._discounts.map((d) => _DiscountTile(
                        discount: d,
                        onToggle: () => _toggleDiscount(
                            d['id'] as String,
                            d['is_active'] as bool? ?? true),
                        onDelete: () =>
                            _deleteDiscount(d['id'] as String),
                      )),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── DISCOUNT SCHEDULE WIDGETS ─────────────────────────

class _DiscountTile extends StatelessWidget {
  final Map<String, dynamic> discount;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _DiscountTile({
    required this.discount,
    required this.onToggle,
    required this.onDelete,
  });

  static const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  String _formatDays(List days) {
    final sorted = days.map((d) => (d as num).toInt()).toList()..sort();
    if (sorted.length == 5 && sorted.first == 1 && sorted.last == 5) {
      return 'Mon–Fri';
    }
    if (sorted.length == 6 && sorted.first == 1 && sorted.last == 6) {
      return 'Mon–Sat';
    }
    return sorted.map((d) => _dayNames[d]).join(', ');
  }

  String _fmtTime(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = discount['is_active'] as bool? ?? true;
    final pct =
        (discount['discount_percent'] as num).toStringAsFixed(0);
    final label = discount['label'] as String? ?? 'Deal';
    final days =
        _formatDays(discount['days_of_week'] as List? ?? []);
    final start = _fmtTime(discount['start_time'] as String);
    final end = _fmtTime(discount['end_time'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? kOrange.withValues(alpha: 0.06)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isActive
                ? kOrange.withValues(alpha: 0.3)
                : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('-$pct%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$days  ·  $start – $end',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeThumbColor: kOrange,
            onChanged: (_) => onToggle(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog();

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  final _labelCtrl =
      TextEditingController(text: 'Lunch Special');
  final _pctCtrl = TextEditingController(text: '20');
  TimeOfDay _start = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 13, minute: 0);
  final Set<int> _days = {1, 2, 3, 4, 5}; // Mon–Fri

  static const _dayLabels = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  ];

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _labelCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Promotion Scheme'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                  labelText: 'Label (e.g. Lunch Special)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pctCtrl,
              decoration: const InputDecoration(
                  labelText: 'Discount %', suffixText: '%'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
            const SizedBox(height: 16),
            const Text('Days',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: List.generate(7, (i) {
                final selected = _days.contains(i);
                return FilterChip(
                  label: Text(_dayLabels[i],
                      style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? Colors.white
                              : Colors.black87)),
                  selected: selected,
                  selectedColor: kOrange,
                  checkmarkColor: Colors.white,
                  onSelected: (v) => setState(
                      () => v ? _days.add(i) : _days.remove(i)),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'From',
                    time: _start.format(context),
                    onTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: _start);
                      if (t != null) setState(() => _start = t);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeButton(
                    label: 'To',
                    time: _end.format(context),
                    onTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: _end);
                      if (t != null) setState(() => _end = t);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final pct = double.tryParse(_pctCtrl.text);
            if (pct == null || pct < 1 || pct > 100) return;
            if (_days.isEmpty) return;
            if (_start.hour * 60 + _start.minute >=
                _end.hour * 60 + _end.minute) {
              return;
            }
            Navigator.pop(context, {
              'label': _labelCtrl.text.trim().isEmpty
                  ? 'Deal'
                  : _labelCtrl.text.trim(),
              'percent': pct,
              'days': _days.toList(),
              'start': _fmt(_start),
              'end': _fmt(_end),
            });
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: kOrange),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  const _TimeButton(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(time,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── SETTINGS TAB ──────────────────────────────────

class _SettingsTab extends StatefulWidget {
  final String shopCode;
  const _SettingsTab({required this.shopCode});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _db = Supabase.instance.client;
  Map<String, dynamic>? _shop;
  bool _loading = true;
  bool _saving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _discountCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _discountCtrl = TextEditingController();
    _fetch();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  bool get _isUuid =>
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-').hasMatch(widget.shopCode);

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final col = _isUuid ? 'id' : 'shop_code';
      final data = await _db
          .from('shops')
          .select()
          .eq(col, widget.shopCode)
          .single();
      setState(() {
        _shop = data;
        _nameCtrl.text = data['name'] as String? ?? '';
        _descCtrl.text = data['description'] as String? ?? '';
        _discountCtrl.text =
            (data['discount_percent'] as num? ?? 0).toStringAsFixed(0);
      });
    } catch (e) {
      // shop not found
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleOpen() async {
    if (_shop == null) return;
    final newVal = !(_shop!['is_active'] as bool? ?? true);
    final col = _isUuid ? 'id' : 'shop_code';
    await _db
        .from('shops')
        .update({'is_active': newVal})
        .eq(col, widget.shopCode);
    setState(() => _shop!['is_active'] = newVal);
  }

  Future<void> _saveInfo() async {
    setState(() => _saving = true);
    try {
      final col = _isUuid ? 'id' : 'shop_code';
      await _db
          .from('shops')
          .update({
            'name': _nameCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'discount_percent': double.tryParse(_discountCtrl.text) ?? 0,
          })
          .eq(col, widget.shopCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final isOpen = _shop?['is_active'] as bool? ?? true;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOpen ? kGreen : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOpen ? 'Shop is OPEN' : 'Shop is CLOSED',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOpen ? kGreen : Colors.red,
                        ),
                      ),
                      Text(
                        isOpen
                            ? 'Customers can place orders'
                            : 'No new orders will be accepted',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOpen,
                  activeThumbColor: kGreen,
                  onChanged: (_) => _toggleOpen(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Shop Info',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Shop Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descCtrl,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _discountCtrl,
          decoration: const InputDecoration(
            labelText: 'Shop-wide Discount %',
            border: OutlineInputBorder(),
            suffixText: '%',
            helperText: '0 = no discount',
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Save Changes',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 8),
        Text('Shop ID: ${widget.shopCode}',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text('Campus: ${_shop?['campus'] ?? ''}',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

// ─────────────────────────── SHARED WIDGETS ─────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final orders = context.read<OrderProvider>();
    final color = _statusColor(order.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                _StatusBadge(status: order.status, color: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d – h:mm a')
                  .format(order.createdAt.toLocal()),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (order.isReservation) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 13, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text(
                    'Pickup: ${DateFormat('h:mm a').format(order.scheduledFor!.toLocal())}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            Text('Customer: ${order.studentName}',
                style: const TextStyle(fontSize: 13)),
            const Divider(height: 12),
            ...order.items.map((item) => Text(
                '${item.quantity}× ${item.name}',
                style: const TextStyle(fontSize: 13))),
            const SizedBox(height: 4),
            Text('Total: \$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (order.cancelReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Reason: ${order.cancelReason}',
                    style: const TextStyle(
                        color: Colors.red, fontSize: 12)),
              ),
            if (order.status != 'completed' &&
                order.status != 'cancelled') ...[
              const SizedBox(height: 10),
              _ActionButtons(order: order, ordersProvider: orders),
            ]
          ],
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return kGreen;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Order order;
  final OrderProvider ordersProvider;

  const _ActionButtons(
      {required this.order, required this.ordersProvider});

  @override
  Widget build(BuildContext context) {
    if (order.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style:
                  OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => _showCancelDialog(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  ordersProvider.updateStatus(order.id, 'preparing'),
              child: const Text('Start Prep'),
            ),
          ),
        ],
      );
    }
    if (order.status == 'preparing') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () =>
              ordersProvider.updateStatus(order.id, 'ready'),
          icon: const Icon(Icons.check_circle),
          label: const Text('Mark Ready'),
        ),
      );
    }
    if (order.status == 'ready') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () =>
              ordersProvider.updateStatus(order.id, 'completed'),
          icon: const Icon(Icons.done_all),
          label: const Text('Mark Completed'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Back')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel Order',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      ordersProvider.updateStatus(order.id, 'cancelled',
          cancelReason:
              ctrl.text.isNotEmpty ? ctrl.text : null);
    }
  }
}

// ─────────────────────────── ANALYTICS TAB ─────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 6));

    bool inLast7(Order o) => !o.createdAt.toLocal().isBefore(weekStart);

    final orders7d = orders.where(inLast7).toList();
    final completed7d =
        orders7d.where((o) => o.status == 'completed').toList();
    final cancelled7d =
        orders7d.where((o) => o.status == 'cancelled').toList();
    final revenue7d =
        completed7d.fold<double>(0, (s, o) => s + o.total);
    final avgOrderValue =
        completed7d.isEmpty ? 0.0 : revenue7d / completed7d.length;
    final cancelRate = orders7d.isEmpty
        ? 0.0
        : (cancelled7d.length / orders7d.length) * 100;

    // 7-day revenue
    final days = List<_SellerDay>.generate(7, (i) {
      final d = todayStart.subtract(Duration(days: 6 - i));
      return _SellerDay(date: d, label: DateFormat('EEE').format(d));
    });
    for (final o in orders) {
      if (o.status != 'completed') continue;
      final d = o.createdAt.toLocal();
      final key = DateTime(d.year, d.month, d.day);
      for (final b in days) {
        if (b.date == key) b.revenue += o.total;
      }
    }

    // Top selling items (lifetime, exclude cancelled)
    final qtyByItem = <String, int>{};
    final revByItem = <String, double>{};
    for (final o in orders) {
      if (o.status == 'cancelled') continue;
      for (final it in o.items) {
        qtyByItem[it.name] = (qtyByItem[it.name] ?? 0) + it.quantity;
        revByItem[it.name] =
            (revByItem[it.name] ?? 0) + it.price * it.quantity;
      }
    }
    final top = qtyByItem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topList = top.take(5).toList();

    // Service split (last 7 days, non-cancelled) — Flutter Order model
    // has no service type, so just count reservation vs immediate as a proxy
    int reservation = 0, immediate = 0;
    for (final o in orders7d.where((o) => o.status != 'cancelled')) {
      if (o.isReservation) {
        reservation += 1;
      } else {
        immediate += 1;
      }
    }

    // Peak hours, last 7 days (6am..10pm)
    final hourBuckets = List<int>.filled(24, 0);
    for (final o in orders7d.where((o) => o.status != 'cancelled')) {
      final h = o.createdAt.toLocal().hour;
      hourBuckets[h] += 1;
    }
    final peakHours = <_HourBucket>[];
    for (int h = 6; h < 22; h++) {
      final lbl = h == 0
          ? '12am'
          : h < 12
              ? '${h}am'
              : h == 12
                  ? '12pm'
                  : '${h - 12}pm';
      peakHours.add(_HourBucket(label: lbl, count: hourBuckets[h]));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI grid
        Row(
          children: [
            Expanded(
                child: _SellerKpi(
                    label: 'Revenue 7d',
                    value: '\$${revenue7d.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: kGreen)),
            const SizedBox(width: 8),
            Expanded(
                child: _SellerKpi(
                    label: 'Orders 7d',
                    value: '${orders7d.length}',
                    icon: Icons.shopping_bag,
                    color: kOrange)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _SellerKpi(
                    label: 'Avg Order',
                    value: '\$${avgOrderValue.toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: Colors.blue.shade600)),
            const SizedBox(width: 8),
            Expanded(
                child: _SellerKpi(
                    label: 'Cancel %',
                    value: '${cancelRate.toStringAsFixed(1)}%',
                    icon: Icons.cancel,
                    color: Colors.red)),
          ],
        ),
        const SizedBox(height: 20),

        // Revenue trend
        _SellerSectionTitle(
            icon: Icons.show_chart,
            iconColor: kGreen,
            title: 'Revenue — Last 7 Days',
            subtitle: 'Completed orders only'),
        _SellerChartCard(
          child: SizedBox(
            height: 180,
            child: BarChart(_revenueChart(days)),
          ),
        ),

        const SizedBox(height: 20),

        // Top items
        _SellerSectionTitle(
            icon: Icons.emoji_events,
            iconColor: kOrange,
            title: 'Top Selling Items',
            subtitle: 'By quantity sold (all-time)'),
        _SellerChartCard(
          child: topList.isEmpty
              ? const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('No sales yet.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              : Column(
                  children: topList.map((e) {
                    final qty = e.value;
                    final rev = revByItem[e.key] ?? 0;
                    final maxQty = topList.first.value;
                    final pct = qty / maxQty;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(e.key,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text('$qty sold · \$${rev.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade100,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(kOrange),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 20),

        // Reservation vs immediate split
        _SellerSectionTitle(
            icon: Icons.event,
            iconColor: Colors.blue.shade600,
            title: 'Reservations vs Walk-in',
            subtitle: 'Last 7 days'),
        _SellerChartCard(
          child: (reservation + immediate) == 0
              ? const SizedBox(
                  height: 140,
                  child: Center(
                    child: Text('No orders in the last 7 days.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              : SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 32,
                            sectionsSpace: 2,
                            sections: [
                              PieChartSectionData(
                                value: reservation.toDouble(),
                                color: const Color(0xFF7C3AED),
                                title: '$reservation',
                                radius: 46,
                                titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                              PieChartSectionData(
                                value: immediate.toDouble(),
                                color: kOrange,
                                title: '$immediate',
                                radius: 46,
                                titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendDot(
                              color: const Color(0xFF7C3AED),
                              label: 'Reservation',
                              value: '$reservation'),
                          const SizedBox(height: 6),
                          _LegendDot(
                              color: kOrange,
                              label: 'Walk-in',
                              value: '$immediate'),
                        ],
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
        ),

        const SizedBox(height: 20),

        // Peak hours
        _SellerSectionTitle(
            icon: Icons.access_time,
            iconColor: const Color(0xFF9333EA),
            title: 'Peak Hours',
            subtitle: 'Orders by hour-of-day · last 7 days'),
        _SellerChartCard(
          child: SizedBox(
            height: 180,
            child: BarChart(_peakChart(peakHours)),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  BarChartData _revenueChart(List<_SellerDay> days) {
    final maxRev = days.fold<double>(0, (m, d) => d.revenue > m ? d.revenue : m);
    final upper = (maxRev == 0 ? 10 : maxRev * 1.2).ceilToDouble();
    return BarChartData(
      maxY: upper,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (v, _) => Text('\$${v.toInt()}',
                style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              final i = value.toInt();
              if (i < 0 || i >= days.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(days[i].label,
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              );
            },
          ),
        ),
      ),
      barGroups: List.generate(days.length, (i) {
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: days[i].revenue,
            color: kGreen,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ]);
      }),
    );
  }

  BarChartData _peakChart(List<_HourBucket> hours) {
    final maxC = hours.fold<int>(0, (m, h) => h.count > m ? h.count : m);
    final upper = (maxC == 0 ? 5 : (maxC * 1.2)).ceilToDouble();
    return BarChartData(
      maxY: upper,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 1,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              final i = value.toInt();
              if (i < 0 || i >= hours.length || i % 2 != 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(hours[i].label,
                    style: const TextStyle(fontSize: 9, color: Colors.grey)),
              );
            },
          ),
        ),
      ),
      barGroups: List.generate(hours.length, (i) {
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: hours[i].count.toDouble(),
            color: const Color(0xFF9333EA),
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ]);
      }),
    );
  }
}

class _SellerDay {
  final DateTime date;
  final String label;
  double revenue = 0;
  _SellerDay({required this.date, required this.label});
}

class _HourBucket {
  final String label;
  final int count;
  const _HourBucket({required this.label, required this.count});
}

class _SellerKpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SellerKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerSectionTitle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _SellerSectionTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class _SellerChartCard extends StatelessWidget {
  final Widget child;
  const _SellerChartCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(value,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
