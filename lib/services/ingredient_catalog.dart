/// Lokalny, kuratorowany katalog popularnych składników/dodatków/pojęć,
/// używany do podpowiedzi przy wpisywaniu (autouzupełnianie typu „typeahead").
///
/// Założenia (opisane w pracy):
/// - rozwiązanie offline i deterministyczne — brak zależności od sieci,
/// - wyszukiwanie po fragmencie tekstu, odporne na wielkość liter i polskie
///   znaki diakrytyczne (np. „lakt" → „laktoza", „zihl" → „żelatyna" po
///   normalizacji), co upraszcza wpisywanie na klawiaturze mobilnej,
/// - lista jest świadomie krótka i rozszerzalna; docelowo można ją zasilić
///   taksonomiami Open Food Facts (poza zakresem MVP).
class IngredientCatalog {
  const IngredientCatalog();

  /// Surowa lista pozycji katalogu (etykiety widoczne dla użytkownika).
  static const List<String> items = [
    // Alergeny / częste nietolerancje
    'Gluten', 'Laktoza', 'Orzechy', 'Orzeszki ziemne', 'Jaja', 'Soja',
    'Ryby', 'Skorupiaki', 'Sezam', 'Gorczyca', 'Seler', 'Migdały',
    // Cukry i słodziki
    'Cukier', 'Syrop glukozowo-fruktozowy', 'Aspartam', 'Acesulfam K',
    'Ksylitol', 'Erytrytol', 'Stewia',
    // Tłuszcze
    'Olej palmowy', 'Tłuszcze trans', 'Olej rzepakowy', 'Masło',
    // Dodatki (E)
    'E621 (glutaminian sodu)', 'E250 (azotyn sodu)', 'E951 (aspartam)',
    'Konserwanty', 'Barwniki', 'Wzmacniacze smaku',
    // Składniki pożądane
    'Białko', 'Błonnik', 'Pełne ziarno', 'Owoce', 'Warzywa',
    'Kwasy omega-3', 'Wapń', 'Żelazo', 'Witamina C', 'Probiotyki',
    // Inne częste
    'Sól', 'Kofeina', 'Alkohol', 'Żelatyna', 'Drożdże', 'Kakao',
  ];

  /// Zwraca do [limit] podpowiedzi pasujących do [query].
  ///
  /// Dopasowanie: znormalizowane [query] jest fragmentem znormalizowanej
  /// pozycji. Pozycje zaczynające się od zapytania mają pierwszeństwo.
  /// Pozycje już wybrane ([exclude]) są pomijane.
  List<String> suggest(
    String query, {
    Set<String> exclude = const {},
    int limit = 6,
  }) {
    final normalizedQuery = _normalize(query);
    final excluded = exclude.map(_normalize).toSet();

    final prefixMatches = <String>[];
    final substringMatches = <String>[];

    for (final item in items) {
      final normalizedItem = _normalize(item);
      if (excluded.contains(normalizedItem)) continue;
      if (normalizedQuery.isEmpty) {
        prefixMatches.add(item);
      } else if (normalizedItem.startsWith(normalizedQuery)) {
        prefixMatches.add(item);
      } else if (normalizedItem.contains(normalizedQuery)) {
        substringMatches.add(item);
      }
    }

    return [...prefixMatches, ...substringMatches].take(limit).toList();
  }

  /// Normalizacja: małe litery + zamiana polskich znaków na podstawowe.
  static String _normalize(String text) {
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_diacritics[char] ?? char);
    }
    return buffer.toString().trim();
  }

  static const Map<String, String> _diacritics = {
    'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n',
    'ó': 'o', 'ś': 's', 'ź': 'z', 'ż': 'z',
  };
}
