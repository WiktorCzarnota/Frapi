import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/profile_repository.dart';
import '../widgets/tag_picker.dart';

/// Ekran profilu użytkownika (funkcja 2 MVP).
///
/// Użytkownik definiuje: składniki zakazane / niechciane / zalecane, ogólne
/// potrzeby żywieniowe oraz wagi aspektów oceny (1-5). Profil jest wczytywany
/// przy wejściu i zapisywany lokalnie po kliknięciu „Zapisz"
/// (`ProfileRepository` → `shared_preferences`).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, ProfileRepository? repository})
      : repository = repository ?? _defaultRepository;

  final ProfileRepository repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// Pojedyncza, współdzielona instancja repozytorium (domyślna).
const _defaultRepository = ProfileRepository();

// Kolory akcentu rozróżniające trzy sekcje składników.
const Color _forbiddenColor = Color(0xFFD32F2F); // czerwony – zakaz
const Color _unwantedColor = Color(0xFFEF6C00); // pomarańczowy – ostrożnie
const Color _preferredColor = Color(0xFF2E7D32); // zielony – pożądane

// Domyślne podpowiedzi specyficzne dla każdej sekcji (bez powtórzeń między nimi).
const List<String> _forbiddenSuggestions = [
  'Orzechy', 'Gluten', 'Laktoza', 'Jaja', 'Soja', 'Ryby',
];
const List<String> _unwantedSuggestions = [
  'Olej palmowy', 'Cukier', 'Syrop glukozowo-fruktozowy',
  'Konserwanty', 'Barwniki', 'Tłuszcze trans',
];
const List<String> _preferredSuggestions = [
  'Białko', 'Błonnik', 'Pełne ziarno', 'Kwasy omega-3', 'Warzywa', 'Probiotyki',
];

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile _profile = const UserProfile();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final loaded = await widget.repository.load();
    if (!mounted) return;
    setState(() {
      _profile = loaded;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await widget.repository.save(_profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil zapisany')),
    );
  }

  void _toggleNeed(DietaryNeed need, bool selected) {
    setState(() {
      final updated = Set<DietaryNeed>.from(_profile.needs);
      if (selected) {
        updated.add(need);
      } else {
        updated.remove(need);
      }
      _profile = _profile.copyWith(needs: updated);
    });
  }

  void _setPreference(Nutrient nutrient, NutrientPreference preference) {
    setState(() {
      final updated =
          Map<Nutrient, NutrientPreference>.from(_profile.nutrientPrefs);
      updated[nutrient] = preference;
      _profile = _profile.copyWith(nutrientPrefs: updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TagPicker(
                  title: 'Składniki zakazane (kategorycznie)',
                  icon: Icons.block,
                  accentColor: _forbiddenColor,
                  tags: _profile.forbidden,
                  hintText: 'Np. orzechy…',
                  quickSuggestions: _forbiddenSuggestions,
                  onChanged: (tags) => setState(
                    () => _profile = _profile.copyWith(forbidden: tags),
                  ),
                ),
                const SizedBox(height: 16),
                TagPicker(
                  title: 'Składniki niechciane (unikam, ale dopuszczalne)',
                  icon: Icons.thumb_down_alt_outlined,
                  accentColor: _unwantedColor,
                  tags: _profile.unwanted,
                  hintText: 'Np. konserwanty…',
                  quickSuggestions: _unwantedSuggestions,
                  onChanged: (tags) => setState(
                    () => _profile = _profile.copyWith(unwanted: tags),
                  ),
                ),
                const SizedBox(height: 16),
                TagPicker(
                  title: 'Składniki zalecane (zależy mi na nich)',
                  icon: Icons.thumb_up_alt_outlined,
                  accentColor: _preferredColor,
                  tags: _profile.preferred,
                  hintText: 'Np. białko…',
                  quickSuggestions: _preferredSuggestions,
                  onChanged: (tags) => setState(
                    () => _profile = _profile.copyWith(preferred: tags),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Co AI ma o Tobie wiedzieć przy analizie',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final need in DietaryNeed.values)
                      FilterChip(
                        label: Text(need.label),
                        selected: _profile.needs.contains(need),
                        onSelected: (selected) => _toggleNeed(need, selected),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TagPicker(
                  title: 'Dopisz coś o sobie (własne)',
                  icon: Icons.edit_outlined,
                  tags: _profile.customNeeds,
                  hintText: 'Np. cukrzyca, sportowiec, unikam ostrego…',
                  enableCatalogSearch: false,
                  onChanged: (tags) => setState(
                    () => _profile = _profile.copyWith(customNeeds: tags),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Preferencje wartości odżywczych',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Zaznacz, czego chcesz w produktach mniej lub więcej. '
                  'Domyślnie: obojętnie.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                for (final nutrient in Nutrient.values) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(nutrient.label),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<NutrientPreference>(
                      segments: const [
                        ButtonSegment(
                          value: NutrientPreference.less,
                          label: Text('Mniej'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                        ButtonSegment(
                          value: NutrientPreference.neutral,
                          label: Text('Obojętnie'),
                        ),
                        ButtonSegment(
                          value: NutrientPreference.more,
                          label: Text('Więcej'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                      ],
                      selected: {_profile.preferenceOf(nutrient)},
                      onSelectionChanged: (selection) =>
                          _setPreference(nutrient, selection.first),
                      showSelectedIcon: false,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Zapisz'),
                ),
              ],
            ),
    );
  }
}
