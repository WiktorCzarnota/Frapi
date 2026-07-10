import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/history_repository.dart';
import '../widgets/product_tile.dart';
import 'open_product.dart';

/// Zakładka „Lista" — ostatnio skanowane produkty jako kafelki.
///
/// Dotknięcie kafelka otwiera pełny ekran produktu. Porównywanie produktów
/// jest w osobnej zakładce „Porównaj".
class ListScreen extends StatefulWidget {
  const ListScreen({super.key, this.history = const HistoryRepository()});

  final HistoryRepository history;

  @override
  ListScreenState createState() => ListScreenState();
}

class ListScreenState extends State<ListScreen> {
  List<Product> _products = const [];
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
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ostatnio skanowane')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Brak skanów. Zeskanuj lub wpisz kod produktu '
                      'w zakładce Skaner.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final product in _products)
                      ProductTile(
                        product: product,
                        onTap: () async {
                          await openProduct(context, product);
                          await reload();
                        },
                      ),
                  ],
                ),
    );
  }
}
