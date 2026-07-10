import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/history_repository.dart';
import '../widgets/product_tile.dart';
import 'compare_screen.dart';

/// Zakładka „Porównaj" — wybór 2-6 produktów z historii i ich porównanie.
///
/// Produkty zaznacza się kliknięciem w kafelek. Przycisk „Porównaj" jest na
/// stałe na dole ekranu (aktywny od 2 zaznaczonych). Zaznaczone produkty
/// pokazujemy w tabeli ([CompareScreen]) z graficznym wyróżnieniem, sortowaniem
/// i krótkim podsumowaniem AI.
class CompareTab extends StatefulWidget {
  const CompareTab({super.key, this.history = const HistoryRepository()});

  final HistoryRepository history;

  @override
  CompareTabState createState() => CompareTabState();
}

class CompareTabState extends State<CompareTab> {
  static const int _maxCompare = 6;

  List<Product> _products = const [];
  final Set<String> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  /// Wczytuje historię ponownie (wołane też przy wejściu na zakładkę).
  Future<void> reload() async {
    final products = await widget.history.load();
    if (!mounted) return;
    setState(() {
      _products = products;
      _selected.removeWhere((code) => !products.any((p) => p.code == code));
      _loading = false;
    });
  }

  void _toggle(String code) {
    setState(() {
      if (_selected.contains(code)) {
        _selected.remove(code);
      } else if (_selected.length < _maxCompare) {
        _selected.add(code);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Możesz porównać najwyżej $_maxCompare produkty.'),
          ),
        );
      }
    });
  }

  void _compare() {
    final chosen = _products.where((p) => _selected.contains(p.code)).toList();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CompareScreen(products: chosen)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enoughProducts = _products.length >= 2;
    final canCompare = _selected.length >= 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Porównaj produkty')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !enoughProducts
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Za mało produktów do porównania. Zeskanuj przynajmniej '
                      'dwa produkty w zakładce Skaner.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        'Stuknij produkty, które chcesz porównać (2-$_maxCompare).',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    for (final product in _products)
                      ProductTile(
                        product: product,
                        selected: _selected.contains(product.code),
                        onTap: () => _toggle(product.code),
                      ),
                  ],
                ),
      bottomNavigationBar: !enoughProducts
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: canCompare ? _compare : null,
                  icon: const Icon(Icons.compare_arrows),
                  label: Text(
                    canCompare
                        ? 'Porównaj (${_selected.length})'
                        : 'Zaznacz min. 2 produkty',
                  ),
                ),
              ),
            ),
    );
  }
}
