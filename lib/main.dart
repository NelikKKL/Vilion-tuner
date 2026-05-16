import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'services/metronome_service.dart';
import 'services/tuner_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TunerService()),
        ChangeNotifierProvider(create: (_) => MetronomeService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const ViolinTunerApp(),
    ),
  );
}

class ViolinTunerApp extends StatelessWidget {
  const ViolinTunerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            final lightScheme = lightDynamic?.harmonized() ??
                AppTheme.defaultLightScheme;
            final darkScheme = darkDynamic?.harmonized() ??
                AppTheme.defaultDarkScheme;

            return MaterialApp(
              title: 'Violin Tuner',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode,
              theme: ThemeData(
                colorScheme: lightScheme,
                useMaterial3: true,
                fontFamily: 'sans-serif',
              ),
              darkTheme: ThemeData(
                colorScheme: darkScheme,
                useMaterial3: true,
                fontFamily: 'sans-serif',
              ),
              home: const MainScreen(),
            );
          },
        );
      },
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }
}
