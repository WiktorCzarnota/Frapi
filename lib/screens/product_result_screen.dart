import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/product_analysis.dart';
import '../models/user_profile.dart';
import '../services/food_labels_info.dart';
import '../services/ingredient_glossary.dart';
import '../services/llm_client.dart';
import '../services/profile_matcher.dart';
import '../services/profile_repository.dart';
import '../widgets/info_sheet.dart';
import 'search_results_screen.dart';

/// Klucz API podawany przy uruchomieniu: --dart-define=GROQ_API_KEY=...
const String _apiKey = String.fromEnvironment('GROQ_API_KEY');

/// Ekran wyniku — dane produktu, podświetlenie składników z profilu oraz
/// dwie osobne funkcje AI: analiza pod profil (1-2) i zdrowsze zamienniki (3).
class ProductResultScreen extends StatefulWidget {
  const ProductResultScreen({
    super.key,
    required this.product,
    this.llmClient,
    this.profileRepository,
  });

  final Product product;
  final LlmClient? llmClient;
  final ProfileRepository? profileRepository;

  @override
  State<ProductResultScreen> createState() => _ProductResultScreenState();
}

class _ProductResultScreenState extends State<ProductResultScreen> {
  static const IngredientGlossary _glossary = IngredientGlossary();
  static const ProfileMatcher _matcher = ProfileMatcher();

  late final ProfileRepository _profileRepository =
      widget.profileRepository ?? const ProfileRepository();
  late final LlmClient _llmClient =
      widget.llmClient ?? LlmClient(apiKey: _apiKey);

  UserProfile _profile = const UserProfile();

  ProductAnalysis? _analysis;
  bool _analyzing = false;
  String? _analysisError;

  List<Alternative>? _alternatives;
  bool _loadingAlts = false;
  String? _altsError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final loaded = await _profileRepository.load();
    if (mounted) setState(() => _profile = loaded);
  }

  Future<void> _analyze() async {
    setState(() {
      _analyzing = true;
      _analysisError = null;
    });
    try {
      final analysis = await _llmClient.analyze(widget.product, _profile);
      if (mounted) setState(() => _analysis = analysis);
    } on LlmException catch (e) {
      if (mounted) setState(() => _analysisError = e.message);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _suggestAlternatives() async {
    setState(() {
      _loadingAlts = true;
      _altsError = null;
    });
    try {
      final alts =
          await _llmClient.suggestAlternatives(widget.product, _profile);
      if (mounted) setState(() => _alternatives = alts);
    } on LlmException catch (e) {
      if (mounted) setState(() => _altsError = e.message);
    } finally {
      if (mounted) setState(() => _loadingAlts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ingredients = IngredientGlossary.split(widget.product.ingredientsText);

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.product.imageUrl != null)
            Center(
              child: Image.network(
                widget.product.imageUrl!,
                height: 160,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 16),
          Text(widget.product.displayName, style: theme.textTheme.headlineSmall),
          if (widget.product.brands != null)
            Text(widget.product.brands!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),

          // Funkcja 1-2: analiza pod profil.
          _AnalysisCard(
            analyzing: _analyzing,
            error: _analysisError,
            analysis: _analysis,
            onAnalyze: _analyze,
          ),
          const SizedBox(height: 12),

          // Funkcja 3: zdrowsze zamienniki (osobno).
          _AlternativesCard(
            loading: _loadingAlts,
            error: _altsError,
            alternatives: _alternatives,
            onSuggest: _suggestAlternatives,
            onOpenAlternative: (alt) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SearchResultsScreen(
                  query: alt.name,
                  titlePrefix: 'Zamiennik',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Oceny — klikalne plakietki.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.product.nutriScore != null)
                _ScoreBadge(
                  label:
                      'Nutri-Score: ${widget.product.nutriScore!.toUpperCase()}',
                  onTap: () => showInfoSheet(
                    context,
                    FoodLabelsInfo.forNutriScore(widget.product.nutriScore!),
                  ),
                ),
              if (widget.product.novaGroup != null)
                _ScoreBadge(
                  label: 'NOVA: ${widget.product.novaGroup}',
                  onTap: () => showInfoSheet(
                    context,
                    FoodLabelsInfo.forNova(widget.product.novaGroup!),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Skład — z podświetleniem pozycji z profilu.
          _Section(
            title: 'Skład (kolor = z Twojego profilu; dotknij po szczegóły)',
            child: ingredients.isEmpty
                ? const Text('Brak danych o składzie.')
                : Column(
                    children: [
                      for (final ingredient in ingredients)
                        _IngredientTile(
                          explanation: _glossary.lookup(ingredient),
                          match: _matcher.match(ingredient, _profile),
                          onTap: () => showInfoSheet(
                            context,
                            _glossary.lookup(ingredient),
                          ),
                        ),
                    ],
                  ),
          ),

          if (widget.product.allergens.isNotEmpty)
            _Section(
              title: 'Alergeny',
              child: Text(widget.product.allergens.join(', ')),
            ),

          _Section(
            title: 'Wartości odżywcze (na 100 g)',
            child: _NutritionTable(nutriments: widget.product.nutriments),
          ),
        ],
      ),
    );
  }
}

/// Karta analizy pod profil: przycisk + werdykt + interpretacja.
class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.analyzing,
    required this.error,
    required this.analysis,
    required this.onAnalyze,
  });

  final bool analyzing;
  final String? error;
  final ProductAnalysis? analysis;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton.icon(
              onPressed: analyzing ? null : onAnalyze,
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                analysis == null ? 'Analizuj z AI (Twój profil)' : 'Analizuj ponownie',
              ),
            ),
            if (analyzing) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (analysis != null && !analyzing) ...[
              const SizedBox(height: 16),
              _Verdict(recommendation: analysis!.recommendation),
              const SizedBox(height: 8),
              Text(analysis!.recommendationReason),
              const SizedBox(height: 12),
              Text(analysis!.summary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Karta zdrowszych zamienników (osobna funkcja).
class _AlternativesCard extends StatelessWidget {
  const _AlternativesCard({
    required this.loading,
    required this.error,
    required this.alternatives,
    required this.onSuggest,
    required this.onOpenAlternative,
  });

  final bool loading;
  final String? error;
  final List<Alternative>? alternatives;
  final VoidCallback onSuggest;
  final ValueChanged<Alternative> onOpenAlternative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: loading ? null : onSuggest,
              icon: const Icon(Icons.swap_horiz),
              label: Text(
                alternatives == null
                    ? 'Zaproponuj zdrowsze zamienniki'
                    : 'Zaproponuj ponownie',
              ),
            ),
            if (loading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (alternatives != null && !loading) ...[
              const SizedBox(height: 4),
              if (alternatives!.isEmpty)
                const Text('Brak propozycji.')
              else ...[
                const Text(
                  'Dotknij zamiennik, by znaleźć go w bazie produktów.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                for (final alt in alternatives!)
                  InkWell(
                    onTap: () => onOpenAlternative(alt),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alt.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(alt.reason),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.search, size: 20),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// „Plakietka" werdyktu oceny pod profil (tak / z umiarem / nie).
class _Verdict extends StatelessWidget {
  const _Verdict({required this.recommendation});
  final Recommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final color = Color(recommendation.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            recommendation.label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Wiersz składnika: kropka poziomu obaw + nazwa + chip profilu + ikona „info".
class _IngredientTile extends StatelessWidget {
  const _IngredientTile({
    required this.explanation,
    required this.match,
    required this.onTap,
  });

  final IngredientExplanation explanation;
  final ProfileMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final concernColor = Color(explanation.concern.colorValue);
    final matched = match != ProfileMatch.none;
    final matchColor = Color(match.colorValue);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: matched
            ? BoxDecoration(
                color: matchColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: matchColor.withValues(alpha: 0.5)),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: concernColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(explanation.term)),
            if (matched) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: matchColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  match.label,
                  style: TextStyle(
                    color: matchColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.info_outline, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Tabela wartości odżywczych: kolejne wiersze rozdzielone tłem,
/// wartości tuż przy etykiecie (po lewej). Wiersze bez danych są pomijane.
class _NutritionTable extends StatelessWidget {
  const _NutritionTable({required this.nutriments});

  final Nutriments nutriments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <(String, double?, String)>[
      ('Energia', nutriments.energyKcal, 'kcal'),
      ('Tłuszcz', nutriments.fat, 'g'),
      ('w tym kwasy nasycone', nutriments.saturatedFat, 'g'),
      ('Węglowodany', nutriments.carbohydrates, 'g'),
      ('w tym cukry', nutriments.sugars, 'g'),
      ('Białko', nutriments.proteins, 'g'),
      ('Sól', nutriments.salt, 'g'),
    ].where((row) => row.$2 != null).toList();

    if (rows.isEmpty) return const Text('Brak danych odżywczych.');

    final stripe = theme.colorScheme.surfaceContainerHighest;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              color: i.isEven ? stripe : theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 190,
                    child: Text(rows[i].$1, style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                    '${_format(rows[i].$2!)} ${rows[i].$3}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Liczba bez zbędnych zer (np. 6.0 → „6", 6.30 → „6.3").
  static String _format(double v) {
    final rounded = (v * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }
}

/// Sekcja z tytułem i dowolną zawartością.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Klikalna „plakietka" oceny (Nutri-Score / NOVA).
class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      avatar: Icon(
        Icons.info_outline,
        size: 18,
        color: theme.colorScheme.onSecondaryContainer,
      ),
      label: Text(label),
      backgroundColor: theme.colorScheme.secondaryContainer,
      onPressed: onTap,
    );
  }
}
