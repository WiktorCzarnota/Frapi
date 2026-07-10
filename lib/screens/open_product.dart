import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/history_repository.dart';
import 'product_result_screen.dart';

/// Zapisuje produkt do historii i otwiera ekran wyniku.
///
/// Wspólny punkt wejścia używany przez skaner, wyszukiwarkę zamienników
/// i listę — dzięki temu każdy obejrzany produkt trafia do historii.
Future<void> openProduct(
  BuildContext context,
  Product product, {
  HistoryRepository history = const HistoryRepository(),
}) async {
  await history.add(product);
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ProductResultScreen(product: product)),
  );
}
