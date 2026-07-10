// Testy budowania promptu analizy (produkt + profil → treść dla LLM).

import 'package:flutter_test/flutter_test.dart';

import 'package:frapi/models/product.dart';
import 'package:frapi/models/user_profile.dart';
import 'package:frapi/services/analysis_prompt.dart';

void main() {
  const product = Product(
    code: '123',
    name: 'Nutella',
    ingredientsText: 'cukier, olej palmowy',
    nutriScore: 'e',
    novaGroup: 4,
  );
  const profile = UserProfile(
    forbidden: ['orzechy'],
    unwanted: ['olej palmowy'],
    preferred: ['białko'],
    needs: {DietaryNeed.gym},
    nutrientPrefs: {Nutrient.sugar: NutrientPreference.less},
  );

  test('wiadomość zawiera dane produktu', () {
    final message = AnalysisPrompt.userMessage(product, profile);
    expect(message, contains('Nutella'));
    expect(message, contains('cukier, olej palmowy'));
    expect(message, contains('NOVA: 4'));
  });

  test('wiadomość zawiera profil użytkownika', () {
    final message = AnalysisPrompt.userMessage(product, profile);
    expect(message, contains('orzechy')); // zakazane
    expect(message, contains('olej palmowy')); // niechciane
    expect(message, contains('białko')); // zalecane
    expect(message, contains('Siłownia / budowa masy')); // cel
    expect(message, contains('cukier jak najmniej')); // preferencja odżywcza
  });

  test('system prompt wymusza twardą blokadę składników zakazanych', () {
    expect(AnalysisPrompt.system.toLowerCase(), contains('zakazan'));
    expect(AnalysisPrompt.system, contains('"nie"'));
  });
}
