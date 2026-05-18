import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../menu/menu_screen.dart';
import '../cart/cart_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../tips/tips_screen.dart';
import '../scan/food_scan_screen.dart';
import '../dashboard/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0=Menu, 1=Cart, 2=Orders, 3=Dashboard  (Scan is a modal push, not a tab)
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    MenuScreen(),
    CartScreen(),
    OrdersScreen(),
    DashboardScreen(),
  ];

  // Nav bar has 5 items: Menu(0), Cart(1), Scan(2), Orders(3), Dashboard(4)
  // Scan pushes a modal; the other 4 map to _screens indices 0-3.
  int get _navBarIndex => _selectedIndex < 2 ? _selectedIndex : _selectedIndex + 1;

  void _handleNavTap(int navIndex) {
    if (navIndex == 2) {
      Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const FoodScanScreen(),
      ));
      return;
    }
    final screenIndex = navIndex < 2 ? navIndex : navIndex - 1;
    setState(() => _selectedIndex = screenIndex);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final notifs = context.watch<NotificationProvider>();
    final name = auth.user?.name ?? '';

    return Scaffold(
      backgroundColor: kBeige,
      drawer: _buildDrawer(context, auth),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kBeige,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.restaurant_menu, size: 18, color: kOrange),
            ),
            const SizedBox(width: 8),
            Text(
              'Student: $name',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.black87),
                onPressed: () => _showNotifications(context, notifs),
              ),
              if (notifs.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${notifs.unreadCount}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
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
              if (confirm == true && context.mounted) {
                context.read<AuthProvider>().logout();
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: BottomNavigationBar(
          currentIndex: _navBarIndex,
          onTap: _handleNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: kOrange,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_cart),
              ),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kOrange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kOrange.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 22),
              ),
              label: 'Scan',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Dashboard',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              color: kOrange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 34, color: kOrange),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Student',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user?.studentId != null)
                    Text(
                      'ID: ${user!.studentId}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerItem(Icons.restaurant_menu, 'Menu', 0),
            _drawerItem(Icons.shopping_cart_outlined, 'Cart', 1),
            _drawerItem(Icons.receipt_long_outlined, 'My Orders', 2),
            _drawerItem(Icons.bar_chart_outlined, 'Dashboard', 3),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline, color: Colors.black54),
              title: const Text('Tips & Advice'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const TipsScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.black54),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ));
              },
            ),
            const Divider(height: 8),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content:
                        const Text('Are you sure you want to logout?'),
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
                if (confirm == true && context.mounted) {
                  context.read<AuthProvider>().logout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, int screenIndex) {
    final selected = _selectedIndex == screenIndex;
    return ListTile(
      leading: Icon(icon, color: selected ? kOrange : Colors.black54),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? kOrange : Colors.black87,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: selected ? kOrange.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        setState(() => _selectedIndex = screenIndex);
        Navigator.pop(context);
      },
    );
  }

  void _showNotifications(
      BuildContext context, NotificationProvider notifs) {
    notifs.markAllRead();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (notifs.notifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No notifications',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...notifs.notifications.take(10).map(
                    (n) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.notifications_outlined,
                          color: kOrange),
                      title: Text(n.message,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        '${n.createdAt.hour}:${n.createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
