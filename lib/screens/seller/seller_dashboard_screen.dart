import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../app.dart';

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
    _tabs = TabController(length: 3, vsync: this);
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
    final shopId = auth.user?.shopId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Shop ${auth.user?.shopId ?? ''}'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: kOrange,
          labelColor: kOrange,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OrdersTab(shopId: shopId),
          _MenuTab(shopId: shopId),
          _SettingsTab(shopId: shopId),
        ],
      ),
    );
  }
}

// ─────────────────────────── ORDERS TAB ────────────────────────────────────

class _OrdersTab extends StatelessWidget {
  final String shopId;
  const _OrdersTab({required this.shopId});

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
          if (activeOrders.isNotEmpty) ...[
            const Text('Active Orders',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...activeOrders.map((o) => _OrderCard(order: o)),
            const SizedBox(height: 16),
          ],
          const Text('All Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
  final String shopId;
  const _MenuTab({required this.shopId});

  @override
  State<_MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<_MenuTab> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final data = await _db
          .from('menu_items')
          .select()
          .eq('shop_id', widget.shopId)
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
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MenuItemForm(
        shopId: widget.shopId,
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

class _MenuItemForm extends StatefulWidget {
  final String shopId;
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;

  const _MenuItemForm(
      {required this.shopId, this.item, required this.onSaved});

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
  bool _saving = false;

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
      'shop_id': widget.shopId,
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'price': double.parse(_price.text),
      'category': _category,
      'calories': int.tryParse(_cal.text) ?? 0,
      'preparation_time': int.tryParse(_prepTime.text) ?? 15,
      'is_healthy': _healthy,
      'is_special': _special,
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
                      initialValue: _category,
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
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Healthy',
                          style: TextStyle(fontSize: 13)),
                      value: _healthy,
                      activeThumbColor: kGreen,
                      onChanged: (v) => setState(() => _healthy = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Special (30% off)',
                          style: TextStyle(fontSize: 13)),
                      value: _special,
                      activeThumbColor: kOrange,
                      onChanged: (v) => setState(() => _special = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── SETTINGS TAB ──────────────────────────────────

class _SettingsTab extends StatefulWidget {
  final String shopId;
  const _SettingsTab({required this.shopId});

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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _fetch();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final data = await _db
          .from('shops')
          .select()
          .eq('shop_code', widget.shopId)
          .single();
      setState(() {
        _shop = data;
        _nameCtrl.text = data['name'] as String? ?? '';
        _descCtrl.text = data['description'] as String? ?? '';
      });
    } catch (e) {
      // shop not found — shouldn't happen
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleOpen() async {
    if (_shop == null) return;
    final newVal = !(_shop!['is_active'] as bool? ?? true);
    await _db
        .from('shops')
        .update({'is_active': newVal})
        .eq('shop_code', widget.shopId);
    setState(() => _shop!['is_active'] = newVal);
  }

  Future<void> _saveInfo() async {
    setState(() => _saving = true);
    try {
      await _db
          .from('shops')
          .update({
            'name': _nameCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
          })
          .eq('shop_code', widget.shopId);
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
        // Open / Closed toggle
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

        // Shop info
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
        Text('Shop ID: ${widget.shopId}',
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
