import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _reserveMode = false;
  List<Map<String, dynamic>> _breaks = [];
  bool _loadingBreaks = false;

  // Format "08:30:00" → DateTime today at that time
  DateTime? _parseBreakTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }

  // Only show breaks that haven't ended yet
  List<Map<String, dynamic>> get _upcomingBreaks {
    final now = DateTime.now();
    return _breaks.where((b) {
      final end = _parseBreakTime(b['break_end'] as String);
      return end != null && end.isAfter(now);
    }).toList();
  }

  Future<void> _loadBreaks(String campus) async {
    setState(() => _loadingBreaks = true);
    try {
      final list = await ApiService.getClassBreaks(campus);
      setState(() => _breaks = list);
    } finally {
      if (mounted) setState(() => _loadingBreaks = false);
    }
  }

  void _toggleReserve(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    if (!_reserveMode) {
      // Switching on
      final campus = auth.user?.campus ?? 'RUPP';
      _loadBreaks(campus);
    } else {
      // Switching off — clear the scheduled time
      cart.setScheduledFor(null);
    }
    setState(() => _reserveMode = !_reserveMode);
  }

  void _selectBreak(
      Map<String, dynamic> breakEntry, CartProvider cart) {
    final dt = _parseBreakTime(breakEntry['break_start'] as String);
    if (dt == null) return;
    cart.setScheduledFor(dt);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orders = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();

    if (cart.items.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_bag_outlined,
                  size: 72, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('Your cart is empty',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Add items from the menu!',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cart.items.length,
            itemBuilder: (ctx, i) {
              final item = cart.items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(14)),
                      child: Image.network(
                        item.menuItem.image,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, st) => Container(
                          width: 76,
                          height: 76,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.fastfood,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.menuItem.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text(item.menuItem.shop,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (item.menuItem.hasDiscount)
                                      Text(
                                        '\$${item.menuItem.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Colors.grey,
                                            fontSize: 11),
                                      ),
                                    Text(
                                      '\$${(item.menuItem.discountedPrice * item.quantity).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: kOrange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    _QtyButton(
                                      icon: Icons.remove,
                                      onTap: () => cart
                                          .removeItem(item.menuItem.id),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Text('${item.quantity}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                    ),
                                    _QtyButton(
                                      icon: Icons.add,
                                      onTap: () =>
                                          cart.addItem(item.menuItem),
                                      filled: true,
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => cart
                                          .deleteItem(item.menuItem.id),
                                      child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // ── Reservation picker ───────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: Colors.purple),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Reserve for class break',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  Switch(
                    value: _reserveMode,
                    activeThumbColor: Colors.purple,
                    activeTrackColor: Colors.purple.shade100,
                    onChanged: (_) => _toggleReserve(context),
                  ),
                ],
              ),
              if (_reserveMode) ...[
                const SizedBox(height: 4),
                const Text(
                  'Your order will be ready when your break starts — no rush-hour queue.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                if (_loadingBreaks)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (_upcomingBreaks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No upcoming breaks today. Check back later or order now.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                else
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _upcomingBreaks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final b = _upcomingBreaks[i];
                        final start = _parseBreakTime(
                            b['break_start'] as String);
                        final end = _parseBreakTime(
                            b['break_end'] as String);
                        final isSelected = cart.scheduledFor != null &&
                            start != null &&
                            cart.scheduledFor!.hour == start.hour &&
                            cart.scheduledFor!.minute == start.minute;
                        final label = b['break_label'] as String? ?? 'Break';
                        final className =
                            b['class_name'] as String? ?? '';
                        final timeStr = start != null && end != null
                            ? '${DateFormat('h:mm a').format(start)} – ${DateFormat('h:mm a').format(end)}'
                            : '';
                        return GestureDetector(
                          onTap: () => _selectBreak(b, cart),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.purple
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? Colors.purple
                                      : Colors.grey.shade300),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(label,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87)),
                                Text(className,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected
                                            ? Colors.white70
                                            : Colors.grey)),
                                Text(timeStr,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected
                                            ? Colors.white70
                                            : Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (cart.scheduledFor != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 14, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text(
                        'Pickup at ${DateFormat('h:mm a').format(cart.scheduledFor!)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.purple,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),

        // ── Checkout bar ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${cart.itemCount} item(s)',
                      style: const TextStyle(color: Colors.grey)),
                  Text(
                    'Total: \$${cart.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kOrange),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: orders.isLoading
                      ? null
                      : () => _placeOrder(context, cart, orders, auth),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _reserveMode && cart.scheduledFor != null
                        ? Colors.purple
                        : kOrange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: orders.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _reserveMode && cart.scheduledFor != null
                              ? 'Reserve Order'
                              : 'Place Order',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _placeOrder(
    BuildContext context,
    CartProvider cart,
    OrderProvider orders,
    AuthProvider auth,
  ) async {
    if (auth.user == null) return;
    // Enforce: if reserve mode is on but no time selected, prompt
    if (_reserveMode && cart.scheduledFor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a break time for your reservation.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final success = await orders.placeOrder(
      cartItems: cart.items.toList(),
      student: auth.user!,
      scheduledFor: cart.scheduledFor,
    );
    if (success && context.mounted) {
      cart.clear();
      setState(() {
        _reserveMode = false;
        _breaks = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cart.scheduledFor != null
              ? 'Order reserved! Your food will be ready at pickup time.'
              : 'Order placed successfully!'),
          backgroundColor: kOrange,
        ),
      );
    } else if (context.mounted && orders.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(orders.error!), backgroundColor: Colors.red),
      );
    }
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _QtyButton(
      {required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled ? kOrange : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kOrange),
        ),
        child: Icon(icon,
            size: 16, color: filled ? Colors.white : kOrange),
      ),
    );
  }
}
