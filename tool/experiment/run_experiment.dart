// Skrypt eksperymentu: dla każdej pary produkt x profil pobiera dane z Open Food
// Facts, trzykrotnie odpytuje model językowy (przez ten sam kod, co aplikacja),
// wyznacza ocenę oczekiwaną funkcją odniesienia i zapisuje wyniki do wyniki.csv.
//
// Uruchomienie (z katalogu projektu, po ustawieniu klucza):
//   dart run tool/experiment/run_experiment.dart
// Klucz Groq czytany ze zmiennej srodowiskowej GROQ_API_KEY.

import 'dart:convert';
import 'dart:io';

import 'package:frapi/models/product.dart';
import 'package:frapi/models/product_analysis.dart';
import 'package:frapi/models/user_profile.dart';
import 'package:frapi/services/llm_client.dart';
import 'package:frapi/services/product_repository.dart';

import 'experiment_profiles.dart';
import 'reference.dart';

/// Kody kreskowe produktów tworzących próbkę badawczą (16 pozycji, dobrane pod
/// kątem różnorodności kategorii; mieszczą się w dziennym limicie tokenów).
const List<String> barcodes = [
  '5902057001748', // kefir
  '5900531000010', // serek wiejski
  '5900531004018', // twarog
  '5902409703887', // skyr naturalny
  '5900512300108', // maslo extra
  '40145990', // Monte
  '5000112651355', // Coca-Cola
  '5900334012685', // sok pomaranczowy
  '5908260254834', // OSHEE
  '5900259128898', // Lay's green onion
  '5053990101597', // Sour Cream & Onion
  '5900320001136', // salted cracker
  '5900259115393', // krakersy wielozbozowe (gluten)
  '5900567009681', // Berlinki
  '5908230524226', // parowki z szynki
  '5900617038289', // maslo orzechowe (orzechy)
];

const int runsPerPair = 1;
const Duration throttle = Duration(seconds: 6);

Future<void> main() async {
  final apiKey = Platform.environment['GROQ_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln('Ustaw zmienna srodowiskowa GROQ_API_KEY przed uruchomieniem.');
    exit(1);
  }

  final repository = ProductRepository();
  final llm = LlmClient(apiKey: apiKey, maxTokens: 300);

  // 1. Pobranie produktów z Open Food Facts (z pamięcią podręczną na dysku).
  final products = await _loadProducts(repository);
  stderr.writeln('Dostepnych ${products.length}/${barcodes.length} produktow.\n');
  if (products.isEmpty) {
    stderr.writeln('Brak produktow do oceny - przerwano.');
    exit(1);
  }

  // 2. Ocena par produkt x profil.
  // Wznawianie: zachowujemy tylko poprawne wyniki (pomijamy "nieznane", które
  // wynikły z wyczerpania limitu), resztę policzymy ponownie. Usuwa duplikaty.
  const header = 'kod;produkt;nutriscore;nova;profil;oczekiwana;'
      'llm1;llm2;llm3;wiekszosc;zgodnosc;zakazany_obecny';
  final resultsFile = File('wyniki.csv');
  final done = <String>{};
  if (resultsFile.existsSync()) {
    final kept = <String>[];
    for (final line in resultsFile.readAsLinesSync().skip(1)) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(';');
      if (parts.length < 10) continue;
      final key = '${parts[0]}|${parts[4]}';
      if (parts[9] != 'nieznane' && done.add(key)) kept.add(line);
    }
    final rewrite = resultsFile.openWrite();
    rewrite.writeln(header);
    for (final line in kept) {
      rewrite.writeln(line);
    }
    await rewrite.close();
    stderr.writeln('Wznawianie: zachowano ${done.length} poprawnych par; '
        'reszta zostanie policzona.');
  } else {
    resultsFile.writeAsStringSync('$header\n');
  }
  final csv = resultsFile.openWrite(mode: FileMode.append);

  var total = 0;
  var agreed = 0;
  for (final entry in experimentProfiles.entries) {
    final profileName = entry.key;
    final profile = entry.value;
    for (final product in products) {
      if (done.contains('${product.code}|$profileName')) continue;
      final expected = expectedRecommendation(product, profile);
      final forbidden = hasForbidden(product, profile);

      final runs = <Recommendation>[];
      for (var i = 0; i < runsPerPair; i++) {
        runs.add(await _analyzeWithRetry(llm, product, profile));
        await Future<void>.delayed(throttle);
      }

      final majority = _majority(runs);
      final agree = majority == expected;
      total++;
      if (agree) agreed++;

      csv.writeln([
        product.code,
        _csv(product.displayName),
        product.nutriScore?.toUpperCase() ?? '',
        product.novaGroup?.toString() ?? '',
        profileName,
        expected.key,
        runs[0].key,
        runs.length > 1 ? runs[1].key : '',
        runs.length > 2 ? runs[2].key : '',
        majority.key,
        agree ? '1' : '0',
        forbidden ? '1' : '0',
      ].join(';'));
      await csv.flush();

      stderr.writeln('$profileName | ${product.displayName} '
          '-> oczek=${expected.key} llm=${majority.key} '
          '${agree ? 'OK' : 'X'}');
    }
  }

  await csv.close();
  final acc = total == 0 ? 0 : (100 * agreed / total);
  stderr.writeln('\nZapisano wyniki.csv');
  stderr.writeln('Par: $total, zgodnych: $agreed, '
      'trafnosc: ${acc.toStringAsFixed(1)}%');
}

/// Analiza z jedną ponowną próbą (np. przy chwilowym błędzie/limicie 429).
Future<Recommendation> _analyzeWithRetry(
  LlmClient llm,
  Product product,
  UserProfile profile,
) async {
  const backoff = [Duration(seconds: 8), Duration(seconds: 20)];
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      final analysis = await llm.analyze(product, profile);
      return analysis.recommendation;
    } catch (e) {
      if (attempt < backoff.length) {
        stderr.writeln('  [ponawiam po bledzie] ${product.code}: $e');
        await Future<void>.delayed(backoff[attempt]);
      } else {
        stderr.writeln('  [blad LLM] ${product.code}: $e');
      }
    }
  }
  return Recommendation.unknown;
}

/// Ocena większościowa z listy uruchomień (przy remisie: pierwsza wartość).
Recommendation _majority(List<Recommendation> runs) {
  final counts = <Recommendation, int>{};
  for (final r in runs) {
    counts[r] = (counts[r] ?? 0) + 1;
  }
  var best = runs.first;
  var bestCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > bestCount) {
      best = entry.key;
      bestCount = entry.value;
    }
  }
  return best;
}

/// Usuwa znaki kolidujące z formatem CSV (średnik, nowe linie).
String _csv(String s) =>
    s.replaceAll(';', ',').replaceAll('\n', ' ').replaceAll('\r', ' ');

/// Wczytuje produkty: najpierw z pamięci podręcznej (products_cache.json),
/// brakujące dociąga z Open Food Facts (wolno, z ponawianiem przy 429) i
/// zapisuje do cache po każdym pobraniu. Ponowne uruchomienie nie odpytuje OFF
/// o produkty już zapisane.
Future<List<Product>> _loadProducts(ProductRepository repository) async {
  final cacheFile = File('products_cache.json');
  final cache = <String, Product>{};
  if (cacheFile.existsSync()) {
    final list = jsonDecode(cacheFile.readAsStringSync()) as List<dynamic>;
    for (final item in list) {
      final product = Product.fromJson(Map<String, dynamic>.from(item as Map));
      cache[product.code] = product;
    }
    stderr.writeln('Wczytano ${cache.length} produktow z products_cache.json');
  }

  final missing = barcodes.where((c) => !cache.containsKey(c)).toList();
  if (missing.isNotEmpty) {
    stderr.writeln('Pobieranie ${missing.length} brakujacych produktow z OFF '
        '(wolno, aby uniknac limitu)...');
  }
  for (final code in missing) {
    final product = await _fetchWithRetry(repository, code);
    if (product != null) {
      cache[code] = product;
      _saveCache(cacheFile, cache);
      stderr.writeln('  [ok] $code ${product.displayName}');
    } else {
      stderr.writeln('  [pominieto] $code');
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  return barcodes.where(cache.containsKey).map((c) => cache[c]!).toList();
}

/// Pobranie pojedynczego produktu z ponawianiem przy błędzie (np. 429).
Future<Product?> _fetchWithRetry(
  ProductRepository repository,
  String code,
) async {
  const backoff = [
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];
  for (var attempt = 0; attempt <= backoff.length; attempt++) {
    try {
      return await repository.fetchByBarcode(code);
    } catch (e) {
      if (attempt < backoff.length) {
        stderr.writeln('  [ponawiam $code za ${backoff[attempt].inSeconds}s] $e');
        await Future<void>.delayed(backoff[attempt]);
      } else {
        stderr.writeln('  [blad pobierania] $code: $e');
      }
    }
  }
  return null;
}

/// Zapisuje pamięć podręczną produktów do pliku JSON.
void _saveCache(File file, Map<String, Product> cache) {
  final list = cache.values.map((p) => p.toJson()).toList();
  file.writeAsStringSync(jsonEncode(list));
}
