import 'package:flutter/material.dart';

import '../models/product.dart';

/// Kafelek produktu: małe zdjęcie, nazwa, marka i skrót wartości odżywczych.
///
/// Gdy [selected] jest nie-null, kafelek działa w trybie wyboru: pokazuje
/// wskaźnik zaznaczenia i podświetla obramowanie, a zaznaczanie odbywa się
/// przez [onTap] (kliknięcie całego kafelka).
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    this.onTap,
    this.selected,
  });

  final Product product;
  final VoidCallback? onTap;

  /// Gdy nie-null, kafelek jest w trybie wyboru (do porównywania).
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selected == true;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: isSelected
          ? RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _thumbnail(theme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.displayName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.brands != null)
                      Text(
                        product.brands!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _nutritionSummary(),
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (selected != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(ThemeData theme) {
    const size = 56.0;
    if (product.imageUrl == null) {
      return Container(
        width: size,
        height: size,
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.fastfood, size: 28),
      );
    }
    return Image.network(
      product.imageUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.fastfood, size: 28),
      ),
    );
  }

  /// Skrót wartości odżywczych (na 100 g), pomija brakujące.
  String _nutritionSummary() {
    final n = product.nutriments;
    final parts = <String>[
      if (n.energyKcal != null) '${_fmt(n.energyKcal!)} kcal',
      if (n.sugars != null) 'cukry ${_fmt(n.sugars!)} g',
      if (n.fat != null) 'tłuszcz ${_fmt(n.fat!)} g',
      if (n.proteins != null) 'białko ${_fmt(n.proteins!)} g',
    ];
    return parts.isEmpty ? 'Brak danych odżywczych' : parts.join(' · ');
  }

  static String _fmt(double v) {
    final rounded = (v * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }
}
