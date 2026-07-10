/// Profil użytkownika wpływający na personalizowaną ocenę produktów (funkcja 2 MVP).
///
/// Profil jest przechowywany lokalnie (bez backendu) i trafia do promptu LLM
/// razem z danymi produktu, aby ocena była dopasowana do potrzeb użytkownika.
///
/// Trzy listy tagów wyrażają stosunek użytkownika do składników (lub innych
/// pojęć — kategorii, dodatków E):
/// - [forbidden] — twarda blokada (np. alergie); produkt z tym ma być odrzucony,
/// - [unwanted]  — unikane, ale dopuszczalne (obniżają ocenę),
/// - [preferred] — pożądane (podnoszą ocenę).
class UserProfile {
  const UserProfile({
    this.forbidden = const [],
    this.unwanted = const [],
    this.preferred = const [],
    this.needs = const {},
    this.customNeeds = const [],
    this.nutrientPrefs = const {},
  });

  /// Składniki/pojęcia kategorycznie zakazane (twarda blokada).
  final List<String> forbidden;

  /// Składniki/pojęcia niechciane, ale dopuszczalne.
  final List<String> unwanted;

  /// Składniki/pojęcia pożądane przez użytkownika.
  final List<String> preferred;

  /// Ogólne potrzeby żywieniowe wybrane z listy (wielokrotny wybór).
  final Set<DietaryNeed> needs;

  /// Własne, wpisane przez użytkownika potrzeby (spoza listy).
  final List<String> customNeeds;

  /// Preferencje co do wartości odżywczych (mniej / obojętnie / więcej).
  /// Brak wpisu = [NutrientPreference.neutral].
  final Map<Nutrient, NutrientPreference> nutrientPrefs;

  /// Preferencja dla danej wartości odżywczej (domyślnie „obojętnie").
  NutrientPreference preferenceOf(Nutrient nutrient) =>
      nutrientPrefs[nutrient] ?? NutrientPreference.neutral;

  /// Kopia profilu ze zmienionymi wybranymi polami.
  UserProfile copyWith({
    List<String>? forbidden,
    List<String>? unwanted,
    List<String>? preferred,
    Set<DietaryNeed>? needs,
    List<String>? customNeeds,
    Map<Nutrient, NutrientPreference>? nutrientPrefs,
  }) {
    return UserProfile(
      forbidden: forbidden ?? this.forbidden,
      unwanted: unwanted ?? this.unwanted,
      preferred: preferred ?? this.preferred,
      needs: needs ?? this.needs,
      customNeeds: customNeeds ?? this.customNeeds,
      nutrientPrefs: nutrientPrefs ?? this.nutrientPrefs,
    );
  }

  /// Serializacja do prostej mapy (zapis w shared_preferences jako JSON).
  Map<String, dynamic> toJson() {
    return {
      'forbidden': forbidden,
      'unwanted': unwanted,
      'preferred': preferred,
      'needs': needs.map((n) => n.name).toList(),
      'customNeeds': customNeeds,
      'nutrientPrefs': {
        for (final entry in nutrientPrefs.entries)
          entry.key.name: entry.value.name,
      },
    };
  }

  /// Odtworzenie profilu z mapy. Nieznane/uszkodzone wartości → wartości domyślne.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      forbidden: _stringList(json['forbidden']),
      unwanted: _stringList(json['unwanted']),
      preferred: _stringList(json['preferred']),
      needs: (json['needs'] as List<dynamic>? ?? [])
          .map((name) => _enumByName(DietaryNeed.values, name))
          .whereType<DietaryNeed>()
          .toSet(),
      customNeeds: _stringList(json['customNeeds']),
      nutrientPrefs: _nutrientPrefs(json['nutrientPrefs']),
    );
  }
}

/// Bezpieczne wczytanie listy napisów (pomija wartości nietekstowe).
List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}

/// Bezpieczne wczytanie map preferencji wartości odżywczych.
Map<Nutrient, NutrientPreference> _nutrientPrefs(Object? value) {
  if (value is! Map) return const {};
  final result = <Nutrient, NutrientPreference>{};
  value.forEach((key, raw) {
    final nutrient = _enumByName(Nutrient.values, key);
    final pref = _enumByName(NutrientPreference.values, raw);
    if (nutrient != null && pref != null) {
      result[nutrient] = pref;
    }
  });
  return result;
}

/// Pomocnik: zamienia nazwę na wartość enuma; nieznana nazwa → null.
T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

/// Ogólne potrzeby żywieniowe użytkownika. `label` to tekst w UI (po polsku).
enum DietaryNeed {
  healthy('Ogólnie zdrowo'),
  gym('Siłownia / budowa masy'),
  weightLoss('Odchudzanie'),
  specialDiet('Dieta specjalna'),
  budget('Oszczędzanie'),
  family('Dla dziecka / rodziny');

  const DietaryNeed(this.label);
  final String label;
}

/// Wartość odżywcza, dla której użytkownik określa preferencję.
enum Nutrient {
  calories('Kalorie'),
  sugar('Cukier'),
  fat('Tłuszcz'),
  salt('Sól'),
  protein('Białko');

  const Nutrient(this.label);
  final String label;
}

/// Preferencja użytkownika co do danej wartości odżywczej.
enum NutrientPreference {
  less('jak najmniej'),
  neutral('obojętnie'),
  more('jak najwięcej');

  const NutrientPreference(this.label);
  final String label;
}
