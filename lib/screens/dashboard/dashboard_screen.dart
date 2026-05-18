import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app.dart';
import '../../providers/order_provider.dart';
import '../../providers/menu_provider.dart';
import '../../models/order.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const int _dailyGoal = 2000;
  static const int _avgMealKcal = 600;

  int _orderCalories(Order order, MenuProvider menu) {
    return order.items.fold<int>(0, (sum, item) {
      final found = menu.allItems.where((m) => m.id == item.menuItemId);
      final kcal = found.isEmpty ? 500 : found.first.calories;
      return sum + kcal * item.quantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final menu = context.watch<MenuProvider>();

    final now = DateTime.now();
    final todayOrders = orders.orders.where((o) {
      final d = o.createdAt.toLocal();
      return d.year == now.year &&
          d.month == now.month &&
          d.day == now.day &&
          o.status != 'cancelled';
    }).toList();

    final todayCalories =
        todayOrders.fold(0, (sum, o) => sum + _orderCalories(o, menu));
    final progress = (todayCalories / _dailyGoal).clamp(0.0, 1.0);
    final mealsCount = todayOrders.length;
    final avgPerMeal =
        mealsCount > 0 ? (todayCalories / mealsCount).round() : 0;
    final remaining = (_dailyGoal - todayCalories).clamp(0, _dailyGoal);

    return RefreshIndicator(
      color: kOrange,
      onRefresh: orders.fetchOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(children: [
            const Expanded(
              child: Text('Nutrition Dashboard',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Text(DateFormat('EEE, MMM d').format(now),
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
          const SizedBox(height: 16),

          // ── Today's calorie card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kOrange, kOrange.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Calories",
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$todayCalories',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            height: 1)),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text('/ $_dailyGoal kcal',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white30,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${(progress * 100).toStringAsFixed(0)}% of daily goal',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Three stat chips ──────────────────────────────────────────
          Row(children: [
            _StatChip(
              label: "Today's Orders",
              value: '$mealsCount',
              icon: Icons.receipt_long,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Avg / Meal',
              value: '$avgPerMeal kcal',
              icon: Icons.local_fire_department,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Goal Left',
              value: '$remaining kcal',
              icon: Icons.track_changes,
              color: kGreen,
            ),
          ]),
          const SizedBox(height: 16),

          // ── Meal comparison card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Meal Comparison',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                const Text('Your avg meal vs recommended',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 14),
                _ComparisonBar(
                  label: 'Your avg',
                  kcal: avgPerMeal,
                  maxKcal: _dailyGoal,
                  color: kOrange,
                ),
                const SizedBox(height: 8),
                _ComparisonBar(
                  label: 'Avg meal',
                  kcal: _avgMealKcal,
                  maxKcal: _dailyGoal,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Recommendation ────────────────────────────────────────────
          _RecommendationCard(
              todayCalories: todayCalories,
              avgPerMeal: avgPerMeal,
              remaining: remaining),
          const SizedBox(height: 16),

          // ── Today's orders breakdown ──────────────────────────────────
          if (todayOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('No orders today — start eating!',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else ...[
            const Text("Today's Orders",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            ...todayOrders.map((order) {
              final kcal = _orderCalories(order, menu);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.fastfood, color: kOrange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items
                              .map((i) =>
                                  '${i.quantity}× ${i.name}')
                              .join(', '),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('h:mm a').format(
                              order.createdAt.toLocal()),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(children: [
                        Icon(Icons.local_fire_department,
                            size: 14,
                            color: Colors.orange.shade400),
                        const SizedBox(width: 2),
                        Text('$kcal kcal',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      ]),
                      Text('\$${order.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ]),
              );
            }),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  final String label;
  final int kcal;
  final int maxKcal;
  final Color color;

  const _ComparisonBar({
    required this.label,
    required this.kcal,
    required this.maxKcal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = (kcal / maxKcal).clamp(0.0, 1.0);
    return Row(children: [
      SizedBox(
        width: 68,
        child: Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text('$kcal kcal',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color)),
    ]);
  }
}

class _RecommendationCard extends StatelessWidget {
  final int todayCalories;
  final int avgPerMeal;
  final int remaining;

  const _RecommendationCard({
    required this.todayCalories,
    required this.avgPerMeal,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final String message;
    final Color bg;
    final Color border;
    final IconData icon;

    if (todayCalories == 0) {
      message =
          "You haven't ordered yet today. A balanced meal is around 500–700 kcal.";
      bg = const Color(0xFFeff6ff);
      border = const Color(0xFFbfdbfe);
      icon = Icons.info_outline;
    } else if (avgPerMeal <= 400) {
      message =
          "Your meals are quite light. Consider adding a protein-rich side to stay energized.";
      bg = const Color(0xFFfefce8);
      border = const Color(0xFFfde047);
      icon = Icons.warning_amber_rounded;
    } else if (avgPerMeal <= 700) {
      message =
          "Great balance! Your meals are well within the healthy range. Keep it up!";
      bg = const Color(0xFFf0fdf4);
      border = const Color(0xFF86efac);
      icon = Icons.check_circle_outline;
    } else if (avgPerMeal <= 900) {
      message =
          "Your meals are a bit above average. Consider lighter options or smaller portions next time.";
      bg = const Color(0xFFfff7ed);
      border = const Color(0xFFfed7aa);
      icon = Icons.warning_amber_rounded;
    } else {
      message =
          "High calorie meals today. Try adding vegetables or choosing a lighter dish to balance things out.";
      bg = const Color(0xFFfef2f2);
      border = const Color(0xFFfecaca);
      icon = Icons.dangerous_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: border),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
