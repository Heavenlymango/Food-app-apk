// Health classification for menu items.
//
// Mirror of food_app/src/utils/healthClassification.ts so the mobile app
// makes the same calls and cites the same papers. Keep the two files in
// sync when adding rules.
//
// Frameworks each contribute one signal:
//   - WHO Healthy Diet (energy + sugar + fat ceilings)
//   - UK FSA Traffic Light (per-100g thresholds → category proxy)
//   - Nutri-Score 2024 (combined nutrient profile)
//   - NOVA classification (ultra-processed foods)
//   - USDA Dietary Guidelines for Americans 2020–2025
//   - Harvard Healthy Eating Plate (food-group balance)

enum HealthStatus { unhealthy, caution, healthy, neutral }

class HealthSource {
  final String short;
  final String full;
  final String url;
  const HealthSource({required this.short, required this.full, required this.url});
}

class HealthRule {
  final String id;
  final String label;
  final String reason;
  final HealthStatus status;
  final List<HealthSource> sources;
  const HealthRule({
    required this.id,
    required this.label,
    required this.reason,
    required this.status,
    required this.sources,
  });
}

class ClassifiableItem {
  final String name;
  final String? category;
  final int? calories;
  final bool isHealthy;
  const ClassifiableItem({
    required this.name,
    this.category,
    this.calories,
    this.isHealthy = false,
  });
}

class ClassificationResult {
  final HealthStatus status;
  final List<HealthRule> reasons;
  const ClassificationResult({required this.status, required this.reasons});
}

// ─── Source catalogue ──────────────────────────────────────────────────────
class HealthSources {
  static const who = HealthSource(
    short: 'WHO Healthy Diet (2020)',
    full: 'World Health Organization — Healthy diet fact sheet. Limits: free sugars <10% of energy, saturated fat <10%, sodium <2 g/day, total fat <30%.',
    url: 'https://www.who.int/news-room/fact-sheets/detail/healthy-diet',
  );
  static const fsa = HealthSource(
    short: 'UK FSA Traffic Light Labelling',
    full: 'UK Food Standards Agency front-of-pack thresholds (per 100 g of food): fat >17.5 g, sat fat >5 g, sugar >22.5 g, or salt >1.5 g triggers a red label. Drinks: thresholds roughly halved.',
    url: 'https://nutrasafe.co.uk/uk-food-label-traffic-light-system-explained',
  );
  static const nutriScore = HealthSource(
    short: 'Nutri-Score (EU, 2024 update)',
    full: 'European front-of-pack five-grade label (A–E) combining negative nutrients (energy, sat fat, sugars, salt) against positive ones (fibre, protein, fruit/veg/legumes). Algorithm updated January 2024 with stricter sugar and salt thresholds.',
    url: 'https://en.wikipedia.org/wiki/Nutri-Score',
  );
  static const nova = HealthSource(
    short: 'NOVA Classification (Monteiro et al., 2016)',
    full: 'Classifies foods by extent and purpose of processing into 4 groups; Group 4 (ultra-processed: sodas, packaged snacks, deep-fried fast food, sweets) is consistently linked with increased risk of obesity, type-2 diabetes, and cardiovascular disease.',
    url: 'https://archive.wphna.org/wp-content/uploads/2016/01/WN-2016-7-1-3-28-38-Monteiro-Cannon-Levy-et-al-NOVA.pdf',
  );
  static const usda = HealthSource(
    short: 'USDA Dietary Guidelines for Americans 2020–2025',
    full: 'US federal guidelines: <10% calories from added sugars, <10% from saturated fat, <2,300 mg sodium/day. Limit foods high in added fats, sugars, and sodium (e.g. fried items, sugar-sweetened drinks).',
    url: 'https://www.dietaryguidelines.gov/sites/default/files/2020-12/Dietary_Guidelines_for_Americans_2020-2025.pdf',
  );
  static const harvard = HealthSource(
    short: 'Harvard Healthy Eating Plate',
    full: 'Recommends a plate roughly half fruits & vegetables, a quarter whole grains, a quarter healthy protein, with healthy plant oils and water — operationalises the "balanced meal" concept.',
    url: 'https://www.hsph.harvard.edu/nutritionsource/healthy-eating-plate/',
  );

  static const all = [who, fsa, nutriScore, nova, usda, harvard];
}

// ─── Helpers ───────────────────────────────────────────────────────────────
const _friedKeywords = ['fried', 'fries', 'deep-fry', 'deep fry', 'tempura', 'nugget', 'chip'];
const _sugaryDrinkKeywords = ['soda', 'cola', 'pepsi', 'coke', 'sprite', 'fanta', 'lemonade', 'milkshake', 'frappe', 'bubble tea', 'boba', 'syrup'];
const _sweetKeywords = ['cake', 'donut', 'doughnut', 'cookie', 'candy', 'ice cream', 'icecream', 'pastry', 'chocolate'];
const _ultraProcessedCategories = ['Snacks', 'Desserts'];

bool _nameContains(String name, List<String> keywords) {
  final lower = name.toLowerCase();
  return keywords.any(lower.contains);
}

// ─── Rules ─────────────────────────────────────────────────────────────────
typedef _RuleFn = HealthRule? Function(ClassifiableItem);

HealthRule? _ruleHighCalorie(ClassifiableItem item) {
  final kcal = item.calories ?? 0;
  if (kcal < 700) return null;
  return HealthRule(
    id: 'high-calorie',
    label: 'High calorie',
    reason: 'This meal has $kcal kcal — more than 35% of a 2,000 kcal daily reference for a single serving.',
    status: HealthStatus.caution,
    sources: const [HealthSources.who, HealthSources.usda],
  );
}

HealthRule? _ruleFried(ClassifiableItem item) {
  if (!_nameContains(item.name, _friedKeywords)) return null;
  return const HealthRule(
    id: 'fried',
    label: 'Fried / deep-fried',
    reason: 'Deep-fried items are typically high in saturated fat and trans fats, which WHO and USDA both recommend keeping below 10% and 1% of daily energy intake respectively.',
    status: HealthStatus.unhealthy,
    sources: [HealthSources.who, HealthSources.usda, HealthSources.fsa],
  );
}

HealthRule? _ruleSugaryDrink(ClassifiableItem item) {
  final sugaryName = _nameContains(item.name, _sugaryDrinkKeywords);
  if (!sugaryName) return null;
  return const HealthRule(
    id: 'sugary-drink',
    label: 'Sugar-sweetened drink',
    reason: 'Sugar-sweetened beverages typically exceed the FSA red threshold for drinks (>11.25 g sugar / 100 ml) and contribute to free-sugar intake which WHO recommends keeping below 10% of total energy (ideally below 5%).',
    status: HealthStatus.unhealthy,
    sources: [HealthSources.who, HealthSources.fsa, HealthSources.usda],
  );
}

HealthRule? _ruleSweetDessert(ClassifiableItem item) {
  final isDessert = (item.category ?? '').toLowerCase() == 'desserts';
  final sweetName = _nameContains(item.name, _sweetKeywords);
  if (!isDessert && !sweetName) return null;
  return const HealthRule(
    id: 'sweet-dessert',
    label: 'High in added sugar',
    reason: 'Desserts and confectionery are concentrated sources of added sugar — typically far above the FSA red threshold (>22.5 g sugar / 100 g) and quickly use up the WHO free-sugar allowance.',
    status: HealthStatus.unhealthy,
    sources: [HealthSources.who, HealthSources.fsa, HealthSources.usda],
  );
}

HealthRule? _ruleUltraProcessedCategory(ClassifiableItem item) {
  final cat = item.category ?? '';
  if (!_ultraProcessedCategories.contains(cat)) return null;
  return const HealthRule(
    id: 'ultra-processed',
    label: 'Ultra-processed (NOVA Group 4)',
    reason: 'Snacks and desserts in their commercial form usually fall into NOVA Group 4 — industrially formulated foods linked in cohort studies with increased risk of obesity, type-2 diabetes and cardiovascular disease.',
    status: HealthStatus.unhealthy,
    sources: [HealthSources.nova, HealthSources.nutriScore],
  );
}

HealthRule? _ruleSellerHealthy(ClassifiableItem item) {
  if (!item.isHealthy) return null;
  return const HealthRule(
    id: 'seller-healthy',
    label: 'Balanced meal',
    reason: 'Marked as a balanced meal by the shop: rich in vegetables, whole grains and lean protein in line with the Harvard Healthy Eating Plate.',
    status: HealthStatus.healthy,
    sources: [HealthSources.harvard, HealthSources.who],
  );
}

HealthRule? _ruleBalancedSalad(ClassifiableItem item) {
  if ((item.category ?? '').toLowerCase() != 'salads') return null;
  return const HealthRule(
    id: 'salad',
    label: 'Vegetable-forward',
    reason: 'Vegetable-forward dishes help meet the WHO recommendation of ≥400 g fruit & vegetables per day.',
    status: HealthStatus.healthy,
    sources: [HealthSources.who, HealthSources.harvard],
  );
}

const List<_RuleFn> _allRules = [
  _ruleHighCalorie,
  _ruleFried,
  _ruleSugaryDrink,
  _ruleSweetDessert,
  _ruleUltraProcessedCategory,
  _ruleSellerHealthy,
  _ruleBalancedSalad,
];

// ─── Public API ────────────────────────────────────────────────────────────
ClassificationResult classifyItem(ClassifiableItem item) {
  final fired = <HealthRule>[];
  for (final rule in _allRules) {
    final hit = rule(item);
    if (hit != null) fired.add(hit);
  }
  if (fired.isEmpty) {
    return const ClassificationResult(status: HealthStatus.neutral, reasons: []);
  }

  final unhealthy = fired.where((r) => r.status == HealthStatus.unhealthy).toList();
  if (unhealthy.isNotEmpty) {
    return ClassificationResult(status: HealthStatus.unhealthy, reasons: unhealthy);
  }

  final caution = fired.where((r) => r.status == HealthStatus.caution).toList();
  if (caution.isNotEmpty) {
    final healthy = fired.where((r) => r.status == HealthStatus.healthy).toList();
    return ClassificationResult(
      status: HealthStatus.caution,
      reasons: [...caution, ...healthy],
    );
  }

  final healthy = fired.where((r) => r.status == HealthStatus.healthy).toList();
  if (healthy.isNotEmpty) {
    return ClassificationResult(status: HealthStatus.healthy, reasons: healthy);
  }
  return const ClassificationResult(status: HealthStatus.neutral, reasons: []);
}

class HealthBadge {
  final String label;
  final String tone; // 'orange' | 'green' | 'gray' | 'red'
  const HealthBadge({required this.label, required this.tone});
}

HealthBadge? badgeFor(HealthStatus status) {
  switch (status) {
    case HealthStatus.unhealthy:
      return const HealthBadge(label: 'Unhealthy', tone: 'orange');
    case HealthStatus.caution:
      return const HealthBadge(label: 'Heavy meal', tone: 'orange');
    case HealthStatus.healthy:
      return const HealthBadge(label: 'Healthy', tone: 'green');
    case HealthStatus.neutral:
      return null;
  }
}
