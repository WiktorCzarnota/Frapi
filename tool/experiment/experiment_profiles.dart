// Pięć profili użytkownika użytych w eksperymencie (Rozdz. 4, Tabela profili).

import 'package:frapi/models/user_profile.dart';

/// Profile eksperymentu (nazwa -> profil). Kolejność zachowana.
const Map<String, UserProfile> experimentProfiles = {
  'P1 Alergik': UserProfile(
    forbidden: ['orzechy', 'gluten'],
    needs: {DietaryNeed.healthy},
  ),
  'P2 Odchudzanie': UserProfile(
    needs: {DietaryNeed.weightLoss},
    nutrientPrefs: {
      Nutrient.calories: NutrientPreference.less,
      Nutrient.sugar: NutrientPreference.less,
    },
  ),
  'P3 Sportowiec': UserProfile(
    needs: {DietaryNeed.gym},
    nutrientPrefs: {Nutrient.protein: NutrientPreference.more},
  ),
  'P4 Cukrzyca': UserProfile(
    unwanted: ['cukier'],
    nutrientPrefs: {Nutrient.sugar: NutrientPreference.less},
  ),
  'P5 Bez ograniczen': UserProfile(
    needs: {DietaryNeed.healthy},
  ),
};
