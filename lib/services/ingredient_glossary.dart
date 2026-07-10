/// Poziom „czy trzeba się bać" składnika — wspólny dla składników i ocen.
enum ConcernLevel {
  beneficial('Korzystny', 0xFF2E7D32), // zielony
  neutral('Neutralny', 0xFF616161), // szary
  moderate('Z umiarem', 0xFFEF6C00), // pomarańczowy
  caution('Ostrożnie', 0xFFD32F2F); // czerwony

  const ConcernLevel(this.label, this.colorValue);

  /// Etykieta widoczna w UI.
  final String label;

  /// Kolor akcentu (jako wartość ARGB — widget tworzy z niej Color).
  final int colorValue;
}

/// Proste wyjaśnienie pojedynczego składnika.
class IngredientExplanation {
  IngredientExplanation({
    required this.term,
    required this.description,
    required this.concern,
    String? searchQuery,
  }) : searchQuery = searchQuery ?? 'co to jest $term';

  /// Nazwa wyświetlana (np. „Olej palmowy").
  final String term;

  /// Krótkie wyjaśnienie prostym językiem.
  final String description;

  /// Poziom „czy się bać".
  final ConcernLevel concern;

  /// Zapytanie do wyszukiwarki dla przycisku „Czytaj więcej"
  /// (domyślnie „co to jest {term}").
  final String searchQuery;
}

/// Lokalny słownik popularnych składników i dodatków.
///
/// Rozwiązanie offline i deterministyczne — działa od razu i jest testowalne.
/// Dla składników spoza słownika zwracamy ogólne wyjaśnienie; docelowo lukę
/// wypełni LLM (osobny, zaplanowany krok). Dopasowanie jest odporne na
/// wielkość liter i polskie znaki, i działa „po fragmencie" (token składu może
/// zawierać dodatkowe słowa, np. „LAIT écrémé en poudre" → „mleko").
class IngredientGlossary {
  const IngredientGlossary();

  /// Dzieli surowy skład na pojedyncze pozycje.
  ///
  /// Usuwa nawiasy, procenty i nadmiarowe białe znaki. To uproszczone
  /// parsowanie wystarcza do prezentacji; pełna analiza składu należy do LLM.
  static List<String> split(String? ingredientsText) {
    if (ingredientsText == null || ingredientsText.trim().isEmpty) {
      return const [];
    }
    final withoutBrackets =
        ingredientsText.replaceAll(RegExp(r'[\(\)\[\]]'), ',');
    return withoutBrackets
        .split(RegExp(r'[,;]'))
        .map((part) => part.replaceAll(RegExp(r'[0-9]+([.,][0-9]+)?\s*%'), ''))
        .map((part) => part.replaceAll(RegExp(r'[.]+$'), '').trim())
        .where((part) => part.isNotEmpty && part.length > 1)
        .toList();
  }

  /// Zwraca wyjaśnienie dla danego składnika (z fallbackiem dla nieznanych).
  IngredientExplanation lookup(String ingredient) {
    final normalized = _normalize(ingredient);
    for (final entry in _entries.entries) {
      if (normalized.contains(entry.key)) {
        return IngredientExplanation(
          term: ingredient.trim(),
          description: entry.value.$1,
          concern: entry.value.$2,
        );
      }
    }
    return IngredientExplanation(
      term: ingredient.trim(),
      description:
          'Nie mamy jeszcze opisu tego składnika. Skorzystaj z linku poniżej, '
          'aby dowiedzieć się o nim więcej.',
      concern: ConcernLevel.neutral,
    );
  }

  /// Słownik: znormalizowany klucz → (opis, poziom obaw).
  static const Map<String, (String, ConcernLevel)> _entries = {
    'cukier': (
      'Cukier dodany. Dostarcza pustych kalorii; nadmiar sprzyja próchnicy, '
          'tyciu i wahaniom energii. W większości produktów warto go ograniczać.',
      ConcernLevel.moderate,
    ),
    'sol': (
      'Sól (sód). Potrzebna w małych ilościach, ale nadmiar podnosi ciśnienie '
          'krwi. Produkty mocno solone lepiej jeść z umiarem.',
      ConcernLevel.moderate,
    ),
    'olej palmowy': (
      'Tłuszcz roślinny bogaty w nasycone kwasy tłuszczowe. Bezpieczny w małych '
          'ilościach, ale jego nadmiar bywa niekorzystny dla serca.',
      ConcernLevel.moderate,
    ),
    'tluszcze trans': (
      'Tłuszcze utwardzone (uwodornione). Najbardziej niekorzystny rodzaj '
          'tłuszczu - warto ich unikać.',
      ConcernLevel.caution,
    ),
    'syrop glukozowo-fruktozowy': (
      'Tani słodzik płynny. Działa podobnie jak cukier; łatwo go przedawkować '
          'w słodkich napojach i przekąskach.',
      ConcernLevel.moderate,
    ),
    'blonnik': (
      'Błonnik pokarmowy. Wspiera trawienie i daje sytość - składnik korzystny.',
      ConcernLevel.beneficial,
    ),
    'bialko': (
      'Białko. Niezbędny budulec organizmu; pomaga w sytości i regeneracji.',
      ConcernLevel.beneficial,
    ),
    'mleko': (
      'Mleko / składniki mleczne. Źródło wapnia i białka. Uwaga przy alergii na '
          'białka mleka lub nietolerancji laktozy.',
      ConcernLevel.neutral,
    ),
    'laktoza': (
      'Cukier mleczny. Nieszkodliwy, ale u osób z nietolerancją powoduje '
          'dolegliwości trawienne.',
      ConcernLevel.neutral,
    ),
    'gluten': (
      'Białko zbóż (pszenica, żyto, jęczmień). Problem tylko dla osób z celiakią '
          'lub nietolerancją - dla pozostałych nieszkodliwy.',
      ConcernLevel.neutral,
    ),
    'lecytyn': (
      'Emulgator (często z soi lub słonecznika). Łączy tłuszcz z wodą. '
          'Uznawany za bezpieczny.',
      ConcernLevel.neutral,
    ),
    'aromat': (
      'Substancja nadająca smak/zapach. Dozwolona i bezpieczna, choć świadczy '
          'o przetworzeniu produktu.',
      ConcernLevel.neutral,
    ),
    'kakao': (
      'Miazga / proszek kakaowy. Źródło przeciwutleniaczy; w czystej postaci '
          'korzystne, problemem bywa towarzyszący cukier.',
      ConcernLevel.neutral,
    ),
    'e621': (
      'Glutaminian sodu - wzmacniacz smaku. Bezpieczny w typowych ilościach, '
          'choć kojarzony z mocno przetworzoną żywnością.',
      ConcernLevel.moderate,
    ),
    'e250': (
      'Azotyn sodu - konserwant peklujący mięso. W nadmiarze niewskazany; '
          'spożywaj wędliny z umiarem.',
      ConcernLevel.caution,
    ),
    'aspartam': (
      'Słodzik intensywny (E951). Bezpieczny w dopuszczalnych dawkach; '
          'przeciwwskazany przy fenyloketonurii.',
      ConcernLevel.moderate,
    ),
    'barwnik': (
      'Substancja nadająca kolor. Część barwników bywa kontrowersyjna - '
          'świadczy o przetworzeniu produktu.',
      ConcernLevel.moderate,
    ),
    'konserwant': (
      'Substancja przedłużająca trwałość. Dozwolone są bezpieczne, ale ich '
          'obecność wskazuje na przetworzenie.',
      ConcernLevel.moderate,
    ),
    // Aliasy obcojęzyczne dla popularnych produktów (np. skład po francusku).
    'sucre': (
      'Cukier (fr. sucre). Dostarcza pustych kalorii; nadmiar sprzyja tyciu '
          'i próchnicy. Warto ograniczać.',
      ConcernLevel.moderate,
    ),
    'huile de palme': (
      'Olej palmowy (fr.). Bogaty w tłuszcze nasycone; jego nadmiar bywa '
          'niekorzystny dla serca.',
      ConcernLevel.moderate,
    ),
    'lait': (
      'Mleko / składniki mleczne (fr. lait). Źródło wapnia i białka. Uwaga przy '
          'alergii lub nietolerancji laktozy.',
      ConcernLevel.neutral,
    ),
    'lactoserum': (
      'Serwatka (fr. lactosérum). Białkowy składnik mleczny; zwykle dobrze '
          'tolerowany poza alergią na mleko.',
      ConcernLevel.neutral,
    ),
    'noisette': (
      'Orzechy laskowe (fr. noisettes). Wartościowe tłuszcze i białko, ale '
          'silny alergen - uwaga przy uczuleniu na orzechy.',
      ConcernLevel.neutral,
    ),
    'cacao': (
      'Kakao (fr. cacao). Źródło przeciwutleniaczy; problemem bywa towarzyszący '
          'cukier.',
      ConcernLevel.neutral,
    ),
    'lecithine': (
      'Lecytyna (fr. lécithine) - emulgator łączący tłuszcz z wodą. '
          'Uznawana za bezpieczną.',
      ConcernLevel.neutral,
    ),
    'vanilline': (
      'Wanilina (fr. vanilline) - aromat o smaku wanilii. Bezpieczna, świadczy '
          'o przetworzeniu produktu.',
      ConcernLevel.neutral,
    ),
  };

  /// Normalizacja: małe litery + zamiana polskich/francuskich znaków.
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
    'à': 'a', 'â': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', ' î': 'i',
    'ï': 'i', 'ô': 'o', 'û': 'u', 'ù': 'u', 'ç': 'c',
  };
}
