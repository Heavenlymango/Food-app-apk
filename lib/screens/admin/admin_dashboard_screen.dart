import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _shops = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _classBreaks = [];
  Map<String, dynamic> _settings = {};

  bool _loading = false;
  String _userSearch = '';
  String _userRoleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _adminFetch(String path,
      {String method = 'GET', Map<String, dynamic>? body}) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    late http.Response res;
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    if (method == 'POST') {
      res = await http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
    } else if (method == 'DELETE') {
      res = await http.delete(uri, headers: headers);
    } else {
      res = await http.get(uri, headers: headers);
    }
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception((data is Map ? data['error'] : null) ?? 'HTTP ${res.statusCode}');
    }
    return data is Map ? Map<String, dynamic>.from(data) : {'data': data};
  }

  Future<List<Map<String, dynamic>>> _adminFetchList(String path) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final res = await http.get(uri, headers: headers);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception((data is Map ? data['error'] : null) ?? 'HTTP ${res.statusCode}');
    }
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return [];
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _adminFetch('/admin/stats/db').catchError((_) => _adminFetch('/admin/stats')),
        _adminFetchList('/admin/users'),
        _adminFetchList('/admin/shops'),
        _adminFetchList('/admin/orders?limit=50'),
        _adminFetch('/admin/settings'),
        _loadClassBreaks(),
      ]);
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _users = results[1] as List<Map<String, dynamic>>;
        _shops = results[2] as List<Map<String, dynamic>>;
        _orders = results[3] as List<Map<String, dynamic>>;
        _settings = results[4] as Map<String, dynamic>;
      });
    } catch (e) {
      _snack('Failed to load data: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadClassBreaks() async {
    try {
      final db = Supabase.instance.client;
      final data = await db.from('class_breaks').select().order('campus').order('break_start');
      final breaks = List<Map<String, dynamic>>.from(data);
      setState(() => _classBreaks = breaks);
      return breaks;
    } catch (_) {
      return [];
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : kOrange,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield, color: Color(0xFF2563EB), size: 22),
            SizedBox(width: 8),
            Text('Admin Dashboard', style: TextStyle(fontSize: 17)),
          ],
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Logout from admin?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (ok == true && mounted) auth.logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: kOrange,
          labelColor: kOrange,
          unselectedLabelColor: Colors.grey,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.people, size: 18), text: 'Users'),
            Tab(icon: Icon(Icons.store, size: 18), text: 'Shops'),
            Tab(icon: Icon(Icons.schedule, size: 18), text: 'Breaks'),
            Tab(icon: Icon(Icons.settings, size: 18), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(stats: _stats, orders: _orders),
          _UsersTab(
            users: _users,
            search: _userSearch,
            roleFilter: _userRoleFilter,
            onSearchChanged: (v) => setState(() => _userSearch = v),
            onRoleChanged: (v) => setState(() => _userRoleFilter = v),
            onToggle: _toggleUser,
            onDelete: _deleteUser,
            onAdd: _showAddUser,
          ),
          _ShopsTab(shops: _shops, onToggle: _toggleShop, onAdd: _showAddShop),
          _ClassBreaksTab(breaks: _classBreaks, onRefresh: _loadClassBreaks, onAdd: _showAddBreak, onDelete: _deleteBreak, onToggle: _toggleBreak),
          _SettingsTab(
            settings: _settings,
            onChanged: (k, v) => setState(() => _settings[k] = v),
            onSave: _saveSettings,
            onBroadcast: _showBroadcast,
          ),
        ],
      ),
    );
  }

  // ── User actions ────────────────────────────────────────────────────────────

  Future<void> _toggleUser(String userId, bool current) async {
    try {
      await _adminFetch('/admin/users/$userId/toggle-status',
          method: 'POST', body: {'isActive': !current});
      _snack(current ? 'User deactivated' : 'User activated');
      _loadAll();
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  Future<void> _deleteUser(String userId, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _adminFetch('/admin/users/$userId', method: 'DELETE');
      _snack('User deleted');
      _loadAll();
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  void _showAddUser() {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final shopCode = TextEditingController();
    String role = 'seller';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add User'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(name, 'Full Name'),
              const SizedBox(height: 10),
              _field(email, 'Email', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _field(password, 'Password', obscure: true),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: role,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'seller', child: Text('Seller')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setS(() => role = v!),
              ),
              if (role == 'seller') ...[
                const SizedBox(height: 10),
                _field(shopCode, 'Shop Code (e.g. A1)'),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (name.text.isEmpty || email.text.isEmpty || password.text.isEmpty) {
                  _snack('Name, email and password required', error: true);
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _adminFetch('/admin/users/create', method: 'POST', body: {
                    'name': name.text.trim(),
                    'email': email.text.trim(),
                    'password': password.text,
                    'role': role,
                    if (shopCode.text.isNotEmpty) 'shopCode': shopCode.text.toUpperCase(),
                  });
                  _snack('User created');
                  _loadAll();
                } catch (e) {
                  _snack('$e', error: true);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shop actions ────────────────────────────────────────────────────────────

  Future<void> _toggleShop(String shopId, bool current) async {
    try {
      await _adminFetch('/admin/shops/$shopId/toggle-status',
          method: 'POST', body: {'isActive': !current});
      _snack(current ? 'Shop deactivated' : 'Shop activated');
      _loadAll();
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  void _showAddShop() {
    final name = TextEditingController();
    final shopCode = TextEditingController();
    final category = TextEditingController();
    final description = TextEditingController();
    String campus = 'RUPP';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Shop'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(name, 'Shop Name'),
              const SizedBox(height: 10),
              _field(shopCode, 'Shop Code (e.g. A3)'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: campus,
                decoration: const InputDecoration(labelText: 'Campus', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'RUPP', child: Text('RUPP')),
                  DropdownMenuItem(value: 'IFL', child: Text('IFL')),
                ],
                onChanged: (v) => setS(() => campus = v!),
              ),
              const SizedBox(height: 10),
              _field(category, 'Category (optional)'),
              const SizedBox(height: 10),
              _field(description, 'Description (optional)', maxLines: 2),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (name.text.isEmpty || shopCode.text.isEmpty) {
                  _snack('Name and shop code required', error: true);
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _adminFetch('/admin/shops/create', method: 'POST', body: {
                    'name': name.text.trim(),
                    'shopCode': shopCode.text.toUpperCase(),
                    'campus': campus,
                    if (category.text.isNotEmpty) 'category': category.text.trim(),
                    if (description.text.isNotEmpty) 'description': description.text.trim(),
                  });
                  _snack('Shop created');
                  _loadAll();
                } catch (e) {
                  _snack('$e', error: true);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Class break actions ─────────────────────────────────────────────────────

  Future<void> _deleteBreak(String id) async {
    try {
      await Supabase.instance.client.from('class_breaks').delete().eq('id', id);
      _snack('Break deleted');
      _loadClassBreaks();
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  Future<void> _toggleBreak(String id, bool current) async {
    try {
      await Supabase.instance.client
          .from('class_breaks')
          .update({'is_active': !current}).eq('id', id);
      _snack(current ? 'Break disabled' : 'Break enabled');
      _loadClassBreaks();
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  void _showAddBreak() {
    String campus = 'RUPP';
    int dow = 1;
    final label = TextEditingController();
    final startTime = TextEditingController(text: '10:00');
    final endTime = TextEditingController(text: '10:30');

    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Class Break'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: campus,
                decoration: const InputDecoration(labelText: 'Campus', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'RUPP', child: Text('RUPP')),
                  DropdownMenuItem(value: 'IFL', child: Text('IFL')),
                ],
                onChanged: (v) => setS(() => campus = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                // ignore: deprecated_member_use
                value: dow,
                decoration: const InputDecoration(labelText: 'Day of Week', border: OutlineInputBorder()),
                items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text(days[i]))),
                onChanged: (v) => setS(() => dow = v!),
              ),
              const SizedBox(height: 10),
              _field(label, 'Label (e.g. Morning Break)'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field(startTime, 'Start (HH:MM)')),
                const SizedBox(width: 8),
                Expanded(child: _field(endTime, 'End (HH:MM)')),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (startTime.text.isEmpty || endTime.text.isEmpty) {
                  _snack('Start and end times required', error: true);
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await Supabase.instance.client.from('class_breaks').insert({
                    'campus': campus,
                    'day_of_week': dow,
                    'label': label.text.trim().isNotEmpty ? label.text.trim() : null,
                    'break_start': '${startTime.text}:00',
                    'break_end': '${endTime.text}:00',
                    'is_active': true,
                  });
                  _snack('Break added');
                  _loadClassBreaks();
                } catch (e) {
                  _snack('$e', error: true);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Settings ────────────────────────────────────────────────────────────────

  Future<void> _saveSettings() async {
    try {
      await _adminFetch('/admin/settings', method: 'POST', body: _settings);
      _snack('Settings saved');
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  void _showBroadcast() {
    final title = TextEditingController();
    final message = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Broadcast Announcement'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(title, 'Title'),
          const SizedBox(height: 10),
          _field(message, 'Message', maxLines: 4),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (title.text.isEmpty || message.text.isEmpty) {
                _snack('Title and message required', error: true);
                return;
              }
              Navigator.pop(ctx);
              try {
                final res = await _adminFetch('/admin/broadcast', method: 'POST', body: {
                  'title': title.text.trim(),
                  'message': message.text.trim(),
                });
                _snack('Sent to ${res['sent'] ?? 'all'} users');
              } catch (e) {
                _snack('$e', error: true);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType? keyboardType, bool obscure = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> orders;

  const _OverviewTab({required this.stats, required this.orders});

  @override
  Widget build(BuildContext context) {
    final statCards = [
      ('Total Users', stats['totalUsers'] ?? 0, Icons.people),
      ('Active Shops', stats['totalShops'] ?? 0, Icons.store),
      ('Total Orders', stats['totalOrders'] ?? 0, Icons.shopping_bag),
      ('Revenue', '\$${((stats['totalRevenue'] as num?) ?? 0).toStringAsFixed(2)}', Icons.attach_money),
      ('Active Orders', stats['activeOrders'] ?? 0, Icons.trending_up),
      ("Today's Orders", stats['todayOrders'] ?? 0, Icons.today),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: statCards.map((c) => _StatCard(label: c.$1, value: '${c.$2}', icon: c.$3)).toList(),
        ),
        const SizedBox(height: 16),
        const Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        ...orders.take(15).map((o) => _OrderTile(order: o)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: kOrange, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderTile({required this.order});

  Color _statusColor(String status) {
    return switch (status) {
      'completed' => Colors.green,
      'ready' => Colors.blue,
      'preparing' => Colors.orange,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? '';
    final total = ((order['totalAmount'] as num?) ?? (order['total'] as num?) ?? 0).toStringAsFixed(2);
    final orderNum = order['orderNumber'] ?? order['order_number'] ?? (order['id'] as String? ?? '').substring(0, 8.clamp(0, (order['id'] as String? ?? '').length));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text('#$orderNum', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Text(order['studentName'] as String? ?? 'N/A', style: const TextStyle(fontSize: 13))),
          Text('\$$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status, style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Users Tab ─────────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final String search;
  final String roleFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRoleChanged;
  final Function(String, bool) onToggle;
  final Function(String, String) onDelete;
  final VoidCallback onAdd;

  const _UsersTab({
    required this.users,
    required this.search,
    required this.roleFilter,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = users.where((u) {
      final name = (u['name'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      final role = u['role'] as String? ?? '';
      final matchSearch = name.contains(search.toLowerCase()) || email.contains(search.toLowerCase());
      final matchRole = roleFilter == 'all' || role == roleFilter;
      return matchSearch && matchRole;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search name or email…',
                    prefixIcon: Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: roleFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'student', child: Text('Students')),
                  DropdownMenuItem(value: 'seller', child: Text('Sellers')),
                  DropdownMenuItem(value: 'admin', child: Text('Admins')),
                ],
                onChanged: (v) => onRoleChanged(v!),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${filtered.length} users', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add User'),
                style: FilledButton.styleFrom(backgroundColor: kOrange, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final u = filtered[i];
              final isActive = u['isActive'] as bool? ?? true;
              final role = u['role'] as String? ?? 'student';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: role == 'admin'
                        ? Colors.blue.shade100
                        : role == 'seller'
                            ? kOrange.withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                    child: Icon(
                      role == 'admin' ? Icons.shield : role == 'seller' ? Icons.store : Icons.person,
                      size: 18,
                      color: role == 'admin' ? Colors.blue : role == 'seller' ? kOrange : Colors.grey,
                    ),
                  ),
                  title: Text(u['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(u['email'] as String? ?? '', style: const TextStyle(fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Off',
                          style: TextStyle(fontSize: 10, color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: Icon(isActive ? Icons.person_off : Icons.person, size: 18, color: Colors.orange),
                        onPressed: () => onToggle(u['id'] as String, isActive),
                        tooltip: isActive ? 'Deactivate' : 'Activate',
                      ),
                      if (role != 'admin')
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => onDelete(u['id'] as String, u['name'] as String? ?? ''),
                          tooltip: 'Delete',
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Shops Tab ─────────────────────────────────────────────────────────────────

class _ShopsTab extends StatelessWidget {
  final List<Map<String, dynamic>> shops;
  final Function(String, bool) onToggle;
  final VoidCallback onAdd;

  const _ShopsTab({required this.shops, required this.onToggle, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${shops.length} shops', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Shop'),
                style: FilledButton.styleFrom(backgroundColor: kOrange, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: shops.length,
            itemBuilder: (_, i) {
              final s = shops[i];
              final isActive = s['isActive'] as bool? ?? true;
              final shopId = s['id'] as String? ?? s['shopCode'] as String? ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: kOrange.withValues(alpha: 0.1),
                    child: Icon(Icons.store, size: 18, color: kOrange),
                  ),
                  title: Text(s['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('$shopId · ${s['campus'] ?? ''} · ${s['category'] ?? '—'}', style: const TextStyle(fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Off',
                          style: TextStyle(fontSize: 10, color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: Icon(isActive ? Icons.toggle_on : Icons.toggle_off, size: 20, color: isActive ? kOrange : Colors.grey),
                        onPressed: () => onToggle(shopId, isActive),
                        tooltip: isActive ? 'Deactivate' : 'Activate',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Class Breaks Tab ──────────────────────────────────────────────────────────

class _ClassBreaksTab extends StatelessWidget {
  final List<Map<String, dynamic>> breaks;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;
  final Function(String) onDelete;
  final Function(String, bool) onToggle;

  const _ClassBreaksTab({
    required this.breaks,
    required this.onRefresh,
    required this.onAdd,
    required this.onDelete,
    required this.onToggle,
  });

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${breaks.length} breaks', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Break'),
                style: FilledButton.styleFrom(backgroundColor: kOrange, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: breaks.length,
              itemBuilder: (_, i) {
                final b = breaks[i];
                final isActive = b['is_active'] as bool? ?? true;
                final dow = (b['day_of_week'] as int? ?? 0).clamp(0, 6);
                final start = (b['break_start'] as String? ?? '').substring(0, 5.clamp(0, (b['break_start'] as String? ?? '').length));
                final end = (b['break_end'] as String? ?? '').substring(0, 5.clamp(0, (b['break_end'] as String? ?? '').length));
                final label = b['label'] as String? ?? '';
                final campus = b['campus'] as String? ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(_days[dow], style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                      label.isNotEmpty ? label : '$start – $end',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text('$campus · $start – $end', style: const TextStyle(fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: isActive,
                          onChanged: (v) => onToggle(b['id'] as String, isActive),
                          activeThumbColor: kOrange,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => onDelete(b['id'] as String),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Settings Tab ──────────────────────────────────────────────────────────────

class _SettingsTab extends StatelessWidget {
  final Map<String, dynamic> settings;
  final Function(String, dynamic) onChanged;
  final VoidCallback onSave;
  final VoidCallback onBroadcast;

  const _SettingsTab({
    required this.settings,
    required this.onChanged,
    required this.onSave,
    required this.onBroadcast,
  });

  @override
  Widget build(BuildContext context) {
    final commissionCtrl = TextEditingController(
        text: '${settings['commission'] ?? 0}');
    final emailCtrl = TextEditingController(
        text: settings['supportEmail'] as String? ?? '');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: 'Platform Controls',
          children: [
            _SwitchTile(
              label: 'Enable Registrations',
              subtitle: 'Allow new students to register',
              value: settings['registrationsEnabled'] as bool? ?? true,
              onChanged: (v) => onChanged('registrationsEnabled', v),
            ),
            _SwitchTile(
              label: 'Maintenance Mode',
              subtitle: 'Temporarily disable the platform',
              value: settings['maintenanceMode'] as bool? ?? false,
              onChanged: (v) => onChanged('maintenanceMode', v),
            ),
            _SwitchTile(
              label: 'Email Notifications',
              subtitle: 'Send email notifications to users',
              value: settings['emailNotifications'] as bool? ?? false,
              onChanged: (v) => onChanged('emailNotifications', v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Platform Details',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Commission (%)', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: commissionCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => onChanged('commission', num.tryParse(v) ?? 0),
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Support Email', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) => onChanged('supportEmail', v),
                    decoration: const InputDecoration(
                      hintText: 'support@campus.edu.kh',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onSave,
          style: FilledButton.styleFrom(backgroundColor: kOrange),
          child: const Text('Save Settings'),
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'Announcements',
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: OutlinedButton.icon(
                onPressed: onBroadcast,
                icon: const Icon(Icons.campaign),
                label: const Text('Broadcast to All Users'),
                style: OutlinedButton.styleFrom(foregroundColor: kOrange, side: BorderSide(color: kOrange)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
          ),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.label, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: kOrange,
      dense: true,
    );
  }
}
