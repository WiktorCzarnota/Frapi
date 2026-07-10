// Testy klienta LLM (Groq) z podstawionym HTTP — analiza i zamienniki osobno.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frapi/models/product.dart';
import 'package:frapi/models/product_analysis.dart';
import 'package:frapi/models/user_profile.dart';
import 'package:frapi/services/llm_client.dart';

const _product = Product(code: '123', name: 'Test', ingredientsText: 'cukier');
const _profile = UserProfile(forbidden: ['orzechy']);

/// Buduje odpowiedź (bajty UTF-8) w formacie OpenAI/Groq z JSON treści.
List<int> _apiResponse(Map<String, dynamic> content) {
  return utf8.encode(jsonEncode({
    'choices': [
      {
        'message': {'role': 'assistant', 'content': jsonEncode(content)},
      },
    ],
  }));
}

MockClient _ok(Map<String, dynamic> content) {
  return MockClient((_) async => http.Response.bytes(_apiResponse(content), 200));
}

void main() {
  test('analyze: parsuje wyjaśnienie i ocenę (bez zamienników)', () async {
    final llm = LlmClient(
      apiKey: 'gsk-test',
      client: _ok({
        'summary': 'Słodki produkt.',
        'recommendation': 'z umiarem',
        'recommendationReason': 'Dużo cukru.',
      }),
    );

    final result = await llm.analyze(_product, _profile);

    expect(result.summary, 'Słodki produkt.');
    expect(result.recommendation, Recommendation.moderate);
    expect(result.recommendationReason, 'Dużo cukru.');
  });

  test('suggestAlternatives: parsuje listę zamienników', () async {
    final llm = LlmClient(
      apiKey: 'gsk-test',
      client: _ok({
        'alternatives': [
          {'name': 'Jogurt naturalny', 'reason': 'Mniej cukru.'},
          {'name': 'Serek twarogowy', 'reason': 'Więcej białka.'},
        ],
      }),
    );

    final result = await llm.suggestAlternatives(_product, _profile);

    expect(result, hasLength(2));
    expect(result.first.name, 'Jogurt naturalny');
  });

  test('analyze: pusty klucz → LlmException', () {
    final llm = LlmClient(apiKey: '', client: _ok({}));
    expect(() => llm.analyze(_product, _profile),
        throwsA(isA<LlmException>()));
  });

  test('analyze: 401 (zły klucz) → LlmException', () {
    final client = MockClient((_) async => http.Response('unauthorized', 401));
    final llm = LlmClient(apiKey: 'zly', client: client);

    expect(() => llm.analyze(_product, _profile),
        throwsA(isA<LlmException>()));
  });

  test('compareProducts: parsuje najlepszy produkt i opis', () async {
    final llm = LlmClient(
      apiKey: 'gsk-test',
      client: _ok({
        'best': 'Jogurt naturalny',
        'summary': 'Najmniej cukru i najwięcej białka.',
      }),
    );

    final result = await llm.compareProducts(
      const [Product(code: '1', name: 'A'), Product(code: '2', name: 'B')],
      _profile,
    );

    expect(result.best, 'Jogurt naturalny');
    expect(result.summary, 'Najmniej cukru i najwięcej białka.');
  });

  test('extractProductFromLabel: buduje produkt z odczytanych danych', () async {
    final llm = LlmClient(
      apiKey: 'gsk-test',
      client: _ok({
        'product_name': 'Batonik testowy',
        'ingredients_text': 'cukier, kakao',
        'nutriments': {
          'energy-kcal_100g': 500,
          'sugars_100g': 40,
          'proteins_100g': 5,
        },
      }),
    );

    final product =
        await llm.extractProductFromLabel(const [1, 2, 3], code: 'label-1');

    expect(product.code, 'label-1');
    expect(product.displayName, 'Batonik testowy');
    expect(product.ingredientsText, 'cukier, kakao');
    expect(product.nutriments.energyKcal, 500);
    expect(product.nutriments.sugars, 40);
  });

  test('extractProductFromLabel: żądanie używa modelu z wizją i zawiera obraz',
      () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response.bytes(_apiResponse({'product_name': 'X'}), 200);
    });
    final llm = LlmClient(apiKey: 'gsk-test', client: client);

    await llm.extractProductFromLabel(const [1, 2, 3]);

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['model'], 'meta-llama/llama-4-scout-17b-16e-instruct');
    final content = (body['messages'] as List)[1]['content'] as List;
    expect(content.any((c) => c['type'] == 'image_url'), isTrue);
  });

  test('analyze: żądanie zawiera model, klucz i tryb JSON', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response.bytes(
        _apiResponse({
          'summary': 's',
          'recommendation': 'tak',
          'recommendationReason': 'r',
        }),
        200,
      );
    });
    final llm = LlmClient(apiKey: 'gsk-test', client: client);

    await llm.analyze(_product, _profile);

    expect(captured.headers['authorization'], 'Bearer gsk-test');
    expect(jsonDecode(captured.body)['model'], 'llama-3.3-70b-versatile');
    expect(jsonDecode(captured.body)['response_format']['type'], 'json_object');
  });
}
