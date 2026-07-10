import 'package:flutter/material.dart';

import 'compare_tab.dart';
import 'list_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

/// Główny szkielet aplikacji z dolną nawigacją: Lista / Skaner / Porównaj / Profil.
///
/// Zakładki trzymane w [IndexedStack], żeby zachowywały swój stan przy
/// przełączaniu. Wejście na „Listę"/„Porównaj" odświeża historię skanów.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 1; // domyślnie Skaner
  final GlobalKey<ListScreenState> _listKey = GlobalKey<ListScreenState>();
  final GlobalKey<CompareTabState> _compareKey = GlobalKey<CompareTabState>();

  late final List<Widget> _screens = [
    ListScreen(key: _listKey),
    const ScanScreen(),
    CompareTab(key: _compareKey),
    ProfileScreen(),
  ];

  void _onSelect(int index) {
    setState(() => _index = index);
    if (index == 0) _listKey.currentState?.reload();
    if (index == 2) _compareKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onSelect,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'Lista'),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Skaner',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows),
            label: 'Porównaj',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
