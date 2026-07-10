import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

/// Przechowuje listę ostatnio oglądanych produktów (lokalnie, bez backendu).
///
/// Zapis w `shared_preferences` jako lista JSON. Najnowsze na początku,
/// bez duplikatów (po kodzie), maksymalnie [_maxItems] pozycji.
class HistoryRepository {
  const HistoryRepository();

  static const String _key = 'scan_history';
  static const int _maxItems = 20;

  /// Wczytuje historię (najnowsze pierwsze).
  Future<List<Product>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    final products = <Product>[];
    for (final entry in raw) {
      try {
        products.add(Product.fromJson(jsonDecode(entry) as Map<String, dynamic>));
      } catch (_) {
        // pomijamy uszkodzony wpis
      }
    }
    return products;
  }

  /// Dodaje produkt na początek historii (usuwa wcześniejszy wpis o tym kodzie).
  Future<void> add(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];

    raw.removeWhere((entry) {
      try {
        return (jsonDecode(entry) as Map<String, dynamic>)['code'] ==
            product.code;
      } catch (_) {
        return false;
      }
    });

    raw.insert(0, jsonEncode(product.toJson()));
    if (raw.length > _maxItems) raw.removeRange(_maxItems, raw.length);

    await prefs.setStringList(_key, raw);
  }
}
