import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../utils/health_classification.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const MenuItemCard({super.key, required this.item});

  ClassificationResult get _classification => classifyItem(ClassifiableItem(
        name: item.name,
        category: item.category,
        calories: item.calories,
        isHealthy: item.isHealthy,
      ));

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.contains(item.id);
    final classification = _classification;
    final badge = badgeFor(classification.status);
    final isWarning = classification.status == HealthStatus.unhealthy ||
        classification.status == HealthStatus.caution;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context),
        child: Row(
          children: [
            // Image + discount badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14)),
                  child: Image.network(
                    item.image,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, st) => Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.fastfood,
                          color: Colors.grey, size: 36),
                    ),
                  ),
                ),
                if (item.hasDiscount)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(
                        color: kOrange,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                          '-${item.discountPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + healthy badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isHealthy && !item.hideHealthyBadge)
                          Icon(Icons.eco, size: 16, color: kGreen),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(item.description,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),

                    // Shop + calories + time + health badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.shop,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black87)),
                        ),
                        // Chip is hidden when (a) seller explicitly hides it,
                        // or (b) a green leaf is currently visible (no double-
                        // badging). "Visible leaf" = isHealthy AND not suppressed.
                        if (badge != null &&
                            isWarning &&
                            !item.hideUnhealthyBadge &&
                            !(item.isHealthy && !item.hideHealthyBadge)) ...[
                          const SizedBox(width: 4),
                          _HealthBadgeChip(
                            badge: badge,
                            onTap: () => _showHealthReasons(context, classification),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Icon(Icons.local_fire_department,
                            size: 12, color: Colors.orange.shade400),
                        Text(' ${item.calories}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 6),
                        const Icon(Icons.access_time,
                            size: 12, color: Colors.grey),
                        Text(' ${item.preparationTime}m',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Price + add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (item.hasDiscount) ...[
                              Text(
                                '\$${item.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 11),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              '\$${item.discountedPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: kOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => cart.addItem(item),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: inCart ? kOrange : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kOrange),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  inCart ? Icons.check : Icons.add,
                                  size: 14,
                                  color: inCart ? Colors.white : kOrange,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  inCart ? 'Added' : 'Add',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        inCart ? Colors.white : kOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final cart = context.read<CartProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.image,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, e, st) => Container(
                  height: 180,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.fastfood,
                      size: 64, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(item.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                if (item.isHealthy && !item.hideHealthyBadge)
                  Icon(Icons.eco, color: kGreen, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.shop,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(item.description,
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (item.isHealthy && !item.hideHealthyBadge) _Badge(label: 'Healthy', color: kGreen),
                if (item.hasDiscount) ...[
                  const SizedBox(width: 8),
                  _Badge(
                      label:
                          '${item.discountPercent.toStringAsFixed(0)}% off now',
                      color: kOrange),
                ],
                const Spacer(),
                Icon(Icons.local_fire_department,
                    size: 14, color: Colors.orange.shade400),
                Text(' ${item.calories} cal',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                const Icon(Icons.access_time,
                    size: 14, color: Colors.grey),
                Text(' ${item.preparationTime} min',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (item.hasDiscount) ...[
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '\$${item.discountedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: kOrange,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    cart.addItem(item);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} added to cart'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: kOrange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class _HealthBadgeChip extends StatelessWidget {
  final HealthBadge badge;
  final VoidCallback onTap;
  const _HealthBadgeChip({required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDD5),
          border: Border.all(color: const Color(0xFFFB923C)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 10, color: Color(0xFFC2410C)),
            const SizedBox(width: 2),
            Text(badge.label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFC2410C),
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 2),
            const Icon(Icons.info_outline,
                size: 10, color: Color(0xFFC2410C)),
          ],
        ),
      ),
    );
  }
}

void _showHealthReasons(BuildContext context, ClassificationResult c) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFC2410C), size: 22),
              SizedBox(width: 8),
              Text('Why this is flagged',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...c.reasons.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0xFFFB923C), width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(r.reason,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: r.sources
                          .map((s) => Text(s.short,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFEA580C),
                                  decoration: TextDecoration.underline)))
                          .toList(),
                    ),
                  ],
                ),
              )),
          const Divider(height: 16),
          const Text(
            'Open the FAQ from the home screen for the full rule set, '
            'links to each paper, and the rationale behind the AI scanner '
            'threshold.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}
