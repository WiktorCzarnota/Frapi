import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

/// Błąd pobierania produktu z czytelnym komunikatem dla UI.
class ProductException implements Exception {
  const ProductException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Pobiera dane produktu z Open Food Facts po kodzie kreskowym.
///
/// Używa publicznego API v2 (REST/JSON, darmowe). Prosimy tylko o potrzebne
/// pola (parametr `fields`), aby ograniczyć rozmiar odpowiedzi.
class ProductRepository {
  ProductRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _host = 'world.openfoodfacts.org';

  /// Pola, o które prosimy API (mniejsza odpowiedź, mniej parsowania).
  static const String _fields =
      'code,product_name,brands,quantity,ingredients_text,'
      'nutriscore_grade,nova_group,nutriments,allergens_tags,'
      'categories,image_front_small_url';

  /// Open Food Facts prosi o identyfikację aplikacji w nagłówku User-Agent.
  static const Map<String, String> _headers = {
    'User-Agent': 'frapi-thesis/0.1 (kontakt: weqtor66@gmail.com)',
  };

  /// Pobiera produkt o podanym [barcode].
  ///
  /// Zwraca `null`, gdy produktu nie ma w bazie. Rzuca [ProductException]
  /// przy błędzie sieci lub nieprawidłowej odpowiedzi.
  Future<Product?> fetchByBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) {
      throw const ProductException('Pusty kod kreskowy.');
    }

    final uri = Uri.https(_host, '/api/v2/product/$code.json', {
      'fields': _fields,
    });

    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers);
    } catch (_) {
      throw const ProductException(
        'Brak połączenia z internetem lub serwer nie odpowiada.',
      );
    }

    if (response.statusCode != 200) {
      throw ProductException('Serwer zwrócił błąd (${response.statusCode}).');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const ProductException('Nieprawidłowa odpowiedź serwera.');
    }

    // status: 1 = znaleziono, 0 = brak produktu w bazie.
    if (body['status'] != 1 || body['product'] is! Map<String, dynamic>) {
      return null;
    }

    return Product.fromJson(body['product'] as Map<String, dynamic>);
  }

  /// Wyszukuje produkty po nazwie/frazie (np. zaproponowany zamiennik).
  ///
  /// Zwraca produkty z bazy Open Food Facts pasujące do [query]. Pomija pozycje
  /// bez nazwy. Rzuca [ProductException] przy błędzie sieci/odpowiedzi.
  Future<List<Product>> searchByName(String query, {int limit = 12}) async {
    final term = query.trim();
    if (term.isEmpty) return const [];

    final uri = Uri.https(_host, '/cgi/search.pl', {
      'search_terms': term,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '$limit',
      'fields': _fields,
    });

    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers);
    } catch (_) {
      throw const ProductException(
        'Brak połączenia z internetem lub serwer nie odpowiada.',
      );
    }

    if (response.statusCode != 200) {
      throw ProductException('Serwer zwrócił błąd (${response.statusCode}).');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const ProductException('Nieprawidłowa odpowiedź serwera.');
    }

    final products = body['products'];
    if (products is! List) return const [];

    return products
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .where((p) => p.name != null)
        .toList();
  }
}
