// Testy serializacji profilu użytkownika (model UserProfile).
//
// Sprawdzają, że profil przetrwa zapis i odczyt (round-trip toJson/fromJson)
// oraz że uszkodzone/niekompletne dane nie wywracają aplikacji.

import 'package:flutter_test/flutter_test.dart';

import 'package:frapi/models/user_profile.dart';

void main() {
  test('round-trip: toJson → fromJson zachowuje wartości', () {
    const profile = UserProfile(
      forbidden: ['Orzechy', 'Laktoza'],
      unwanted: ['Olej palmowy'],
      preferred: ['Białko', 'Błonnik'],
      needs: {DietaryNeed.gym, DietaryNeed.healthy},
      customNeeds: ['Keto', 'IF 16/8'],
      nutrientPrefs: {
        Nutrient.sugar: NutrientPreference.less,
        Nutrient.protein: NutrientPreference.more,
      },
    );

    final restored = UserProfile.fromJson(profile.toJson());

    expect(restored.forbidden, ['Orzechy', 'Laktoza']);
    expect(restored.unwanted, ['Olej palmowy']);
    expect(restored.preferred, ['Białko', 'Błonnik']);
    expect(restored.needs, {DietaryNeed.gym, DietaryNeed.healthy});
    expect(restored.customNeeds, ['Keto', 'IF 16/8']);
    expect(restored.preferenceOf(Nutrient.sugar), NutrientPreference.less);
    expect(restored.preferenceOf(Nutrient.protein), NutrientPreference.more);
  });

  test('preferenceOf: brak ustawienia zwraca „obojętnie"', () {
    const profile = UserProfile();
    expect(profile.preferenceOf(Nutrient.calories), NutrientPreference.neutral);
  });

  test('fromJson: pusta mapa daje profil domyślny', () {
    final profile = UserProfile.fromJson({});

    expect(profile.forbidden, isEmpty);
    expect(profile.unwanted, isEmpty);
    expect(profile.preferred, isEmpty);
    expect(profile.needs, isEmpty);
    expect(profile.nutrientPrefs, isEmpty);
  });

  test('fromJson: uszkodzone/nieznane dane są ignorowane', () {
    final profile = UserProfile.fromJson({
      'forbidden': ['Orzechy', 123, null], // tylko napisy przechodzą
      'needs': ['gym', 'cos_dziwnego'],
      'nutrientPrefs': {
        'sugar': 'less', // poprawne
        'cos': 'more', // nieznana wartość odżywcza
        'protein': 'xxx', // nieznana preferencja
      },
    });

    expect(profile.forbidden, ['Orzechy']);
    expect(profile.needs, {DietaryNeed.gym});
    expect(profile.preferenceOf(Nutrient.sugar), NutrientPreference.less);
    expect(profile.preferenceOf(Nutrient.protein), NutrientPreference.neutral);
    expect(profile.nutrientPrefs, hasLength(1));
  });
}
