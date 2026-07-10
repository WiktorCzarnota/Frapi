import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_repository.dart';
import 'add_from_label_screen.dart';
import 'barcode_scanner_screen.dart';
import 'open_product.dart';
import 'search_results_screen.dart';

/// Ekran „znajdź produkt": skan kodu kamerą, wyszukiwanie po nazwie, wpisanie
/// kodu ręcznie oraz dodanie produktu spoza bazy ze zdjęcia etykiety.
///
/// Wszystkie ścieżki prowadzą do tego samego dalszego przepływu
/// (produkt → analiza → historia).
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.repository});

  final ProductRepository? repository;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final ProductRepository _repository =
      widget.repository ?? ProductRepository();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final product = await _repository.fetchByBarcode(code);
      if (!mounted) return;
      if (product == null) {
        setState(() => _error = 'Nie znaleziono produktu o kodzie $code.');
        return;
      }
      await openProduct(context, product);
    } on ProductException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Wyszukiwanie produktów po nazwie (Open Food Facts) — otwiera listę wyników.
  Future<void> _searchByName() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SearchResultsScreen(query: query)),
    );
  }

  /// Skan kodu kreskowego kamerą — wypełnia pole i pobiera produkt.
  Future<void> _scanCamera() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code != null && mounted) {
      _controller.text = code;
      await _search();
    }
  }

  /// Dodanie produktu spoza bazy przez zdjęcie etykiety (LLM z wizją).
  Future<void> _addFromLabel() async {
    final product = await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => const AddFromLabelScreen()),
    );
    if (product != null && mounted) {
      await openProduct(context, product);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skaner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _loading ? null : _scanCamera,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Skanuj kod aparatem'),
            ),
            const SizedBox(height: 24),
            const Text('lub wyszukaj produkt po nazwie:'),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Nazwa produktu',
                hintText: 'np. jogurt naturalny',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _searchByName(),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _loading ? null : _searchByName,
              icon: const Icon(Icons.search),
              label: const Text('Szukaj po nazwie'),
            ),
            const Divider(height: 40),
            const Text('lub wpisz kod kreskowy ręcznie:'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kod kreskowy',
                hintText: 'np. 3017620422003',
                prefixIcon: Icon(Icons.qr_code),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.qr_code),
              label: const Text('Pobierz po kodzie'),
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const Divider(height: 40),
            const Text('Nie ma produktu w bazie lub dane są niepełne?'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _addFromLabel,
              icon: const Icon(Icons.document_scanner),
              label: const Text('Dodaj ze zdjęcia etykiety'),
            ),
          ],
        ),
      ),
    );
  }
}
