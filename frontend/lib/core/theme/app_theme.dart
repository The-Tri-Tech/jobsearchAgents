import 'package:flutter/material.dart';

class AppTheme {
  // SkillBridge Palette
  static const Color background = Color(0xFFF9FAFB);
  static const Color sidebarBackground = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFEAECF0);
  
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textMuted = Color(0xFF98A2B3);

  static const Color activeNavBackground = Color(0xFFF2F4F7);
  static const Color activeNavText = Color(0xFF101828);

  static const Color pillButtonBorder = Color(0xFFD0D5DD);
  static const Color pillButtonText = Color(0xFF344054);
  
  static const Color iconContainerBackground = Color(0xFFF2F4F7);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF101828),
        surface: cardBackground,
      ),
      fontFamily: 'Inter',
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
    );
  }
}
