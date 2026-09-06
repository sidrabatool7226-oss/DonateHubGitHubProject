import 'package:flutter/material.dart';

class AppTheme {
  // Existing DonateHub brand green — preserved exactly as-is (same
  // seed used in the original GetMaterialApp theme).
  static const Color brandGreen = Color(0xFF2D6A4F);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandGreen,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
      ),
      cardColor: Colors.white,
      dialogBackgroundColor: Colors.white,
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white),
    );
  }

  // Material Design recommended dark surfaces — NOT pure black (#121212
  // scaffold, #1E1E1E cards/surfaces), which is the professional standard
  // used by Google apps and avoids harsh contrast/OLED smearing issues.
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandGreen,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: const Color(0xFF1E1E1E),
      dialogBackgroundColor: const Color(0xFF1E1E1E),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Color(0xFF1E1E1E)),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white.withOpacity(0.87),
        displayColor: Colors.white.withOpacity(0.87),
      ),
    );
  }
}