import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../services/llm_client.dart';

/// Ekran dodania produktu spoza Open Food Facts na podstawie zdjęcia etykiety.
///
/// Rozszerza rolę LLM z interpretacji danych na ich EKSTRAKCJĘ: model z wizją
/// odczytuje tabelę wartości odżywczych i skład ze zdjęcia i zwraca je w tej
/// samej strukturze co Open Food Facts. Po udanym odczycie ekran zwraca gotowy
/// [Product] (przez `Navigator.pop`), a wołający otwiera go zwykłym przepływem
/// (analiza + zapis do historii).
class AddFromLabelScreen extends StatefulWidget {
  const AddFromLabelScreen({super.key, this.client, this.picker});

  /// Klient LLM (wstrzykiwany w testach). Domyślnie budowany z klucza z env.
  final LlmClient? client;

  /// Wybór zdjęcia (wstrzykiwany w testach).
  final ImagePicker? picker;

  @override
  State<AddFromLabelScreen> createState() => _AddFromLabelScreenState();
}

class _AddFromLabelScreenState extends State<AddFromLabelScreen> {
  // Klucz API podawany przy starcie: --dart-define=GROQ_API_KEY=...
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');

  late final LlmClient _client =
      widget.client ?? LlmClient(apiKey: _apiKey);
  late final ImagePicker _picker = widget.picker ?? ImagePicker();

  Uint8List? _preview;
  bool _loading = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 70,
      );
      if (file == null) {
        if (mounted) setState(() => _loading = false);
        return; // użytkownik anulował
      }

      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _preview = bytes);

      final product = await _client.extractProductFromLabel(
        bytes,
        mimeType: _mimeType(file.name),
      );

      if (!_hasUsefulData(product)) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Nie udało się odczytać danych z etykiety. Spróbuj '
                'wyraźniejsze, dobrze oświetlone zdjęcie tabeli wartości '
                'odżywczych lub składu.';
          });
        }
        return;
      }

      if (mounted) Navigator.of(context).pop(product);
    } on LlmException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Nie udało się przetworzyć zdjęcia.';
        });
      }
    }
  }

  /// Czy odczyt zwrócił cokolwiek użytecznego (nazwa, skład lub jakakolwiek
  /// wartość odżywcza) — inaczej traktujemy zdjęcie jako nieczytelne.
  bool _hasUsefulData(Product p) {
    final n = p.nutriments;
    final anyNutriment = [
      n.energyKcal,
      n.sugars,
      n.fat,
      n.saturatedFat,
      n.salt,
      n.proteins,
      n.carbohydrates,
    ].any((v) => v != null);
    return p.name != null || p.ingredientsText != null || anyNutriment;
  }

  String _mimeType(String name) =>
      name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj ze zdjęcia etykiety')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Zrób zdjęcie tabeli wartości odżywczych lub listy składników. '
            'Aplikacja odczyta z niego dane, gdy produktu nie ma w bazie '
            'Open Food Facts.',
          ),
          const SizedBox(height: 20),
          if (_preview != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(_preview!, height: 200, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
          ],
          FilledButton.icon(
            onPressed: _loading ? null : () => _pick(ImageSource.camera),
            icon: const Icon(Icons.photo_camera),
            label: const Text('Zrób zdjęcie (aparat)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Wybierz zdjęcie z galerii / pliku'),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Column(
              children: [
                Center(child: CircularProgressIndicator()),
                SizedBox(height: 12),
                Text('Odczytuję etykietę…', textAlign: TextAlign.center),
              ],
            ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}
