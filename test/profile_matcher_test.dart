// Testy dopasowania składników do profilu (podświetlanie przy skanowaniu).

import 'package:flutter_test/flutter_test.dart';

import 'package:frapi/models/user_profile.dart';
import 'package:frapi/services/profile_matcher.dart';

void main() {
  const matcher = ProfileMatcher();
  const profile = UserProfile(
    forbidden: ['Orzechy'],
    unwanted: ['Olej palmowy'],
    preferred: ['Białko'],
  );

  test('zakazane ma pierwszeństwo i łapie po fragmencie', () {
    expect(matcher.match('orzechy laskowe', profile), ProfileMatch.forbidden);
  });

  test('niechciane wykrywane (odporne na wielkość liter)', () {
    expect(matcher.match('OLEJ PALMOWY', profile), ProfileMatch.unwanted);
  });

  test('zalecane wykrywane', () {
    expect(matcher.match('białko serwatkowe', profile), ProfileMatch.preferred);
  });

  test('brak dopasowania → none', () {
    expect(matcher.match('woda', profile), ProfileMatch.none);
  });
}
