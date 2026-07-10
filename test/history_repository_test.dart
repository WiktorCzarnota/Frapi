// Testy historii skanów (zapis lokalny przez shared_preferences).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frapi/models/product.dart';
import 'package:frapi/services/history_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const repo = HistoryRepository();

  Product product(String code, String name) =>
      Product.fromJson({'code': code, 'product_name': name});

  test('add + load: najnowszy produkt jest pierwszy', () async {
    await repo.add(product('1', 'Pierwszy'));
    await repo.add(product('2', 'Drugi'));

    final history = await repo.load();

    expect(history.map((p) => p.code), ['2', '1']);
  });

  test('add: ponowne dodanie tego samego kodu przenosi na początek, bez duplikatu',
      () async {
    await repo.add(product('1', 'A'));
    await repo.add(product('2', 'B'));
    await repo.add(product('1', 'A'));

    final history = await repo.load();

    expect(history.map((p) => p.code), ['1', '2']);
    expect(history, hasLength(2));
  });
}
