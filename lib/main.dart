import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'services/metronome_service.dart';
import 'services/tuner_service.dart';
import 'services/instrument_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TunerService()),
        ChangeNotifierProvider(create: (_) => MetronomeService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => InstrumentService()),
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
            // Dark grey scheme when Material You is disabled
            const darkGreySeed = Color(0xFF2E2E2E);
            final greyDarkScheme = ColorScheme.fromSeed(
              seedColor: darkGreySeed,
              brightness: Brightness.dark,
            ).copyWith(
              surface: const Color(0xFF1A1A1A),
              surfaceContainerLow: const Color(0xFF222222),
              surfaceContainerHighest: const Color(0xFF2E2E2E),
              primary: const Color(0xFFAAAAAA),
              onPrimary: const Color(0xFF1A1A1A),
              secondary: const Color(0xFF888888),
            );
            final greyLightScheme = ColorScheme.fromSeed(
              seedColor: darkGreySeed,
              brightness: Brightness.light,
            ).copyWith(
              surface: const Color(0xFFF0F0F0),
              surfaceContainerLow: const Color(0xFFE0E0E0),
              surfaceContainerHighest: const Color(0xFFD0D0D0),
            );

            final ColorScheme lightScheme;
            final ColorScheme darkScheme;

            if (themeProvider.useMaterialYou) {
              lightScheme = lightDynamic?.harmonized() ?? AppTheme.defaultLightScheme;
              darkScheme = darkDynamic?.harmonized() ?? AppTheme.defaultDarkScheme;
            } else {
              lightScheme = greyLightScheme;
              darkScheme = greyDarkScheme;
            }

            return MaterialApp(
              title: 'Tuner',
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
  bool _useMaterialYou = true;

  ThemeMode get themeMode => _themeMode;
  bool get useMaterialYou => _useMaterialYou;

  ThemeProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('themeMode') ?? 0; // 0=system,1=light,2=dark
    _themeMode = ThemeMode.values[modeIndex.clamp(0, 2)];
    _useMaterialYou = prefs.getBool('useMaterialYou') ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  Future<void> setUseMaterialYou(bool value) async {
    _useMaterialYou = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useMaterialYou', value);
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
