import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

void showCaloriePreview(BuildContext context, CartProvider cart) {
  const int avgMeal = 600;
  const int dailyGoal = 2000;
  final int total = cart.totalCalories;
  final double ratio = total / avgMeal;

  final String message;
  final Color color;
  if (total == 0) {
    message = 'Add items to see calorie info.';
    color = Colors.grey;
  } else if (total < 400) {
    message = 'Light meal — consider adding a protein-rich side to stay energized.';
    color = Colors.blue;
  } else if (total <= 700) {
    message = 'Great portion! This fits well within a healthy meal range.';
    color = kGreen;
  } else if (total <= 900) {
    message = 'Slightly above average — consider skipping a snack later.';
    color = Colors.orange;
  } else {
    message = 'Heavy meal. Try to eat lighter at your next meal to balance out.';
    color = Colors.red;
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Calorie Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('How does your order compare?',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          _PreviewBar(label: 'Your order', kcal: total, maxKcal: dailyGoal, color: kOrange),
          const SizedBox(height: 10),
          _PreviewBar(label: 'Avg meal', kcal: avgMeal, maxKcal: dailyGoal, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          _PreviewBar(label: 'Daily goal', kcal: dailyGoal, maxKcal: dailyGoal, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(message,
                  style: TextStyle(fontSize: 13, color: color))),
            ]),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Your order is ${ratio.toStringAsFixed(1)}× the average meal',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PreviewBar extends StatelessWidget {
  final String label;
  final int kcal;
  final int maxKcal;
  final Color color;
  const _PreviewBar({required this.label, required this.kcal, required this.maxKcal, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 12))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (kcal / maxKcal).clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text('$kcal kcal',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]);
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _reserveMode = false;
  String _serviceType = 'pickup';
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
                        errorBuilder: (_, _, _) => Container(
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
                            Row(children: [
                              Text(item.menuItem.shop,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              const SizedBox(width: 8),
                              Icon(Icons.local_fire_department,
                                  size: 12,
                                  color: Colors.orange.shade400),
                              Text(
                                ' ${item.menuItem.calories * item.quantity} kcal',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ]),
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
                else
                  SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _upcomingBreaks.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      // Custom time chip (always last)
                      if (i == _upcomingBreaks.length) {
                        final isCustomSelected = cart.scheduledFor != null &&
                            !_upcomingBreaks.any((b) {
                              final s = _parseBreakTime(
                                  b['break_start'] as String);
                              return s != null &&
                                  cart.scheduledFor!.hour == s.hour &&
                                  cart.scheduledFor!.minute == s.minute;
                            });
                        return GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: cart.scheduledFor != null
                                  ? TimeOfDay.fromDateTime(
                                      cart.scheduledFor!)
                                  : TimeOfDay.now(),
                            );
                            if (picked != null) {
                              final now = DateTime.now();
                              cart.setScheduledFor(DateTime(
                                now.year,
                                now.month,
                                now.day,
                                picked.hour,
                                picked.minute,
                              ));
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isCustomSelected
                                  ? Colors.purple
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCustomSelected
                                    ? Colors.purple
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Custom',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isCustomSelected
                                            ? Colors.white
                                            : Colors.black87)),
                                const SizedBox(height: 2),
                                Text(
                                  isCustomSelected
                                      ? DateFormat('h:mm a')
                                          .format(cart.scheduledFor!)
                                      : 'Pick a time',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: isCustomSelected
                                          ? Colors.white70
                                          : Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
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
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.local_fire_department,
                        size: 14, color: Colors.orange.shade400),
                    Text(
                      ' ${cart.totalCalories} kcal total',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ]),
                  TextButton.icon(
                    onPressed: () => showCaloriePreview(context, cart),
                    icon: const Icon(Icons.bar_chart, size: 14),
                    label: const Text('Preview', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: kGreen,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Service type selector (always shown) ───────────────────
              Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _ServiceTypeBtn(
                        label: 'Pickup',
                        icon: Icons.shopping_bag_outlined,
                        selected: _serviceType == 'pickup',
                        onTap: () => setState(() => _serviceType = 'pickup'),
                      ),
                      _ServiceTypeBtn(
                        label: 'Dine-In',
                        icon: Icons.restaurant_outlined,
                        selected: _serviceType == 'dine-in',
                        onTap: () => setState(() => _serviceType = 'dine-in'),
                      ),
                    ],
                  ),
                ),
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
                          _buildOrderButtonLabel(cart),
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

  String _buildOrderButtonLabel(CartProvider cart) {
    final typeLabel = _serviceType == 'dine-in' ? 'Dine-In' : 'Pickup';
    if (_reserveMode && cart.scheduledFor != null) {
      final t = cart.scheduledFor!;
      final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
      final m = t.minute.toString().padLeft(2, '0');
      final suffix = t.hour >= 12 ? 'PM' : 'AM';
      return 'Reserve $typeLabel at $h:$m $suffix';
    }
    return _serviceType == 'dine-in' ? 'Place Dine-In Order' : 'Place Pickup Order';
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
      serviceType: _serviceType,
    );
    if (success && context.mounted) {
      cart.clear();
      setState(() {
        _reserveMode = false;
        _serviceType = 'pickup';
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

class _ServiceTypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceTypeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? kOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
