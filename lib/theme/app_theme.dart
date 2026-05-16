import 'package:flutter/material.dart';

class AppTheme {
  // Default fallback colors when dynamic colors not available
  static const _seedColor = Color(0xFF2AB5A5); // Teal-green like the app

  static final ColorScheme defaultLightScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
  );

  static final ColorScheme defaultDarkScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  );
}
