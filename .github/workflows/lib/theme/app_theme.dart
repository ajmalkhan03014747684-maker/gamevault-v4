import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GameVault design system.
/// Every hex value here is copied 1:1 from the reference sheet's
/// "Theme Recommendation" panel. Do not change these — every screen
/// pulls from this file so the whole app stays visually identical.
class AppColors {
  AppColors._();

  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color secondaryOrange = Color(0xFFFF6B35);
  static const Color successGreen = Color(0xFF2ED573);
  static const Color dangerRed = Color(0xFFFF4757);
  static const Color gold = Color(0xFFFFD700);

  static const Color background = Color(0xFF07080F);
  static const Color surface = Color(0xFF0D0F1A);
  static const Color surface2 = Color(0xFF13162A);

  static const Color text = Color(0xFFE8EAF6);
  static const Color muted = Color(0xFF7B80A8);

  static Color glassBorder = Colors.white.withOpacity(0.08);
  static Color glassFill = Colors.white.withOpacity(0.04);
}

class AppGradients {
  AppGradients._();

  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primaryPurple, Color(0xFF8B7CFF)],
  );

  static const LinearGradient rewardButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.secondaryOrange, Color(0xFFFF8C5A)],
  );

  static const LinearGradient successGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.successGreen, Color(0xFF1BA85C)],
  );

  static const RadialGradient screenGlow = RadialGradient(
    center: Alignment(0, -0.6),
    radius: 1.3,
    colors: [Color(0xFF171238), AppColors.background],
  );
}

class AppText {
  AppText._();

  static TextStyle heading({
    double size = 22,
    Color color = AppColors.text,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.orbitron(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: 0.5,
      );

  static TextStyle body({
    double size = 15,
    Color color = AppColors.text,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        color: color,
        fontWeight: weight,
      );

  static TextStyle caption({
    double size = 12,
    Color color = AppColors.muted,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color,
        fontWeight: weight,
      );
}

class AppRadius {
  AppRadius._();
  static const double card = 20;
  static const double button = 14;
  static const double chip = 30;
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: GoogleFonts.rajdhani().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryPurple,
      secondary: AppColors.secondaryOrange,
      surface: AppColors.surface,
      error: AppColors.dangerRed,
    ),
    textTheme: TextTheme(
      displayLarge: AppText.heading(size: 32),
      headlineMedium: AppText.heading(size: 20),
      bodyLarge: AppText.body(size: 16),
      bodyMedium: AppText.body(size: 14),
      bodySmall: AppText.caption(),
    ),
  );
}
