// Testy słownika składników: dzielenie składu, dopasowanie i fallback.

import 'package:flutter_test/flutter_test.dart';

import 'package:frapi/services/food_labels_info.dart';
import 'package:frapi/services/ingredient_glossary.dart';

void main() {
  const glossary = IngredientGlossary();

  group('split', () {
    test('dzieli skład i usuwa procenty oraz nawiasy', () {
      final parts = IngredientGlossary.split(
        'Sucre, huile de palme, NOISETTES 13%, cacao 7,4%',
      );
      expect(parts, contains('Sucre'));
      expect(parts, contains('huile de palme'));
      expect(parts.any((p) => p.contains('%')), isFalse);
    });

    test('pusty/niepełny skład daje pustą listę', () {
      expect(IngredientGlossary.split(null), isEmpty);
      expect(IngredientGlossary.split('   '), isEmpty);
    });
  });

  group('lookup', () {
    test('znajduje znany składnik (odporne na znaki i dodatkowe słowa)', () {
      final info = glossary.lookup('LAIT écrémé en poudre');
      expect(info.description, contains('Mleko'));
      expect(info.concern, ConcernLevel.neutral);
    });

    test('błonnik oznaczony jako korzystny', () {
      final info = glossary.lookup('Błonnik');
      expect(info.concern, ConcernLevel.beneficial);
    });

    test('nieznany składnik dostaje fallback', () {
      final info = glossary.lookup('xyzzy123');
      expect(info.concern, ConcernLevel.neutral);
      expect(info.description, contains('Nie mamy jeszcze opisu'));
    });

    test('zapytanie wyszukiwania to „co to jest {nazwa}"', () {
      expect(glossary.lookup('Olej palmowy').searchQuery,
          'co to jest Olej palmowy');
    });
  });

  group('FoodLabelsInfo', () {
    test('Nutri-Score E to wysoki poziom obaw', () {
      final info = FoodLabelsInfo.forNutriScore('e');
      expect(info.concern, ConcernLevel.caution);
      expect(info.term, contains('E'));
    });

    test('NOVA 1 jest korzystne, NOVA 4 wymaga ostrożności', () {
      expect(FoodLabelsInfo.forNova(1).concern, ConcernLevel.beneficial);
      expect(FoodLabelsInfo.forNova(4).concern, ConcernLevel.caution);
    });

    test('zapytania wyszukiwania pytają o sam system, nie o ocenę', () {
      expect(FoodLabelsInfo.forNutriScore('e').searchQuery,
          'co to jest Nutri-Score');
      expect(FoodLabelsInfo.forNova(4).searchQuery,
          contains('NOVA'));
    });
  });
}
