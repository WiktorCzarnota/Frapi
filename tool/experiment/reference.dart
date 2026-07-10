// Funkcja odniesienia eksperymentu: wyznacza ocenę OCZEKIWANĄ produktu wobec
// profilu na podstawie jawnych, deterministycznych kryteriów (patrz Rozdz. 4
// pracy). Nie korzysta z modelu językowego. Używana do porównania z oceną LLM.

import 'package:frapi/models/product.dart';
import 'package:frapi/models/product_analysis.dart';
import 'package:frapi/models/user_profile.dart';

/// Stałe eksperymentu: progi mapowania oraz progi "wysoko/nisko" wartości
/// odżywczych (na 100 g), zbliżone do progów stosowanych w oznaczeniach
/// front-of-pack. Zebrane w jednym miejscu, by kryteria były jawne.
class ReferenceConfig {
  static const int scorePositive = 2; // s+ : suma >= s+  -> "tak"
  static const int scoreNegative = -2; // s- : suma <= s-  -> "nie"

  // progi na 100 g
  static const double sugarHigh = 22.5, sugarLow = 5;
  static const double fatHigh = 17.5, fatLow = 3;
  static const double saltHigh = 1.5, saltLow = 0.3;
  static const double energyHigh = 350, energyLow = 100; // kcal
  static const double proteinHigh = 10, proteinLow = 5;
}

/// Ocena oczekiwana wg jawnych kryteriów (reguła twarda + punktacja).
Recommendation expectedRecommendation(Product product, UserProfile profile) {
  // 1. Reguła twarda: składnik zakazany obecny -> "nie".
  if (hasForbidden(product, profile)) return Recommendation.no;

  // 2. Punktacja.
  var score = 0;
  score += _nutriScorePoints(product.nutriScore);
  score += _novaPoints(product.novaGroup);
  if (_containsAny(product, profile.unwanted)) score -= 2;
  if (_containsAny(product, profile.preferred)) score += 1;
  score += _nutrientPrefPoints(product, profile);

  if (score >= ReferenceConfig.scorePositive) return Recommendation.yes;
  if (score <= ReferenceConfig.scoreNegative) return Recommendation.no;
  return Recommendation.moderate;
}

/// Czy produkt zawiera którykolwiek składnik zakazany w profilu.
bool hasForbidden(Product product, UserProfile profile) =>
    _containsAny(product, profile.forbidden);

int _nutriScorePoints(String? grade) {
  switch (grade?.toLowerCase()) {
    case 'a':
      return 2;
    case 'b':
      return 1;
    case 'c':
      return 0;
    case 'd':
      return -1;
    case 'e':
      return -2;
    default:
      return 0;
  }
}

int _novaPoints(int? nova) {
  if (nova == null) return 0;
  if (nova <= 2) return 1;
  if (nova == 3) return 0;
  return -1; // NOVA 4
}

/// Punkty z preferencji wartości odżywczych (mniej/więcej vs realna zawartość).
int _nutrientPrefPoints(Product product, UserProfile profile) {
  var pts = 0;
  for (final nutrient in Nutrient.values) {
    final pref = profile.preferenceOf(nutrient);
    if (pref == NutrientPreference.neutral) continue;
    final value = _valueFor(product, nutrient);
    if (value == null) continue;
    final high = _isHigh(nutrient, value);
    final low = _isLow(nutrient, value);
    if (pref == NutrientPreference.less) {
      if (high) pts -= 1;
      if (low) pts += 1;
    } else {
      // more
      if (high) pts += 1;
      if (low) pts -= 1;
    }
  }
  return pts;
}

double? _valueFor(Product product, Nutrient nutrient) {
  final n = product.nutriments;
  switch (nutrient) {
    case Nutrient.calories:
      return n.energyKcal;
    case Nutrient.sugar:
      return n.sugars;
    case Nutrient.fat:
      return n.fat;
    case Nutrient.salt:
      return n.salt;
    case Nutrient.protein:
      return n.proteins;
  }
}

bool _isHigh(Nutrient nutrient, double v) {
  switch (nutrient) {
    case Nutrient.calories:
      return v > ReferenceConfig.energyHigh;
    case Nutrient.sugar:
      return v > ReferenceConfig.sugarHigh;
    case Nutrient.fat:
      return v > ReferenceConfig.fatHigh;
    case Nutrient.salt:
      return v > ReferenceConfig.saltHigh;
    case Nutrient.protein:
      return v > ReferenceConfig.proteinHigh;
  }
}

bool _isLow(Nutrient nutrient, double v) {
  switch (nutrient) {
    case Nutrient.calories:
      return v < ReferenceConfig.energyLow;
    case Nutrient.sugar:
      return v <= ReferenceConfig.sugarLow;
    case Nutrient.fat:
      return v <= ReferenceConfig.fatLow;
    case Nutrient.salt:
      return v <= ReferenceConfig.saltLow;
    case Nutrient.protein:
      return v < ReferenceConfig.proteinLow;
  }
}

// Synonimy/odpowiedniki (PL składu i EN tagów alergenów z Open Food Facts).
const Map<String, List<String>> _synonyms = {
  'orzechy': ['orzech', 'nuts', 'nut'],
  'orzech': ['orzech', 'nuts', 'nut'],
  'gluten': ['gluten', 'pszenic', 'wheat', 'jeczmien', 'barley', 'zyto'],
  'mleko': ['mleko', 'milk', 'laktoz', 'lactose'],
  'laktoza': ['laktoz', 'milk', 'lactose', 'mleko'],
  'jaja': ['jaj', 'egg'],
  'soja': ['soja', 'soy'],
  'cukier': ['cukier', 'sugar', 'glukoz', 'fruktoz', 'syrop'],
};

/// Czy w danych produktu (skład, alergeny, nazwa) występuje którykolwiek term.
bool _containsAny(Product product, List<String> terms) {
  if (terms.isEmpty) return false;
  final hay = _normalize(
    '${product.ingredientsText ?? ''} '
    '${product.allergens.join(' ')} '
    '${product.name ?? ''}',
  );
  for (final term in terms) {
    final key = _normalize(term.trim());
    if (key.isEmpty) continue;
    final needles = _synonyms[key] ?? [key];
    for (final needle in needles) {
      if (needle.isNotEmpty && hay.contains(needle)) return true;
    }
  }
  return false;
}

/// Normalizacja: małe litery + usunięcie polskich znaków diakrytycznych.
String _normalize(String s) {
  const from = 'ąćęłńóśżź';
  const to = 'acelnoszz';
  final buffer = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final idx = from.indexOf(ch);
    buffer.write(idx >= 0 ? to[idx] : ch);
  }
  return buffer.toString();
}
