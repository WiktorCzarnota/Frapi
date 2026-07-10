import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_repository.dart';
import '../widgets/product_tile.dart';
import 'open_product.dart';

/// Ekran wyników wyszukiwania produktów po nazwie (np. zaproponowany zamiennik).
///
/// Po dotknięciu wyniku otwieramy pełny ekran produktu (z analizą i danymi).
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.query,
    this.repository,
    this.titlePrefix = 'Wyniki',
  });

  final String query;
  final ProductRepository? repository;

  /// Prefiks tytułu ekranu (np. „Wyniki" dla wyszukiwarki, „Zamiennik" dla
  /// sprawdzania zaproponowanego zamiennika).
  final String titlePrefix;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final ProductRepository _repository =
      widget.repository ?? ProductRepository();

  bool _loading = true;
  String? _error;
  List<Product> _results = const [];

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    try {
      final results = await _repository.searchByName(widget.query);
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } on ProductException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.titlePrefix}: ${widget.query}')),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }
          if (_results.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Brak pasujących produktów w bazie.'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final product in _results)
                ProductTile(
                  product: product,
                  onTap: () => openProduct(context, product),
                ),
            ],
          );
        },
      ),
    );
  }
}
