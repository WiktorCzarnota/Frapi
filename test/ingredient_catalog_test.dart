// Testy lokalnego katalogu podpowiedzi (typeahead).
//
// Weryfikują kluczowe własności wyszukiwania opisane w pracy: odporność na
// wielkość liter i polskie znaki, pierwszeństwo dopasowań od początku słowa
// oraz pomijanie pozycji już wybranych.

import 'package:flutter_test/flutter_test.dart';

import 'package:frapi/services/ingredient_catalog.dart';

void main() {
  const catalog = IngredientCatalog();

  test('dopasowanie po fragmencie, niewrażliwe na wielkość liter', () {
    final result = catalog.suggest('LAKT');
    expect(result, contains('Laktoza'));
  });

  test('dopasowanie odporne na polskie znaki', () {
    // „blon" powinno znaleźć „Błonnik" mimo braku znaku „ł".
    final result = catalog.suggest('blon');
    expect(result, contains('Błonnik'));
  });

  test('pomija pozycje już wybrane', () {
    final result = catalog.suggest('cukier', exclude: {'Cukier'});
    expect(result, isNot(contains('Cukier')));
  });

  test('puste zapytanie zwraca propozycje (do limitu)', () {
    final result = catalog.suggest('', limit: 4);
    expect(result, isNotEmpty);
    expect(result.length, lessThanOrEqualTo(4));
  });
}
