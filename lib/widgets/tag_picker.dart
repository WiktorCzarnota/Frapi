import 'package:flutter/material.dart';

import '../services/ingredient_catalog.dart';

/// Pole wyboru tagów: wybrane pozycje + wpisywanie własnych z podpowiedziami.
///
/// Powtarzalny komponent używany dla kategorii profilu (zakazane, niechciane,
/// zalecane) oraz dla własnych potrzeb. Łączy trzy sposoby dodawania:
/// - kliknięcie szybkiej sugestii ([quickSuggestions]),
/// - kliknięcie podpowiedzi pojawiającej się podczas pisania (typeahead),
/// - zatwierdzenie własnego, dowolnego wpisu (Enter).
///
/// [accentColor] i [icon] pozwalają wizualnie odróżnić sekcje od siebie.
class TagPicker extends StatefulWidget {
  const TagPicker({
    super.key,
    required this.title,
    required this.tags,
    required this.onChanged,
    this.icon,
    this.accentColor,
    this.hintText = 'Wpisz własny…',
    this.quickSuggestions = const [],
    this.catalog = const IngredientCatalog(),
    this.enableCatalogSearch = true,
  });

  /// Nagłówek sekcji.
  final String title;

  /// Aktualnie wybrane tagi.
  final List<String> tags;

  /// Wywoływane po każdej zmianie listy tagów.
  final ValueChanged<List<String>> onChanged;

  /// Ikona przy nagłówku (wzmacnia rozróżnienie sekcji).
  final IconData? icon;

  /// Akcent kolorystyczny sekcji (nagłówek, ikona, tło chipów).
  final Color? accentColor;

  /// Podpowiedź w polu tekstowym.
  final String hintText;

  /// Domyślne propozycje pokazywane, gdy pole jest puste (specyficzne dla sekcji).
  final List<String> quickSuggestions;

  /// Źródło podpowiedzi przy pisaniu.
  final IngredientCatalog catalog;

  /// Czy podczas pisania szukać w katalogu (false = tylko własne wpisy).
  final bool enableCatalogSearch;

  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  final TextEditingController _controller = TextEditingController();
  List<String> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _suggestions = _computeSuggestions('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Puste zapytanie → szybkie sugestie sekcji; w trakcie pisania → katalog.
  List<String> _computeSuggestions(String query) {
    final selected = widget.tags.map((t) => t.toLowerCase()).toSet();
    if (query.trim().isEmpty) {
      return widget.quickSuggestions
          .where((s) => !selected.contains(s.toLowerCase()))
          .toList();
    }
    if (!widget.enableCatalogSearch) return const [];
    return widget.catalog.suggest(query, exclude: widget.tags.toSet());
  }

  void _refreshSuggestions(String query) {
    setState(() => _suggestions = _computeSuggestions(query));
  }

  void _addTag(String raw) {
    final tag = raw.trim();
    if (tag.isEmpty) return;
    // Pomijamy duplikaty (bez rozróżniania wielkości liter).
    final exists =
        widget.tags.any((t) => t.toLowerCase() == tag.toLowerCase());
    if (!exists) {
      widget.onChanged([...widget.tags, tag]);
    }
    _controller.clear();
    // Po dodaniu pokazujemy ponownie szybkie sugestie sekcji.
    setState(() => _suggestions = _computeSuggestions(''));
  }

  void _removeTag(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
    _refreshSuggestions(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: accent, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: accent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final tag in widget.tags)
                  InputChip(
                    label: Text(tag),
                    backgroundColor: accent.withValues(alpha: 0.15),
                    side: BorderSide(color: accent.withValues(alpha: 0.5)),
                    onDeleted: () => _removeTag(tag),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.add),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            textInputAction: TextInputAction.done,
            onChanged: _refreshSuggestions,
            onSubmitted: _addTag,
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final suggestion in _suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => _addTag(suggestion),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
