/// Wynik analizy produktu przez LLM (funkcje 1-2 MVP).
///
/// - [summary]               — interpretacja produktu prostym językiem (funkcja 1),
/// - [recommendation]        — ocena dopasowania do profilu użytkownika (funkcja 2),
/// - [recommendationReason]  — uzasadnienie tej oceny.
///
/// Zdrowsze zamienniki (funkcja 3) są osobną operacją — patrz [Alternative].
class ProductAnalysis {
  const ProductAnalysis({
    required this.summary,
    required this.recommendation,
    required this.recommendationReason,
  });

  final String summary;
  final Recommendation recommendation;
  final String recommendationReason;

  factory ProductAnalysis.fromJson(Map<String, dynamic> json) {
    return ProductAnalysis(
      summary: (json['summary'] ?? '').toString(),
      recommendation: Recommendation.fromKey(json['recommendation']),
      recommendationReason: (json['recommendationReason'] ?? '').toString(),
    );
  }
}

/// Zdrowszy zamiennik proponowany przez LLM (funkcja 3, osobna operacja).
class Alternative {
  const Alternative({required this.name, required this.reason});

  final String name;
  final String reason;

  factory Alternative.fromJson(Map<String, dynamic> json) {
    return Alternative(
      name: (json['name'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
    );
  }
}

/// Krótkie porównanie zestawu produktów przez LLM: który jest najlepszy
/// dla użytkownika i czym się wyróżnia.
class ProductComparison {
  const ProductComparison({required this.best, required this.summary});

  /// Nazwa produktu wskazanego jako najlepszy (może być pusta).
  final String best;

  /// Zwięzły opis porównania (1-2 zdania).
  final String summary;

  factory ProductComparison.fromJson(Map<String, dynamic> json) {
    return ProductComparison(
      best: (json['best'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
    );
  }
}

/// Ocena dopasowania produktu do profilu: tak / z umiarem / nie.
enum Recommendation {
  yes('tak', 'Dobry wybór', 0xFF2E7D32),
  moderate('z umiarem', 'Z umiarem', 0xFFEF6C00),
  no('nie', 'Lepiej unikać', 0xFFD32F2F),
  unknown('nieznane', 'Brak oceny', 0xFF616161);

  const Recommendation(this.key, this.label, this.colorValue);

  /// Wartość zwracana przez LLM w polu JSON.
  final String key;

  /// Etykieta widoczna w UI.
  final String label;

  /// Kolor akcentu (ARGB).
  final int colorValue;

  /// Mapuje klucz z odpowiedzi LLM na wartość enuma.
  factory Recommendation.fromKey(Object? key) {
    for (final value in values) {
      if (value.key == key) return value;
    }
    return Recommendation.unknown;
  }
}
