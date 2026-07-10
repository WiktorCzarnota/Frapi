// Testy repozytorium produktu z podstawionym klientem HTTP (MockClient).
// Dzięki temu testujemy logikę bez połączenia z prawdziwym API.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frapi/services/product_repository.dart';

void main() {
  test('fetchByBarcode: status 1 → zwraca produkt', () async {
    final client = MockClient((request) async {
      return http.Response(
        '{"status":1,"product":{"code":"123","product_name":"Test"}}',
        200,
      );
    });
    final repo = ProductRepository(client: client);

    final product = await repo.fetchByBarcode('123');

    expect(product, isNotNull);
    expect(product!.displayName, 'Test');
  });

  test('fetchByBarcode: status 0 → zwraca null (brak produktu)', () async {
    final client = MockClient((request) async {
      return http.Response('{"status":0}', 200);
    });
    final repo = ProductRepository(client: client);

    expect(await repo.fetchByBarcode('000'), isNull);
  });

  test('fetchByBarcode: błąd serwera → ProductException', () async {
    final client = MockClient((request) async => http.Response('error', 500));
    final repo = ProductRepository(client: client);

    expect(
      () => repo.fetchByBarcode('123'),
      throwsA(isA<ProductException>()),
    );
  });

  test('fetchByBarcode: pusty kod → ProductException', () async {
    final repo = ProductRepository(client: MockClient((_) async {
      return http.Response('{}', 200);
    }));

    expect(
      () => repo.fetchByBarcode('   '),
      throwsA(isA<ProductException>()),
    );
  });

  test('searchByName: zwraca produkty z nazwą, pomija puste', () async {
    final client = MockClient((request) async {
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'products': [
            {'code': '1', 'product_name': 'Jogurt naturalny'},
            {'code': '2'}, // bez nazwy — pomijany
          ],
        })),
        200,
      );
    });
    final repo = ProductRepository(client: client);

    final results = await repo.searchByName('jogurt');

    expect(results, hasLength(1));
    expect(results.single.displayName, 'Jogurt naturalny');
  });

  test('searchByName: pusta fraza → pusta lista', () async {
    final repo = ProductRepository(client: MockClient((_) async {
      return http.Response('{}', 200);
    }));

    expect(await repo.searchByName('  '), isEmpty);
  });
}
