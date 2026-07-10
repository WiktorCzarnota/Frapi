import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/product_analysis.dart';
import '../models/user_profile.dart';
import 'analysis_prompt.dart';

/// Błąd analizy LLM z czytelnym komunikatem dla UI.
class LlmException implements Exception {
  const LlmException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Klient analizy produktu przez model językowy (Groq, API zgodne z OpenAI).
///
/// Wymusza odpowiedź JSON, klucz podawany z zewnątrz (`--dart-define`). Warstwa
/// niezależna od dostawcy - zmiana modelu sprowadza się do podmiany tej klasy.
class LlmClient {
  LlmClient({
    required this.apiKey,
    http.Client? client,
    this.model = 'llama-3.3-70b-versatile',
    this.visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct',
    this.maxTokens = 1024,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;

  /// Maksymalna długość odpowiedzi modelu (analiza/zamienniki). Niższa wartość
  /// zmniejsza zużycie tokenów - istotne przy limitach darmowego planu.
  final int maxTokens;

  /// Model multimodalny (z wizją) do odczytu danych ze zdjęcia etykiety.
  final String visionModel;
  final http.Client _client;

  static final Uri _endpoint =
      Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  static const String _analysisContract =
      'Odpowiedz wyłącznie w formacie JSON o strukturze: '
      '{"summary": "tekst", "recommendation": "tak" | "z umiarem" | "nie", '
      '"recommendationReason": "tekst"}. Nie dodawaj nic poza tym obiektem JSON.';

  static const String _alternativesContract =
      'Odpowiedz wyłącznie w formacie JSON o strukturze: '
      '{"alternatives": [{"name": "tekst", "reason": "tekst"}]}. '
      'Pole "alternatives" ma 2-3 elementy. Nie dodawaj nic poza tym obiektem JSON.';

  static const String _comparisonContract =
      'Odpowiedz wyłącznie w formacie JSON o strukturze: '
      '{"best": "nazwa produktu", "summary": "krótki opis"}. '
      'Nie dodawaj nic poza tym obiektem JSON.';

  /// Analizuje produkt względem profilu (wyjaśnienie + ocena).
  Future<ProductAnalysis> analyze(Product product, UserProfile profile) async {
    final json = await _complete(
      '${AnalysisPrompt.system}\n\n$_analysisContract',
      product,
      profile,
    );
    return ProductAnalysis.fromJson(json);
  }

  /// Proponuje zdrowsze zamienniki (osobna funkcja).
  Future<List<Alternative>> suggestAlternatives(
    Product product,
    UserProfile profile,
  ) async {
    final json = await _complete(
      '${AnalysisPrompt.alternativesSystem}\n\n$_alternativesContract',
      product,
      profile,
    );
    return (json['alternatives'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Alternative.fromJson)
        .toList();
  }

  /// Krótkie porównanie zestawu produktów (który najlepszy / czym się wyróżnia).
  Future<ProductComparison> compareProducts(
    List<Product> products,
    UserProfile profile,
  ) async {
    final body = jsonEncode({
      'model': model,
      'max_tokens': 512,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              '${AnalysisPrompt.comparisonSystem}\n\n$_comparisonContract',
        },
        {
          'role': 'user',
          'content': AnalysisPrompt.comparisonMessage(products, profile),
        },
      ],
    });
    return ProductComparison.fromJson(_extractJson(await _post(body)));
  }

  /// Odczytuje dane produktu ze zdjęcia etykiety (model z wizją), gdy produktu
  /// brak w Open Food Facts. Zwraca [Product] zgodny z formatem OFF.
  Future<Product> extractProductFromLabel(
    List<int> imageBytes, {
    String? code,
    String mimeType = 'image/jpeg',
  }) async {
    final dataUrl = 'data:$mimeType;base64,${base64Encode(imageBytes)}';
    final body = jsonEncode({
      'model': visionModel,
      'max_tokens': 1024,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': AnalysisPrompt.labelExtractionSystem},
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Odczytaj dane z tej etykiety i zwróć wyłącznie JSON.',
            },
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl},
            },
          ],
        },
      ],
    });

    final json = _extractJson(await _post(body));
    final resolvedCode =
        code ?? 'label-${DateTime.now().millisecondsSinceEpoch}';
    return Product.fromJson({...json, 'code': resolvedCode});
  }

  /// Wspólne wywołanie modelu tekstowego: zwraca sparsowany obiekt JSON.
  Future<Map<String, dynamic>> _complete(
    String systemContent,
    Product product,
    UserProfile profile,
  ) async {
    final body = jsonEncode({
      'model': model,
      'max_tokens': maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': systemContent},
        {'role': 'user', 'content': AnalysisPrompt.userMessage(product, profile)},
      ],
    });

    return _extractJson(await _post(body));
  }

  /// Wysyła gotowe ciało żądania do API i zwraca odpowiedź (z obsługą błędów).
  Future<http.Response> _post(String body) async {
    if (apiKey.isEmpty) {
      throw const LlmException(
        'Brak klucza API. Uruchom aplikację z parametrem '
        '--dart-define=GROQ_API_KEY=twoj_klucz.',
      );
    }

    final http.Response response;
    try {
      response = await _client.post(
        _endpoint,
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $apiKey',
        },
        // Jawne UTF-8 (polskie znaki w promptcie).
        body: utf8.encode(body),
      );
    } catch (_) {
      throw const LlmException('Brak połączenia z serwerem LLM.');
    }

    if (response.statusCode != 200) {
      throw LlmException(_serverError(response));
    }

    return response;
  }

  /// Buduje czytelny komunikat błędu, dołączając opis od serwera.
  String _serverError(http.Response response) {
    var detail = '';
    try {
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final error = body['error'];
      if (error is Map && error['message'] is String) {
        detail = ' ${error['message']}';
      }
    } catch (_) {
      // brak czytelnego ciała błędu — zostaje sam kod
    }
    final code = response.statusCode;
    if (code == 401 || code == 403) {
      return 'Nieprawidłowy klucz API lub brak uprawnień.$detail';
    }
    if (code == 429) {
      return 'Przekroczono limit darmowego planu (429).$detail';
    }
    return 'Serwer LLM zwrócił błąd ($code).$detail';
  }

  /// Wyciąga obiekt JSON z odpowiedzi (format OpenAI/Groq).
  Map<String, dynamic> _extractJson(http.Response response) {
    try {
      // Jawne UTF-8 (polskie znaki w odpowiedzi modelu).
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>;
      final message = (choices.first as Map<String, dynamic>)['message']
          as Map<String, dynamic>;
      final content = message['content'] as String;
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw const LlmException('Nie udało się odczytać odpowiedzi modelu.');
    }
  }
}
