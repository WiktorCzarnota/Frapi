// Testy funkcji odniesienia eksperymentu (ocena oczekiwana wg jawnych kryteriow).

import 'package:flutter_test/flutter_test.dart';

import 'package:frapi/models/product.dart';
import 'package:frapi/models/product_analysis.dart';
import 'package:frapi/models/user_profile.dart';

import '../tool/experiment/reference.dart';

Product product({
  String? nutriScore,
  int? nova,
  List<String> allergens = const [],
  String? ingredients,
  double? sugars,
  double? proteins,
}) {
  return Product(
    code: '1',
    name: 'Test',
    nutriScore: nutriScore,
    novaGroup: nova,
    allergens: allergens,
    ingredientsText: ingredients,
    nutriments: Nutriments(sugars: sugars, proteins: proteins),
  );
}

void main() {
  const alergik = UserProfile(forbidden: ['orzechy', 'gluten']);
  const cukrzyca = UserProfile(
    unwanted: ['cukier'],
    nutrientPrefs: {Nutrient.sugar: NutrientPreference.less},
  );
  const sportowiec = UserProfile(
    nutrientPrefs: {Nutrient.protein: NutrientPreference.more},
  );
  const bezOgraniczen = UserProfile();

  test('regula twarda: alergen w skladzie -> "nie"', () {
    final p = product(ingredients: 'maka, orzechy laskowe, cukier');
    expect(hasForbidden(p, alergik), isTrue);
    expect(expectedRecommendation(p, alergik), Recommendation.no);
  });

  test('regula twarda: alergen z tagow (EN) -> "nie"', () {
    final p = product(allergens: ['gluten'], nutriScore: 'a', nova: 1);
    expect(expectedRecommendation(p, alergik), Recommendation.no);
  });

  test('produkt zdrowy, brak ograniczen -> "tak"', () {
    final p = product(nutriScore: 'a', nova: 1);
    expect(expectedRecommendation(p, bezOgraniczen), Recommendation.yes);
  });

  test('produkt niezdrowy -> "nie"', () {
    final p = product(nutriScore: 'e', nova: 4);
    expect(expectedRecommendation(p, bezOgraniczen), Recommendation.no);
  });

  test('cukrzyca: duzo cukru + niechciany cukier -> "nie"', () {
    final p = product(
      nutriScore: 'c',
      nova: 4,
      ingredients: 'cukier, maka',
      sugars: 40,
    );
    expect(expectedRecommendation(p, cukrzyca), Recommendation.no);
  });

  test('sportowiec: wysokie bialko w dobrym produkcie -> "tak"', () {
    final p = product(nutriScore: 'a', nova: 1, proteins: 20);
    expect(expectedRecommendation(p, sportowiec), Recommendation.yes);
  });

  test('brak forbidden gdy profil pusty', () {
    final p = product(ingredients: 'orzechy');
    expect(hasForbidden(p, bezOgraniczen), isFalse);
  });
}
