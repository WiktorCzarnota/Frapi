import '../models/user_profile.dart';

/// Wynik dopasowania składnika do list profilu użytkownika.
enum ProfileMatch {
  none('', 0),
  forbidden('zakazane', 0xFFD32F2F), // czerwony
  unwanted('niechciane', 0xFFEF6C00), // pomarańczowy
  preferred('zalecane', 0xFF2E7D32); // zielony

  const ProfileMatch(this.label, this.colorValue);

  /// Etykieta widoczna w UI.
  final String label;

  /// Kolor akcentu (ARGB).
  final int colorValue;
}

/// Sprawdza, czy [ingredient] pasuje do którejś z list profilu, i podświetla go.
///
/// Pierwszeństwo: zakazane → niechciane → zalecane. Dopasowanie jest odporne na
/// wielkość liter i polskie znaki oraz działa „po fragmencie" (np. profil
/// „orzechy" trafi w składnik „orzechy laskowe").
class ProfileMatcher {
  const ProfileMatcher();

  ProfileMatch match(String ingredient, UserProfile profile) {
    final normalized = _normalize(ingredient);
    if (_contains(profile.forbidden, normalized)) return ProfileMatch.forbidden;
    if (_contains(profile.unwanted, normalized)) return ProfileMatch.unwanted;
    if (_contains(profile.preferred, normalized)) return ProfileMatch.preferred;
    return ProfileMatch.none;
  }

  bool _contains(List<String> items, String normalizedIngredient) {
    for (final item in items) {
      final normalizedItem = _normalize(item);
      if (normalizedItem.isEmpty) continue;
      if (normalizedIngredient.contains(normalizedItem) ||
          normalizedItem.contains(normalizedIngredient)) {
        return true;
      }
    }
    return false;
  }

  static String _normalize(String text) {
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_diacritics[char] ?? char);
    }
    return buffer.toString().trim();
  }

  static const Map<String, String> _diacritics = {
    'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n',
    'ó': 'o', 'ś': 's', 'ź': 'z', 'ż': 'z',
  };
}
