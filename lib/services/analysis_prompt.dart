import '../models/product.dart';
import '../models/user_profile.dart';

/// Buduje prompt do analizy produktu przez LLM (produkt + profil → rekomendacja).
///
/// Prompt engineering jest częścią pracy dyplomowej, dlatego trzymamy go
/// w jednym, dobrze opisanym miejscu. System prompt ustala rolę i zasady
/// (m.in. twardą blokadę składników zakazanych), a wiadomość użytkownika
/// dostarcza konkretne dane produktu i profilu.
class AnalysisPrompt {
  const AnalysisPrompt._();

  /// Instrukcja systemowa analizy — interpretacja + ocena (funkcje 1-2).
  static const String system =
      'Jesteś asystentem zdrowego żywienia w polskiej aplikacji do świadomych '
      'zakupów spożywczych. Na podstawie danych produktu i profilu użytkownika:\n'
      '1) krótko wyjaśnij, na co zwrócić uwagę w tym produkcie (summary),\n'
      '2) oceń dopasowanie do profilu jako "tak", "z umiarem" lub "nie" '
      '(recommendation) z krótkim uzasadnieniem (recommendationReason).\n'
      '\n'
      'WAŻNE — NIE powtarzaj danych, które użytkownik już widzi na ekranie '
      '(lista składników, wartości odżywcze, Nutri-Score, NOVA, alergeny). '
      'Zamiast je przepisywać, ZINTERPRETUJ je: powiedz, co z nich wynika dla '
      'tego użytkownika i jego profilu.\n'
      '\n'
      'STYL — zwięźle i konkretnie: summary 1-2 zdania; recommendationReason '
      '1-2 zdania (najważniejszy powód na początku). Odwołuj się wprost do '
      'profilu (które jego zakazane/niechciane/zalecane pozycje wystąpiły). '
      'Unikaj ogólników ("to zależy", "warto zwrócić uwagę") i straszenia. '
      'Bez powtarzania nazwy produktu. Po polsku.\n'
      '\n'
      'ZASADA: jeśli produkt zawiera składnik z listy ZAKAZANYCH użytkownika, '
      'recommendation MUSI być "nie". Składniki NIECHCIANE obniżają ocenę, '
      'ZALECANE ją podnoszą. Uwzględnij wagi aspektów (1-5) oraz to, co '
      'użytkownik chce, by AI o nim wiedziało.';

  /// Instrukcja systemowa zamienników — osobna funkcja (funkcja 3).
  static const String alternativesSystem =
      'Jesteś asystentem zdrowego żywienia. Zaproponuj 2-3 konkretne, zdrowsze '
      'zamienniki dla podanego produktu, dopasowane do profilu użytkownika.\n'
      'Każdy zamiennik to typ produktu (nie marka) + jedno krótkie zdanie '
      'uzasadnienia opartego na konkretach (np. mniej cukru, więcej białka, '
      'mniej przetworzony). NIE proponuj zamienników zawierających składniki '
      'ZAKAZANE ani NIECHCIANE użytkownika. Po polsku, zwięźle.';

  /// Instrukcja systemowa ekstrakcji danych ze zdjęcia etykiety.
  ///
  /// Używana, gdy produktu nie ma w Open Food Facts (lub dane są niepełne):
  /// model z wizją odczytuje tabelę wartości odżywczych i skład ze zdjęcia
  /// i zwraca je w kluczach zgodnych z Open Food Facts (`Product.fromJson`),
  /// dzięki czemu dalszy przepływ (analiza, historia) pozostaje bez zmian.
  static const String labelExtractionSystem =
      'Jesteś systemem OCR/ekstrakcji danych z etykiet produktów spożywczych. '
      'Na zdjęciu jest etykieta (tabela wartości odżywczych i/lub skład). '
      'Odczytaj dane i zwróć je w JSON o kluczach zgodnych z Open Food Facts:\n'
      '{"product_name": tekst|null, "brands": tekst|null, '
      '"quantity": tekst|null, "ingredients_text": tekst|null, '
      '"nutriments": {"energy-kcal_100g": liczba|null, "fat_100g": liczba|null, '
      '"saturated-fat_100g": liczba|null, "carbohydrates_100g": liczba|null, '
      '"sugars_100g": liczba|null, "proteins_100g": liczba|null, '
      '"salt_100g": liczba|null}}\n'
      'ZASADY: wartości odżywcze podawaj na 100 g/ml (jeśli etykieta podaje '
      'na porcję, przelicz na 100 g, gdy znasz gramaturę; w innym razie null). '
      'Liczby jako liczby (kropka dziesiętna), bez jednostek. Sól: jeśli podano '
      'tylko sód (sodium), przelicz na sól (sól = sód * 2,5). Czego nie widać '
      'lub nie da się pewnie odczytać — wpisz null, nie zgaduj. Skład przepisz '
      'dosłownie z etykiety. Zwróć wyłącznie ten obiekt JSON, nic poza nim.';

  /// Instrukcja systemowa porównania kilku produktów (funkcja porównywarki).
  static const String comparisonSystem =
      'Jesteś asystentem zdrowego żywienia. Porównujesz 2-6 produktów '
      'spożywczych i wskazujesz, który jest najlepszym wyborem dla tego '
      'użytkownika oraz czym się wyróżnia.\n'
      'STYL: zwięźle, 1-2 zdania, po polsku. Nie przepisuj surowych liczb — '
      'wyciągnij wniosek (np. „ma najmniej cukru i najwięcej białka"). '
      'Uwzględnij profil użytkownika (zakazane/niechciane/zalecane, cel). '
      'Wskaż dokładnie jeden najlepszy produkt (pole "best" = jego nazwa).';

  /// Treść wiadomości użytkownika — lista porównywanych produktów i profil.
  static String comparisonMessage(List<Product> products, UserProfile profile) {
    final buffer = StringBuffer()..writeln('PRODUKTY DO PORÓWNANIA:');
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      buffer
        ..writeln('${i + 1}. ${p.displayName}')
        ..writeln('   Nutri-Score: ${p.nutriScore?.toUpperCase() ?? "brak"}, '
            'NOVA: ${p.novaGroup ?? "brak"}')
        ..writeln('   ${_nutrimentsLine(p)}');
    }
    buffer
      ..writeln()
      ..writeln('PROFIL UŻYTKOWNIKA:')
      ..writeln('- Zakazane (twarda blokada): ${_list(profile.forbidden)}')
      ..writeln('- Niechciane: ${_list(profile.unwanted)}')
      ..writeln('- Zalecane: ${_list(profile.preferred)}')
      ..writeln('- Cel / styl życia: ${_needs(profile)}')
      ..writeln('- Preferencje wartości odżywczych: ${_nutrientPrefs(profile)}');
    return buffer.toString();
  }

  /// Treść wiadomości użytkownika — dane produktu i profilu.
  static String userMessage(Product product, UserProfile profile) {
    final buffer = StringBuffer()
      ..writeln('PRODUKT:')
      ..writeln('- Nazwa: ${product.displayName}')
      ..writeln('- Marka: ${product.brands ?? "brak"}')
      ..writeln('- Skład: ${product.ingredientsText ?? "brak danych"}')
      ..writeln('- Nutri-Score: ${product.nutriScore?.toUpperCase() ?? "brak"}')
      ..writeln('- NOVA: ${product.novaGroup ?? "brak"}')
      ..writeln(
        '- Alergeny (z bazy): '
        '${product.allergens.isEmpty ? "brak" : product.allergens.join(", ")}',
      )
      ..writeln(_nutrimentsLine(product))
      ..writeln()
      ..writeln('PROFIL UŻYTKOWNIKA:')
      ..writeln('- Zakazane (twarda blokada): ${_list(profile.forbidden)}')
      ..writeln('- Niechciane: ${_list(profile.unwanted)}')
      ..writeln('- Zalecane: ${_list(profile.preferred)}')
      ..writeln('- Cel / styl życia: ${_needs(profile)}')
      ..writeln('- Preferencje wartości odżywczych: ${_nutrientPrefs(profile)}');
    return buffer.toString();
  }

  /// Preferencje wartości odżywczych (tylko te inne niż „obojętnie").
  static String _nutrientPrefs(UserProfile profile) {
    final parts = <String>[
      for (final nutrient in Nutrient.values)
        if (profile.preferenceOf(nutrient) != NutrientPreference.neutral)
          '${nutrient.label.toLowerCase()} '
              '${profile.preferenceOf(nutrient).label}',
    ];
    return parts.isEmpty ? 'brak szczególnych' : parts.join(', ');
  }

  static String _nutrimentsLine(Product product) {
    final n = product.nutriments;
    final parts = <String>[
      if (n.energyKcal != null) 'energia ${n.energyKcal} kcal',
      if (n.sugars != null) 'cukry ${n.sugars} g',
      if (n.fat != null) 'tłuszcz ${n.fat} g',
      if (n.salt != null) 'sól ${n.salt} g',
      if (n.proteins != null) 'białko ${n.proteins} g',
    ];
    return '- Wartości odżywcze (na 100 g): '
        '${parts.isEmpty ? "brak" : parts.join(", ")}';
  }

  static String _list(List<String> items) =>
      items.isEmpty ? 'brak' : items.join(', ');

  static String _needs(UserProfile profile) {
    final all = [
      ...profile.needs.map((n) => n.label),
      ...profile.customNeeds,
    ];
    return all.isEmpty ? 'brak' : all.join(', ');
  }
}
