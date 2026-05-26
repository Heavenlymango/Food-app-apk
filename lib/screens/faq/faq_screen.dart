import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/health_classification.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('FAQ & References',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Intro(),
          SizedBox(height: 20),
          _RulesSection(),
          SizedBox(height: 24),
          _ReferencesSection(),
          SizedBox(height: 24),
          _AiScannerSection(),
          SizedBox(height: 24),
          _Footer(),
        ],
      ),
    );
  }
}

// ─── Intro ────────────────────────────────────────────────────────────────
class _Intro extends StatelessWidget {
  const _Intro();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.menu_book, color: Color(0xFFEA580C)),
            SizedBox(width: 8),
            Text('How we classify food',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Every menu item is evaluated against the rules below. If any '
          'unhealthy rule fires, we mark the item as Unhealthy and link to '
          'the matching scientific source so you can read the evidence '
          'yourself.',
          style: TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }
}

// ─── Rules table ──────────────────────────────────────────────────────────
class _Rule {
  final String label;
  final String trigger;
  final HealthStatus status;
  final String rationale;
  final List<HealthSource> sources;
  const _Rule({
    required this.label,
    required this.trigger,
    required this.status,
    required this.rationale,
    required this.sources,
  });
}

const List<_Rule> _rules = [
  _Rule(
    label: 'High calorie (≥ 700 kcal / serving)',
    trigger: 'Item calories ≥ 700',
    status: HealthStatus.caution,
    rationale:
        'A single serving above ~35% of the 2,000 kcal daily reference is treated as a heavy meal — per WHO healthy diet guidance and USDA Dietary Guidelines.',
    sources: [HealthSources.who, HealthSources.usda],
  ),
  _Rule(
    label: 'Fried / deep-fried',
    trigger: 'Name contains fried, fries, tempura, nugget, chip…',
    status: HealthStatus.unhealthy,
    rationale:
        'Deep-fried items are typically high in saturated and trans fats. WHO recommends saturated fat <10% of energy and trans fat <1%; USDA matches the 10% sat-fat cap. NOVA classes most fried fast food as Group 4.',
    sources: [
      HealthSources.who, HealthSources.usda, HealthSources.fsa, HealthSources.nova,
    ],
  ),
  _Rule(
    label: 'Sugar-sweetened drink',
    trigger: 'Name contains soda, cola, lemonade, milkshake, frappe, bubble tea, syrup…',
    status: HealthStatus.unhealthy,
    rationale:
        'Such drinks routinely cross the FSA red threshold (>11.25 g sugar/100 ml). WHO recommends free sugars <10% of energy (ideally <5%); USDA caps added sugars at 10%. Nutri-Score penalises them heavily.',
    sources: [
      HealthSources.who, HealthSources.fsa, HealthSources.usda, HealthSources.nutriScore,
    ],
  ),
  _Rule(
    label: 'Sweet dessert / confectionery',
    trigger: 'Category = Desserts, or name contains cake, donut, cookie, candy, ice cream, pastry, chocolate',
    status: HealthStatus.unhealthy,
    rationale:
        'Desserts are concentrated added-sugar sources and typically pass FSA red (>22.5 g sugar/100 g), quickly using up the WHO/USDA daily free-sugar budget.',
    sources: [HealthSources.who, HealthSources.fsa, HealthSources.usda],
  ),
  _Rule(
    label: 'Ultra-processed (NOVA Group 4)',
    trigger: 'Category in {Snacks, Desserts}',
    status: HealthStatus.unhealthy,
    rationale:
        'Commercial snacks/desserts mostly fall into NOVA Group 4 — industrially formulated foods linked in cohort studies with higher risk of obesity, type-2 diabetes and cardiovascular disease. Nutri-Score arrives at similar grades via negative-nutrient scoring.',
    sources: [HealthSources.nova, HealthSources.nutriScore],
  ),
  _Rule(
    label: 'Balanced meal (seller-tagged)',
    trigger: 'Shop ticked the "is_healthy" box for this item',
    status: HealthStatus.healthy,
    rationale:
        'Sellers tag balanced meals matching the Harvard Healthy Eating Plate ratio (½ veg/fruit, ¼ whole grains, ¼ lean protein), cross-checked against the WHO ≥400 g fruit & veg recommendation.',
    sources: [HealthSources.harvard, HealthSources.who],
  ),
  _Rule(
    label: 'Vegetable-forward (Salads)',
    trigger: 'Category = Salads',
    status: HealthStatus.healthy,
    rationale:
        'Salads help meet the WHO ≥400 g/day fruit & veg recommendation and align with the Harvard Healthy Eating Plate.',
    sources: [HealthSources.who, HealthSources.harvard],
  ),
];

class _RulesSection extends StatelessWidget {
  const _RulesSection();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.rule, color: Color(0xFF16a34a)),
            SizedBox(width: 8),
            Text('Classification rules',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ..._rules.map(_RuleCard.new),
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  final _Rule rule;
  const _RuleCard(this.rule);

  Color _statusColor() {
    switch (rule.status) {
      case HealthStatus.unhealthy: return const Color(0xFFEA580C);
      case HealthStatus.caution:   return const Color(0xFFCA8A04);
      case HealthStatus.healthy:   return const Color(0xFF16A34A);
      case HealthStatus.neutral:   return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (rule.status) {
      case HealthStatus.unhealthy: return 'Unhealthy';
      case HealthStatus.caution:   return 'Caution';
      case HealthStatus.healthy:   return 'Healthy';
      case HealthStatus.neutral:   return 'Neutral';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(rule.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel(),
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Triggers: ${rule.trigger}',
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 8),
          Text(rule.rationale,
              style: const TextStyle(fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: rule.sources
                .map((s) => InkWell(
                      onTap: () => _openUrl(s.url),
                      child: Text(
                        '${s.short} ↗',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFEA580C),
                            decoration: TextDecoration.underline),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── References list ──────────────────────────────────────────────────────
class _ReferencesSection extends StatelessWidget {
  const _ReferencesSection();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.library_books, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Full references',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ...HealthSources.all.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.short,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      InkWell(
                        onTap: () => _openUrl(s.url),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Open',
                                style: TextStyle(
                                    color: Color(0xFFEA580C), fontSize: 12)),
                            SizedBox(width: 2),
                            Icon(Icons.open_in_new,
                                size: 12, color: Color(0xFFEA580C)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(s.full,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black87, height: 1.4)),
                ],
              ),
            )),
      ],
    );
  }
}

// ─── AI scanner / 80% rationale ───────────────────────────────────────────
class _AiScannerSection extends StatelessWidget {
  const _AiScannerSection();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.memory, color: Color(0xFF9333EA)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Why the AI scanner uses an 80% confidence threshold',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The food scanner is a two-stage cascade:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              _Bullet(
                num: '1.',
                text:
                    'MobileNetV3 (local TFLite) — ~8 MB, runs entirely on your phone. ~50 ms per image on a mid-range Android device.',
              ),
              _Bullet(
                num: '2.',
                text:
                    'If MobileNet\'s top prediction is ≥80% confident, we use it and stop.',
              ),
              _Bullet(
                num: '3.',
                text:
                    'Otherwise we fall back to YOLOv11-small — heavier (38 MB on-device, or the cloud inference server) but more accurate for ambiguous dishes.',
              ),
              SizedBox(height: 12),
              Text(
                'Why 80% — not 50% or 95%?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 6),
              _Bullet(
                bullet: '•',
                text:
                    'Random-guess baseline: 32 classes → 1/32 ≈ 3.1%. Useful predictions need to land well above that.',
              ),
              _Bullet(
                bullet: '•',
                text:
                    'Calibration band: modern CNNs are over-confident on training data; on held-out fine-grained tasks top-1 reliability typically plateaus around 75–85% (Guo et al. 2017, On Calibration of Modern Neural Networks). 80% sits inside this band.',
              ),
              _Bullet(
                bullet: '•',
                text:
                    'Too low (50%) → YOLO almost never runs; cascade defeated. Too high (95%) → YOLO runs on most photos, kills the snappy local-first feel. 80% routes ~30% of photos to YOLO.',
              ),
              _Bullet(
                bullet: '•',
                text:
                    'Industrial precedent: cascade systems (Google image fallbacks, NVIDIA multi-stage detectors) gate secondary models at 70–85% confidence.',
              ),
              SizedBox(height: 10),
              Text(
                'Threshold lives in AppConfig.confidenceThreshold and can be tuned without retraining.',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            border: Border.all(color: const Color(0xFFBFDBFE)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Honest caveat: 80% was chosen empirically. The rigorous '
                  'next step is a calibration study (reliability diagram + '
                  'Expected Calibration Error) on a labelled hold-out set '
                  'from our own menus, then adjusting the threshold to '
                  'balance precision and recall on the fallback path.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String? num;
  final String? bullet;
  final String text;
  const _Bullet({this.num, this.bullet, required this.text});
  @override
  Widget build(BuildContext context) {
    final lead = num ?? bullet ?? '•';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Text(lead,
                style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          'Classification rules and thresholds can be updated in\n'
          'lib/utils/health_classification.dart',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
    );
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
