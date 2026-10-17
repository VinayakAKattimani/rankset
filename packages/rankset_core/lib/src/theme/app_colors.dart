import 'package:flutter/material.dart';

/// Colours agreed in the layout guide.
class AppColors {
  const AppColors._();
  static const Color indigo = Color(0xFF3F3D9E);
  static const Color indigoSoft = Color(0xFF5654B8);
  static const Color saffron = Color(0xFFFF9933);
  static const Color offWhite = Color(0xFFF7F8FC);
  static const Color green = Color(0xFF2E9E5B);
  static const Color red = Color(0xFFD64545);
  static const Color text = Color(0xFF1F2230);
  static const Color grey = Color(0xFF8A8FA3);
  static const Color line = Color(0xFFE1E3EE);
  static const Color lavender = Color(0xFFECEBFA);
  static const Color greenTint = Color(0xFFE3F5EA);
  static const Color redTint = Color(0xFFFBE6E6);

  // Dark mode
  static const Color darkBg = Color(0xFF12131A);
  static const Color darkCard = Color(0xFF1C1E2A);
  static const Color darkLine = Color(0xFF2C2F40);
  static const Color darkText = Color(0xFFF2F3F8);
}

/// Colours that change with light/dark mode. Use `Palette.of(context)` in widgets.
class Palette {
  const Palette._({
    required this.dark,
    required this.bg,
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
    required this.tint,
    required this.correctTint,
    required this.wrongTint,
  });

  final bool dark;
  final Color bg;
  final Color card;
  final Color border;
  final Color text;
  final Color muted;
  final Color tint;
  final Color correctTint;
  final Color wrongTint;

  static Palette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return Palette._(
        dark: true,
        bg: AppColors.darkBg,
        card: AppColors.darkCard,
        border: AppColors.darkLine,
        text: AppColors.darkText,
        muted: const Color(0xFFA4A9BD),
        tint: AppColors.indigo.withAlpha(70),
        correctTint: AppColors.green.withAlpha(45),
        wrongTint: AppColors.red.withAlpha(45),
      );
    }
    return const Palette._(
      dark: false,
      bg: AppColors.offWhite,
      card: Colors.white,
      border: AppColors.line,
      text: AppColors.text,
      muted: AppColors.grey,
      tint: AppColors.lavender,
      correctTint: AppColors.greenTint,
      wrongTint: AppColors.redTint,
    );
  }
}
