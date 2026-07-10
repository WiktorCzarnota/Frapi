import 'ingredient_glossary.dart';

/// Wyjaśnienia etykiet żywieniowych: Nutri-Score i klasyfikacja NOVA.
///
/// Teksty są lokalne (offline). Każde wyjaśnienie zawiera ogólny opis systemu
/// oraz interpretację konkretnej oceny danego produktu, wraz z poziomem obaw.
class FoodLabelsInfo {
  const FoodLabelsInfo._();

  /// Ogólny opis systemu Nutri-Score.
  static const String nutriScoreIntro =
      'Nutri-Score to etykieta oceniająca ogólną wartość odżywczą produktu '
      'w skali od A (najlepszy) do E (najgorszy). Bierze pod uwagę m.in. cukry, '
      'tłuszcze nasycone, sól oraz korzystne składniki (błonnik, białko, owoce).';

  /// Ogólny opis klasyfikacji NOVA.
  static const String novaIntro =
      'NOVA dzieli żywność według stopnia przetworzenia w skali 1-4: '
      'od produktów nieprzetworzonych (1) po żywność wysoko przetworzoną (4).';

  /// Interpretacja konkretnej oceny Nutri-Score („a"–„e").
  static IngredientExplanation forNutriScore(String grade) {
    final g = grade.toLowerCase();
    final (desc, concern) = switch (g) {
      'a' => ('Bardzo dobra wartość odżywcza. Produkt z grupy najzdrowszych.',
          ConcernLevel.beneficial),
      'b' => ('Dobra wartość odżywcza.', ConcernLevel.beneficial),
      'c' => ('Przeciętna wartość odżywcza - w sam raz z umiarem.',
          ConcernLevel.moderate),
      'd' => ('Słaba wartość odżywcza - lepiej ograniczać.',
          ConcernLevel.caution),
      'e' => ('Bardzo słaba wartość odżywcza - jedz okazjonalnie.',
          ConcernLevel.caution),
      _ => ('Brak oceny Nutri-Score dla tego produktu.', ConcernLevel.neutral),
    };
    return IngredientExplanation(
      term: 'Nutri-Score: ${grade.toUpperCase()}',
      description: '$nutriScoreIntro\n\n$desc',
      concern: concern,
      searchQuery: 'co to jest Nutri-Score',
    );
  }

  /// Interpretacja konkretnej grupy NOVA (1–4).
  static IngredientExplanation forNova(int group) {
    final (desc, concern) = switch (group) {
      1 => ('Żywność nieprzetworzona lub minimalnie przetworzona '
            '(np. warzywa, kasze).', ConcernLevel.beneficial),
      2 => ('Przetworzone składniki kulinarne (np. oleje, masło, cukier).',
          ConcernLevel.neutral),
      3 => ('Żywność przetworzona (np. pieczywo, sery, konserwy).',
          ConcernLevel.moderate),
      4 => ('Żywność wysoko przetworzona - zwykle z dodatkami, cukrem i solą. '
            'Lepiej ograniczać.', ConcernLevel.caution),
      _ => ('Brak klasyfikacji NOVA dla tego produktu.', ConcernLevel.neutral),
    };
    return IngredientExplanation(
      term: 'NOVA: $group',
      description: '$novaIntro\n\n$desc',
      concern: concern,
      searchQuery: 'co to jest klasyfikacja NOVA w żywności',
    );
  }
}
