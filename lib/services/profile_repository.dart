import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// Odpowiada za trwałe przechowywanie profilu użytkownika na urządzeniu.
///
/// Używa `shared_preferences` (magazyn klucz-wartość) — bez bazy danych
/// i bez backendu, zgodnie z założeniami MVP. Profil zapisujemy jako JSON
/// pod jednym kluczem.
class ProfileRepository {
  const ProfileRepository();

  static const String _key = 'user_profile';

  /// Wczytuje profil. Gdy brak zapisanego profilu lub dane są uszkodzone,
  /// zwraca profil domyślny.
  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const UserProfile();

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (_) {
      // Uszkodzony wpis — wracamy do profilu domyślnego, by nie wywrócić aplikacji.
      return const UserProfile();
    }
  }

  /// Zapisuje profil użytkownika.
  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }
}
