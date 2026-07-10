/// Dane produktu spożywczego pobrane z Open Food Facts.
///
/// Zawiera tylko pola istotne dla aplikacji (nazwa, skład, oceny, wybrane
/// wartości odżywcze). Surowe dane API mają znacznie więcej pól — świadomie
/// bierzemy podzbiór potrzebny do analizy przez LLM i prezentacji użytkownikowi.
class Product {
  const Product({
    required this.code,
    this.name,
    this.brands,
    this.quantity,
    this.ingredientsText,
    this.nutriScore,
    this.novaGroup,
    this.allergens = const [],
    this.categories,
    this.imageUrl,
    this.nutriments = const Nutriments(),
  });

  /// Kod kreskowy (EAN).
  final String code;

  /// Nazwa produktu.
  final String? name;

  /// Marka / marki.
  final String? brands;

  /// Ilość/gramatura (np. „400 g").
  final String? quantity;

  /// Skład w formie tekstowej (wejście do analizy LLM).
  final String? ingredientsText;

  /// Nutri-Score: litera „a"–„e" (lub null, gdy brak danych).
  final String? nutriScore;

  /// Grupa NOVA (1–4) określająca stopień przetworzenia.
  final int? novaGroup;

  /// Alergeny (oczyszczone z prefiksu języka, np. „milk").
  final List<String> allergens;

  /// Kategorie produktu (tekst).
  final String? categories;

  /// URL miniatury zdjęcia produktu.
  final String? imageUrl;

  /// Wybrane wartości odżywcze (na 100 g).
  final Nutriments nutriments;

  /// Nazwa do wyświetlenia (z bezpiecznym fallbackiem na kod).
  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name!.trim() : 'Produkt $code';

  /// Serializacja do zapisu lokalnego (historia). Używa kluczy zgodnych
  /// z [Product.fromJson], więc dane wracają tą samą drogą.
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'product_name': name,
      'brands': brands,
      'quantity': quantity,
      'ingredients_text': ingredientsText,
      'nutriscore_grade': nutriScore,
      'nova_group': novaGroup,
      'allergens_tags': allergens,
      'categories': categories,
      'image_front_small_url': imageUrl,
      'nutriments': {
        'energy-kcal_100g': nutriments.energyKcal,
        'sugars_100g': nutriments.sugars,
        'fat_100g': nutriments.fat,
        'saturated-fat_100g': nutriments.saturatedFat,
        'salt_100g': nutriments.salt,
        'proteins_100g': nutriments.proteins,
        'carbohydrates_100g': nutriments.carbohydrates,
      },
    };
  }

  /// Buduje produkt z obiektu `product` zwracanego przez API Open Food Facts.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      code: (json['code'] ?? '').toString(),
      name: _trimmedOrNull(json['product_name']),
      brands: _trimmedOrNull(json['brands']),
      quantity: _trimmedOrNull(json['quantity']),
      ingredientsText: _trimmedOrNull(json['ingredients_text']),
      nutriScore: _trimmedOrNull(json['nutriscore_grade'])?.toLowerCase(),
      novaGroup: _toInt(json['nova_group']),
      allergens: _allergens(json['allergens_tags']),
      categories: _trimmedOrNull(json['categories']),
      imageUrl: _trimmedOrNull(json['image_front_small_url']),
      nutriments: Nutriments.fromJson(
        json['nutriments'] is Map<String, dynamic>
            ? json['nutriments'] as Map<String, dynamic>
            : const {},
      ),
    );
  }
}

/// Wybrane wartości odżywcze na 100 g produktu.
class Nutriments {
  const Nutriments({
    this.energyKcal,
    this.sugars,
    this.fat,
    this.saturatedFat,
    this.salt,
    this.proteins,
    this.carbohydrates,
  });

  final double? energyKcal;
  final double? sugars;
  final double? fat;
  final double? saturatedFat;
  final double? salt;
  final double? proteins;
  final double? carbohydrates;

  factory Nutriments.fromJson(Map<String, dynamic> json) {
    return Nutriments(
      energyKcal: _toDouble(json['energy-kcal_100g']),
      sugars: _toDouble(json['sugars_100g']),
      fat: _toDouble(json['fat_100g']),
      saturatedFat: _toDouble(json['saturated-fat_100g']),
      salt: _toDouble(json['salt_100g']),
      proteins: _toDouble(json['proteins_100g']),
      carbohydrates: _toDouble(json['carbohydrates_100g']),
    );
  }
}

// --- Pomocnicy parsowania (odporni na braki i nietypowe typy) ---

String? _trimmedOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Czyści listę tagów alergenów: „en:milk" → „milk", pomija puste.
List<String> _allergens(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .map((tag) => tag.contains(':') ? tag.split(':').last : tag)
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();
}
