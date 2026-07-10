// Podstawowy test startu aplikacji z dolną nawigacją.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frapi/main.dart';

void main() {
  testWidgets('Aplikacja startuje i pokazuje 4 zakładki nawigacji',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const FrapiApp());
    await tester.pumpAndSettle();

    expect(find.text('Lista'), findsWidgets);
    expect(find.text('Skaner'), findsWidgets);
    expect(find.text('Porównaj'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);
  });
}
