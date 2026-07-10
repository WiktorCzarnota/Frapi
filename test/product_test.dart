// Testy parsowania modelu Product z danych w formacie Open Food Facts.

import 'package:flutter_test/flutter_test.dart';

import 'package:frapi/models/product.dart';

void main() {
  test('fromJson: parsuje kluczowe pola i czyści alergeny', () {
    final product = Product.fromJson({
      'code': '3017620422003',
      'product_name': 'Nutella',
      'brands': 'Ferrero',
      'nutriscore_grade': 'E',
      'nova_group': 4,
      'allergens_tags': ['en:milk', 'en:nuts', 'en:soybeans'],
      'ingredients_text': 'Sucre, huile de palme, NOISETTES...',
      'nutriments': {
        'energy-kcal_100g': 539,
        'sugars_100g': 56.3,
        'proteins_100g': 6.3,
      },
    });

    expect(product.code, '3017620422003');
    expect(product.displayName, 'Nutella');
    expect(product.nutriScore, 'e'); // znormalizowane do małej litery
    expect(product.novaGroup, 4);
    expect(product.allergens, ['milk', 'nuts', 'soybeans']);
    expect(product.nutriments.energyKcal, 539);
    expect(product.nutriments.sugars, 56.3);
  });

  test('fromJson: braki danych nie wywracają parsowania', () {
    final product = Product.fromJson({'code': '0000'});

    expect(product.code, '0000');
    expect(product.name, isNull);
    expect(product.displayName, 'Produkt 0000'); // fallback na kod
    expect(product.allergens, isEmpty);
    expect(product.nutriments.sugars, isNull);
  });

  test('toJson → fromJson: produkt przetrwa zapis do historii', () {
    final original = Product.fromJson({
      'code': '3017620422003',
      'product_name': 'Nutella',
      'brands': 'Ferrero',
      'nutriscore_grade': 'e',
      'nova_group': 4,
      'allergens_tags': ['en:milk', 'en:nuts'],
      'nutriments': {'energy-kcal_100g': 539, 'sugars_100g': 56.3},
    });

    final restored = Product.fromJson(original.toJson());

    expect(restored.code, '3017620422003');
    expect(restored.displayName, 'Nutella');
    expect(restored.nutriScore, 'e');
    expect(restored.novaGroup, 4);
    expect(restored.allergens, ['milk', 'nuts']);
    expect(restored.nutriments.energyKcal, 539);
    expect(restored.nutriments.sugars, 56.3);
  });
}
