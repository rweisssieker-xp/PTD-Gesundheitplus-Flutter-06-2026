import 'package:flutter/material.dart';

import '../shared_ui/gp_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GpColors.emergencyRed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: GpColors.redSurface,
      cardTheme: CardThemeData(
        color: GpColors.surface,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: GpColors.border),
        ),
      ),
    );
  }
}
