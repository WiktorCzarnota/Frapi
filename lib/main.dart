import 'package:flutter/material.dart';

import 'screens/main_shell.dart';

void main() {
  runApp(const FrapiApp());
}

/// Główny widget aplikacji — konfiguruje motyw i wskazuje ekran startowy.
///
/// Aplikacja wspomaga świadome zakupy spożywcze: skan kodu kreskowego →
/// dane o produkcie (Open Food Facts) → analiza przez LLM → rekomendacja.
class FrapiApp extends StatelessWidget {
  const FrapiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Świadome zakupy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}
