import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/ingredient_glossary.dart';

/// Pokazuje dolny panel z wyjaśnieniem (składnik, Nutri-Score lub NOVA).
///
/// Panel zawiera: nazwę, „plakietkę" poziomu obaw, prosty opis oraz przycisk
/// otwierający wyszukiwarkę Google z nazwą - by użytkownik mógł doczytać więcej.
Future<void> showInfoSheet(
  BuildContext context,
  IngredientExplanation info,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _InfoSheetContent(info: info),
  );
}

/// Buduje adres wyszukiwania Google dla podanego hasła.
Uri googleSearchUrl(String query) {
  return Uri.parse(
    'https://www.google.com/search?q=${Uri.encodeComponent(query)}',
  );
}

class _InfoSheetContent extends StatelessWidget {
  const _InfoSheetContent({required this.info});

  final IngredientExplanation info;

  Future<void> _readMore() async {
    final url = googleSearchUrl(info.searchQuery);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final concernColor = Color(info.concern.colorValue);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(info.term, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: concernColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              info.concern.label,
              style: TextStyle(color: concernColor, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Text(info.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _readMore,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Czytaj więcej w Google'),
            ),
          ),
        ],
      ),
    );
  }
}
