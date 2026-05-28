import 'package:flutter_test/flutter_test.dart';
import 'package:food_app1_flutter/utils/health_classification.dart';

ClassifiableItem item({
  String name = 'Plain Rice',
  String? category = 'Main Course',
  int? calories = 300,
  bool isHealthy = false,
}) =>
    ClassifiableItem(
      name: name,
      category: category,
      calories: calories,
      isHealthy: isHealthy,
    );

void main() {
  group('classifyItem — unhealthy rules', () {
    test('fried items get flagged with WHO + USDA citations', () {
      final r = classifyItem(
          item(name: 'French Fries', category: 'Snacks', calories: 380));
      expect(r.status, HealthStatus.unhealthy);
      final fried = r.reasons.firstWhere((x) => x.id == 'fried');
      expect(fried.sources, contains(HealthSources.who));
      expect(fried.sources, contains(HealthSources.usda));
    });

    test('sugary drinks cite WHO + FSA + USDA', () {
      final r = classifyItem(
          item(name: 'Cola', category: 'Drinks', calories: 140));
      expect(r.status, HealthStatus.unhealthy);
      final sugar = r.reasons.firstWhere((x) => x.id == 'sugary-drink');
      final shorts = sugar.sources.map((s) => s.short).toList();
      expect(shorts, contains(HealthSources.who.short));
      expect(shorts, contains(HealthSources.fsa.short));
      expect(shorts, contains(HealthSources.usda.short));
    });

    test('desserts are unhealthy with NOVA + Nutri-Score citations', () {
      final r = classifyItem(item(
          name: 'Chocolate Cake', category: 'Desserts', calories: 420));
      expect(r.status, HealthStatus.unhealthy);
      final ids = r.reasons.map((x) => x.id).toList();
      expect(ids, contains('sweet-dessert'));
      expect(ids, contains('ultra-processed'));
      final nova =
          r.reasons.firstWhere((x) => x.id == 'ultra-processed');
      expect(nova.sources, contains(HealthSources.nova));
      expect(nova.sources, contains(HealthSources.nutriScore));
    });

    test('"Snacks" category triggers ultra-processed (NOVA Group 4)', () {
      final r = classifyItem(
          item(name: 'Potato Chips', category: 'Snacks', calories: 250));
      expect(r.status, HealthStatus.unhealthy);
      expect(r.reasons.any((x) => x.id == 'ultra-processed'), isTrue);
    });

    test('fried indicators in name fire regardless of category', () {
      final r = classifyItem(item(name: 'Tempura Shrimp'));
      expect(r.status, HealthStatus.unhealthy);
      expect(r.reasons.any((x) => x.id == 'fried'), isTrue);
    });

    test('milk tea is caught as a sugary drink', () {
      final r = classifyItem(
          item(name: 'Iced Milk Tea', category: 'Drinks', calories: 180));
      expect(r.status, HealthStatus.unhealthy);
      expect(r.reasons.any((x) => x.id == 'sugary-drink'), isTrue);
    });
  });

  group('classifyItem — drinks coverage', () {
    test('generic non-healthy drink gets a caution', () {
      final r = classifyItem(
          item(name: 'House Special Cooler', category: 'Drinks', calories: 120));
      expect(r.status, HealthStatus.caution);
      expect(r.reasons.any((x) => x.id == 'sweetened-drink'), isTrue);
    });

    test('explicitly unsweetened drink is not flagged', () {
      final r = classifyItem(
          item(name: 'Sparkling Water', category: 'Drinks', calories: 0));
      expect(r.status, HealthStatus.neutral);
    });

    test('keyword drink stays unhealthy, not double-flagged caution', () {
      final r = classifyItem(
          item(name: 'Bubble Tea', category: 'Drinks', calories: 250));
      expect(r.status, HealthStatus.unhealthy);
      expect(r.reasons.any((x) => x.id == 'sweetened-drink'), isFalse);
    });
  });

  group('classifyItem — healthy rules', () {
    test('salads cite WHO + Harvard', () {
      final r = classifyItem(
          item(name: 'Buddha Bowl', category: 'Salads', calories: 480));
      expect(r.status, HealthStatus.healthy);
      final salad = r.reasons.firstWhere((x) => x.id == 'salad');
      expect(salad.sources, contains(HealthSources.who));
      expect(salad.sources, contains(HealthSources.harvard));
    });

    test('seller-tagged isHealthy flag is honoured', () {
      final r = classifyItem(item(
          name: 'Grilled Chicken Bowl', isHealthy: true, calories: 540));
      expect(r.status, HealthStatus.healthy);
      expect(r.reasons.any((x) => x.id == 'seller-healthy'), isTrue);
    });
  });

  group('classifyItem — caution rule', () {
    test('700+ kcal triggers caution if nothing else fires', () {
      final r = classifyItem(item(name: 'Beef Lok Lak', calories: 850));
      expect(r.status, HealthStatus.caution);
      expect(r.reasons.any((x) => x.id == 'high-calorie'), isTrue);
    });

    test('< 700 kcal does not trigger caution', () {
      final r = classifyItem(item(name: 'Rice Porridge', calories: 280));
      expect(r.reasons.any((x) => x.id == 'high-calorie'), isFalse);
    });
  });

  group('classifyItem — precedence', () {
    test('unhealthy outranks caution: fried high-calorie is unhealthy', () {
      final r =
          classifyItem(item(name: 'Deep Fried Chicken', calories: 920));
      expect(r.status, HealthStatus.unhealthy);
      expect(r.reasons.every((x) => x.status == HealthStatus.unhealthy), isTrue);
    });

    test('caution still surfaces healthy reasons', () {
      final r = classifyItem(item(
          name: 'Hearty Buddha Bowl',
          category: 'Salads',
          calories: 780,
          isHealthy: true));
      expect(r.status, HealthStatus.caution);
      expect(r.reasons.any((x) => x.id == 'high-calorie'), isTrue);
      expect(r.reasons.any((x) => x.status == HealthStatus.healthy), isTrue);
    });

    test('returns neutral when nothing fires', () {
      final r = classifyItem(item(name: 'Plain Rice', calories: 300));
      expect(r.status, HealthStatus.neutral);
      expect(r.reasons, isEmpty);
    });
  });

  group('badgeFor', () {
    test('orange Unhealthy badge', () {
      final b = badgeFor(HealthStatus.unhealthy)!;
      expect(b.label, 'Unhealthy');
      expect(b.tone, 'orange');
    });

    test('"Heavy meal" for caution', () {
      final b = badgeFor(HealthStatus.caution)!;
      expect(b.label, 'Heavy meal');
      expect(b.tone, 'orange');
    });

    test('green Healthy badge', () {
      final b = badgeFor(HealthStatus.healthy)!;
      expect(b.label, 'Healthy');
      expect(b.tone, 'green');
    });

    test('null for neutral (no badge rendered)', () {
      expect(badgeFor(HealthStatus.neutral), isNull);
    });
  });

  group('sources', () {
    test('every source has non-empty fields and a valid URL', () {
      for (final s in HealthSources.all) {
        expect(s.short, isNotEmpty);
        expect(s.full, isNotEmpty);
        expect(RegExp(r'^https?://').hasMatch(s.url), isTrue,
            reason: 'Bad URL on ${s.short}');
      }
    });
  });
}
