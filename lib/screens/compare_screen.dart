import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/product_analysis.dart';
import '../services/llm_client.dart';
import '../services/profile_repository.dart';

/// Klucz API podawany przy uruchomieniu: --dart-define=GROQ_API_KEY=...
const String _apiKey = String.fromEnvironment('GROQ_API_KEY');

/// Ekran porównania wybranych produktów (do 6) w formie tabeli.
///
/// - kolumny = produkty, wiersze = oceny i wartości odżywcze (na 100 g),
/// - długość paska pokazuje, kto ma danego składnika więcej/mniej,
/// - kolor wyróżnia wartość najlepszą (zielony) i najgorszą (czerwony),
/// - kliknięcie w nazwę składnika sortuje produkty po tej wartości,
/// - na górze krótkie podsumowanie AI (który produkt jest najlepszy).
class CompareScreen extends StatefulWidget {
  const CompareScreen({
    super.key,
    required this.products,
    this.llmClient,
    this.profileRepository,
  });

  final List<Product> products;
  final LlmClient? llmClient;
  final ProfileRepository? profileRepository;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  // Kierunek oceny składnika: co jest „lepsze" dla użytkownika.
  static const _lower = _Dir.lower; // mniej = lepiej
  static const _higher = _Dir.higher; // więcej = lepiej
  static const _neutral = _Dir.neutral; // bez oceny (tylko pasek)

  static final List<_Metric> _metrics = [
    _Metric('Nutri-Score', _lower, _Kind.grade, (p) {
      final s = p.nutriScore;
      if (s == null || s.isEmpty) return (null, '—');
      final v = s.toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0) + 1;
      return (v.toDouble(), s.toUpperCase());
    }),
    _Metric('NOVA', _lower, _Kind.grade, (p) {
      final n = p.novaGroup;
      return n == null ? (null, '—') : (n.toDouble(), n.toString());
    }),
    _Metric('Energia (kcal)', _lower, _Kind.number,
        (p) => _num(p.nutriments.energyKcal)),
    _Metric('Tłuszcz (g)', _lower, _Kind.number, (p) => _num(p.nutriments.fat)),
    _Metric('Nasycone (g)', _lower, _Kind.number,
        (p) => _num(p.nutriments.saturatedFat)),
    _Metric('Węglowodany (g)', _neutral, _Kind.number,
        (p) => _num(p.nutriments.carbohydrates)),
    _Metric('Cukry (g)', _lower, _Kind.number,
        (p) => _num(p.nutriments.sugars)),
    _Metric('Białko (g)', _higher, _Kind.number,
        (p) => _num(p.nutriments.proteins)),
    _Metric('Sól (g)', _lower, _Kind.number, (p) => _num(p.nutriments.salt)),
  ];

  static const Color _good = Color(0xFF2E7D32);
  static const Color _bad = Color(0xFFC62828);
  static const Color _neutralBar = Color(0xFF90A4AE);

  late final ProfileRepository _profileRepository =
      widget.profileRepository ?? const ProfileRepository();
  late final LlmClient _llmClient =
      widget.llmClient ?? LlmClient(apiKey: _apiKey);

  late final List<Product> _products = List.of(widget.products);

  // Aktualne sortowanie (etykieta składnika + kierunek).
  String? _sortLabel;
  bool _sortDescending = true;

  // Podsumowanie AI.
  ProductComparison? _comparison;
  bool _loadingAi = true;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    _loadComparison();
  }

  Future<void> _loadComparison() async {
    try {
      final profile = await _profileRepository.load();
      final result = await _llmClient.compareProducts(_products, profile);
      if (mounted) {
        setState(() {
          _comparison = result;
          _loadingAi = false;
        });
      }
    } on LlmException catch (e) {
      if (mounted) {
        setState(() {
          _aiError = e.message;
          _loadingAi = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiError = 'Nie udało się wczytać podsumowania AI.';
          _loadingAi = false;
        });
      }
    }
  }

  /// Sortuje produkty po wartości danego składnika (braki na końcu).
  void _sortBy(_Metric metric) {
    setState(() {
      if (_sortLabel == metric.label) {
        _sortDescending = !_sortDescending;
      } else {
        _sortLabel = metric.label;
        _sortDescending = true;
      }
      _products.sort((a, b) {
        final va = metric.cell(a).$1;
        final vb = metric.cell(b).$1;
        if (va == null && vb == null) return 0;
        if (va == null) return 1; // brak danych na koniec
        if (vb == null) return -1;
        final cmp = va.compareTo(vb);
        return _sortDescending ? -cmp : cmp;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Porównanie')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AiSummary(
            loading: _loadingAi,
            error: _aiError,
            comparison: _comparison,
          ),
          const _Legend(),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: DataTable(
                  columnSpacing: 20,
                  headingRowHeight: 56,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 60,
                  columns: [
                    const DataColumn(label: Text('')),
                    for (final product in _products)
                      DataColumn(
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Text(
                            product.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                  rows: [
                    for (final metric in _metrics) _buildRow(metric),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(_Metric metric) {
    final cells = _products.map(metric.cell).toList();
    final values = cells
        .map((c) => c.$1)
        .whereType<double>()
        .toList(growable: false);

    double? best, worst;
    if (values.length >= 2 && metric.dir != _Dir.neutral) {
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);
      if (min != max) {
        best = metric.dir == _Dir.lower ? min : max;
        worst = metric.dir == _Dir.lower ? max : min;
      }
    }

    final barMax = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);

    return DataRow(
      cells: [
        DataCell(_MetricLabel(
          label: metric.label,
          sortActive: _sortLabel == metric.label,
          descending: _sortDescending,
          onTap: () => _sortBy(metric),
        )),
        for (final cell in cells)
          DataCell(_valueCell(metric, cell, best, worst, barMax)),
      ],
    );
  }

  Widget _valueCell(
    _Metric metric,
    (double?, String) cell,
    double? best,
    double? worst,
    double barMax,
  ) {
    final value = cell.$1;
    final text = cell.$2;

    if (value == null) {
      return const Text('—', style: TextStyle(color: Colors.grey));
    }

    final isBest = best != null && value == best;
    final isWorst = worst != null && value == worst;
    final color = isBest ? _good : (isWorst ? _bad : null);

    if (metric.kind == _Kind.grade) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (color ?? _neutralBar).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color ?? Colors.black87,
          ),
        ),
      );
    }

    final frac = barMax > 0 ? (value / barMax).clamp(0.0, 1.0) : 0.0;
    final barColor = color ?? _neutralBar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight:
                (isBest || isWorst) ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 56,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: frac == 0 ? 0.02 : frac,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static (double?, String) _num(double? v) =>
      v == null ? (null, '—') : (v, _fmt(v));

  static String _fmt(double v) {
    final rounded = (v * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }
}

/// Kierunek oceny składnika.
enum _Dir { lower, higher, neutral }

/// Rodzaj prezentacji wiersza.
enum _Kind { grade, number }

class _Metric {
  const _Metric(this.label, this.dir, this.kind, this.cell);

  final String label;
  final _Dir dir;
  final _Kind kind;

  /// Zwraca (wartość porównywalną, tekst) dla danego produktu.
  final (double?, String) Function(Product) cell;
}

/// Etykieta składnika (nagłówek wiersza) — klikalna, sortuje produkty.
class _MetricLabel extends StatelessWidget {
  const _MetricLabel({
    required this.label,
    required this.sortActive,
    required this.descending,
    required this.onTap,
  });

  final String label;
  final bool sortActive;
  final bool descending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: sortActive ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            sortActive
                ? (descending ? Icons.arrow_downward : Icons.arrow_upward)
                : Icons.unfold_more,
            size: 14,
            color: sortActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

/// Karta z podsumowaniem AI (który produkt najlepszy / czym się wyróżnia).
class _AiSummary extends StatelessWidget {
  const _AiSummary({
    required this.loading,
    required this.error,
    required this.comparison,
  });

  final bool loading;
  final String? error;
  final ProductComparison? comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: _content(theme)),
          ],
        ),
      ),
    );
  }

  Widget _content(ThemeData theme) {
    if (loading) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('AI porównuje produkty…'),
        ],
      );
    }
    if (error != null) {
      return Text(error!, style: TextStyle(color: theme.colorScheme.error));
    }
    final c = comparison;
    if (c == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.best.trim().isNotEmpty) ...[
          Text(
            'Najlepszy: ${c.best}',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
        ],
        if (c.summary.trim().isNotEmpty) Text(c.summary),
      ],
    );
  }
}

/// Legenda tłumacząca kolory i paski.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          _dot(const Color(0xFF2E7D32), 'lepsze', style),
          _dot(const Color(0xFFC62828), 'gorsze', style),
          Text('pasek = ile · stuknij składnik, aby sortować', style: style),
        ],
      ),
    );
  }

  Widget _dot(Color color, String label, TextStyle? style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}
