import 'package:flutter/material.dart';
import 'tuner_screen.dart';
import 'metronome_screen.dart';
import 'chromatic_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    TunerScreen(),
    MetronomeScreen(),
    ChromaticScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        destinations: [
          NavigationDestination(
            icon: Image.asset(
              'assets/images/icon_violin_head.png',
              width: 24,
              height: 24,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Image.asset(
              'assets/images/icon_violin_head.png',
              width: 24,
              height: 24,
              color: colorScheme.onSecondaryContainer,
            ),
            label: 'Tuner',
          ),
          NavigationDestination(
            icon: Image.asset(
              'assets/images/icon_tab_metronome.png',
              width: 24,
              height: 24,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Image.asset(
              'assets/images/icon_tab_metronome.png',
              width: 24,
              height: 24,
              color: colorScheme.onSecondaryContainer,
            ),
            label: 'Metronome',
          ),
          const NavigationDestination(
            icon: Icon(Icons.piano_outlined),
            selectedIcon: Icon(Icons.piano),
            label: 'Chromatic',
          ),
          NavigationDestination(
            icon: Image.asset(
              'assets/images/icon_tab_setting.png',
              width: 24,
              height: 24,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Image.asset(
              'assets/images/icon_tab_setting.png',
              width: 24,
              height: 24,
              color: colorScheme.onSecondaryContainer,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
