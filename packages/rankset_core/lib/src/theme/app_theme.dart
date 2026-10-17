import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography: Poppins for English, Noto Sans Devanagari for Hindi (as agreed).
/// Only widely stable ThemeData parameters are used so this compiles across Flutter versions.
class AppTheme {
  const AppTheme._();

  static const double optionHeight = 56;
  static const double optionRadius = 14;
  static const double cardRadius = 16;

  static ThemeData light(String language) => _build(Brightness.light, language);
  static ThemeData dark(String language) => _build(Brightness.dark, language);

  static ThemeData _build(Brightness brightness, String language) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.indigo,
      onPrimary: Colors.white,
      secondary: AppColors.saffron,
      onSecondary: AppColors.text,
      error: AppColors.red,
      onError: Colors.white,
      surface: dark ? AppColors.darkCard : Colors.white,
      onSurface: dark ? AppColors.darkText : AppColors.text,
    );
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? AppColors.darkBg : AppColors.offWhite,
    );
    final family = language == 'hi'
        ? GoogleFonts.notoSansDevanagariTextTheme(base.textTheme)
        : GoogleFonts.poppinsTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: family.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}
