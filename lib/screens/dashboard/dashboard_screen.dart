import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app.dart';
import '../../providers/order_provider.dart';
import '../../providers/menu_provider.dart';
import '../../models/order.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const int _dailyGoal = 2000;

  // ── Calorie + healthy helpers ────────────────────────────────────────────
  int _orderCalories(Order order, MenuProvider menu) {
    return order.items.fold<int>(0, (sum, item) {
      final found = menu.allItems.where((m) => m.id == item.menuItemId);
      final kcal = found.isEmpty ? 500 : found.first.calories;
      return sum + kcal * item.quantity;
    });
  }

  int _orderHealthyCalories(Order order, MenuProvider menu) {
    return order.items.fold<int>(0, (sum, item) {
      final found = menu.allItems.where((m) => m.id == item.menuItemId);
      if (found.isEmpty || !found.first.isHealthy) return sum;
      return sum + found.first.calories * item.quantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final menu = context.watch<MenuProvider>();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 6));

    final active = orders.orders.where((o) => o.status != 'cancelled').toList();

    // Today
    final todayOrders = active.where((o) {
      final d = o.createdAt.toLocal();
      return DateTime(d.year, d.month, d.day) == todayStart;
    }).toList();
    final todayCalories =
        todayOrders.fold(0, (sum, o) => sum + _orderCalories(o, menu));
    final todaySpend =
        todayOrders.fold<double>(0, (sum, o) => sum + o.total);
    final mealsToday = todayOrders.length;
    final avgPerMeal =
        mealsToday > 0 ? (todayCalories / mealsToday).round() : 0;
    final progress = (todayCalories / _dailyGoal).clamp(0.0, 1.0);

    // 7-day buckets
    final days = List<_DayBucket>.generate(7, (i) {
      final d = todayStart.subtract(Duration(days: 6 - i));
      return _DayBucket(
        date: d,
        label: DateFormat('EEE').format(d),
      );
    });
    for (final o in active) {
      final d = o.createdAt.toLocal();
      final key = DateTime(d.year, d.month, d.day);
      for (final b in days) {
        if (b.date == key) {
          b.kcal += _orderCalories(o, menu);
          b.spend += o.total;
        }
      }
    }
    final weekKcal = days.fold<int>(0, (s, b) => s + b.kcal);
    final weekSpend = days.fold<double>(0, (s, b) => s + b.spend);
    final avgDailyKcal = (weekKcal / 7).round();

    // Healthy vs Indulgent (last 7 days)
    int healthyKcal = 0, otherKcal = 0;
    for (final o in active) {
      final d = o.createdAt.toLocal();
      if (d.isBefore(weekStart)) continue;
      final h = _orderHealthyCalories(o, menu);
      final total = _orderCalories(o, menu);
      healthyKcal += h;
      otherKcal += (total - h);
    }
    final totalSplit = healthyKcal + otherKcal;
    final healthyPct =
        totalSplit > 0 ? ((healthyKcal / totalSplit) * 100).round() : 0;

    // Top items (lifetime)
    final itemQty = <String, int>{};
    final itemKcal = <String, int>{};
    for (final o in active) {
      for (final it in o.items) {
        itemQty[it.name] = (itemQty[it.name] ?? 0) + it.quantity;
        final m = menu.allItems.where((x) => x.id == it.menuItemId);
        final kcal = m.isEmpty ? 0 : m.first.calories;
        itemKcal[it.name] = (itemKcal[it.name] ?? 0) + kcal * it.quantity;
      }
    }
    final topItems = itemQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topItemList = topItems.take(5).toList();

    return RefreshIndicator(
      color: kOrange,
      onRefresh: orders.fetchOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(children: [
            const Expanded(
              child: Text('Nutrition Dashboard',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Text(DateFormat('EEE, MMM d').format(now),
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
          const SizedBox(height: 16),

          // ── Today's calorie hero card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kOrange, const Color(0xFFF97316)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
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
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            height: 1)),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text('/ 2000 kcal',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(progress * 100).round()}% of daily goal',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    Text(
                      '${(_dailyGoal - todayCalories).clamp(0, _dailyGoal)} kcal left',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Quick stat chips ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                  child: _StatChip(
                      label: 'Meals today',
                      value: '$mealsToday',
                      icon: Icons.restaurant,
                      color: Colors.blue.shade600)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatChip(
                      label: 'Avg / meal',
                      value: '$avgPerMeal kcal',
                      icon: Icons.local_fire_department,
                      color: Colors.orange.shade700)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _StatChip(
                      label: 'Spent today',
                      value: '\$${todaySpend.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                      color: kGreen)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatChip(
                      label: 'Healthy %',
                      value: '$healthyPct%',
                      icon: Icons.eco,
                      color: const Color(0xFF059669))),
            ],
          ),

          const SizedBox(height: 20),

          // ── 7-day calorie bar chart ──────────────────────────────────
          _SectionTitle(
            icon: Icons.trending_up,
            iconColor: kOrange,
            title: 'Last 7 Days',
            subtitle:
                'Avg $avgDailyKcal kcal/day · \$${weekSpend.toStringAsFixed(2)} this week',
          ),
          _ChartCard(
            child: SizedBox(
              height: 180,
              child: BarChart(_buildKcalChart(days)),
            ),
          ),

          const SizedBox(height: 20),

          // ── Healthy vs Indulgent donut ───────────────────────────────
          _SectionTitle(
            icon: Icons.eco,
            iconColor: kGreen,
            title: 'Healthy vs Indulgent',
            subtitle: 'By calories · last 7 days',
          ),
          _ChartCard(
            child: totalSplit == 0
                ? const SizedBox(
                    height: 180,
                    child: Center(
                      child: Text('No orders yet this week.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  value: healthyKcal.toDouble(),
                                  color: kGreen,
                                  title: '$healthyKcal',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                                PieChartSectionData(
                                  value: otherKcal.toDouble(),
                                  color: kOrange,
                                  title: '$otherKcal',
                                  radius: 50,
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
                            _LegendRow(color: kGreen, label: 'Healthy', value: '$healthyKcal kcal'),
                            const SizedBox(height: 8),
                            _LegendRow(color: kOrange, label: 'Indulgent', value: '$otherKcal kcal'),
                          ],
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
          ),

          const SizedBox(height: 20),

          // ── Top items ────────────────────────────────────────────────
          _SectionTitle(
            icon: Icons.emoji_events,
            iconColor: kOrange,
            title: 'Your Top Items',
            subtitle: 'Most ordered (all-time)',
          ),
          _ChartCard(
            child: topItemList.isEmpty
                ? const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text('No orders yet.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : Column(
                    children: topItemList.map((e) {
                      final qty = e.value;
                      final kcal = itemKcal[e.key] ?? 0;
                      final maxQty = topItemList.first.value;
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
                                Text('$qty× · $kcal kcal',
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

          // ── Today's orders ────────────────────────────────────────────
          const Text('Today\'s Orders',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          if (todayOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.restaurant_outlined,
                      size: 36, color: Colors.grey.shade300),
                  const SizedBox(height: 6),
                  const Text('No orders today — go grab something!',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            )
          else
            ...todayOrders.map((o) {
              final kcal = _orderCalories(o, menu);
              final time = DateFormat('h:mm a').format(o.createdAt.toLocal());
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: kOrange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.restaurant, color: kOrange, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.items.map((i) => '${i.quantity}× ${i.name}').join(', '),
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(time,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(children: [
                          Icon(Icons.local_fire_department,
                              size: 12, color: Colors.orange.shade400),
                          Text(' $kcal kcal',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ]),
                        Text('\$${o.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Calorie estimates are based on standard serving sizes. '
                'Goal of 2000 kcal is a general adult reference.',
                style: TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chart builders ─────────────────────────────────────────────────────
  BarChartData _buildKcalChart(List<_DayBucket> days) {
    final maxKcal = days.fold<int>(0, (m, b) => b.kcal > m ? b.kcal : m);
    final upper = (maxKcal == 0 ? 100 : (maxKcal * 1.2)).ceilToDouble();
    return BarChartData(
      maxY: upper,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, _) => Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
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
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: days[i].kcal.toDouble(),
              color: kOrange,
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        );
      }),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────
class _DayBucket {
  final DateTime date;
  final String label;
  int kcal = 0;
  double spend = 0;
  _DayBucket({required this.date, required this.label});
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _SectionTitle({
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

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
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
