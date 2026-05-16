import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
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
            icon: _ViolinIcon(color: colorScheme.onSurfaceVariant),
            selectedIcon: _ViolinIcon(color: colorScheme.onSecondaryContainer),
            label: 'Tuner',
          ),
          const NavigationDestination(
            icon: Icon(Icons.av_timer_outlined),
            selectedIcon: Icon(Icons.av_timer),
            label: 'Metronome',
          ),
          const NavigationDestination(
            icon: Icon(Icons.piano_outlined),
            selectedIcon: Icon(Icons.piano),
            label: 'Chromatic',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Custom violin icon matching the app icon aesthetic
class _ViolinIcon extends StatelessWidget {
  final Color color;
  const _ViolinIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _ViolinIconPainter(color: color),
    );
  }
}

class _ViolinIconPainter extends CustomPainter {
  final Color color;
  const _ViolinIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final s = size.width / 24.0;

    // Neck
    final neckPath = Path();
    neckPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(10.5 * s, 1 * s, 3 * s, 10 * s),
      Radius.circular(1.5 * s),
    ));
    canvas.drawPath(neckPath, paint);

    // Upper bout
    canvas.drawOval(Rect.fromCenter(
      center: Offset(12 * s, 13 * s),
      width: 7 * s,
      height: 6 * s,
    ), paint);

    // Waist fill
    canvas.drawRect(Rect.fromLTWH(9 * s, 15 * s, 6 * s, 3 * s), paint);

    // C-bout cutouts
    final cutPaint = Paint()
      ..color = color.withAlpha(0)
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;

    // Lower bout
    canvas.drawOval(Rect.fromCenter(
      center: Offset(12 * s, 20 * s),
      width: 8.5 * s,
      height: 7 * s,
    ), paint);

    // Scroll
    canvas.drawOval(Rect.fromCenter(
      center: Offset(12 * s, 1.5 * s),
      width: 3 * s,
      height: 2.5 * s,
    ), paint);
  }

  @override
  bool shouldRepaint(covariant _ViolinIconPainter old) => old.color != color;
}
