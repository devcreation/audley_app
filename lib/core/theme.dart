import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mirrors the website's CSS custom properties:
///   --teal: #4d726d  --gold: #c8a04e  --charcoal: #1a1a1a
///   --bg: #f3f1ee    --bg-warm: #faf8f5
class AppTheme {
  AppTheme._();

  // ─── Palette ──────────────────────────────────────────────
  static const Color teal = Color(0xFF4D726D);
  static const Color tealDark = Color(0xFF3A5955);
  static const Color tealLight = Color(0xFF6A9E97);
  static const Color gold = Color(0xFFC8A04E);
  static const Color goldLight = Color(0xFFDAB96A);
  static const Color goldDark = Color(0xFFA6833A);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color textColor = Color(0xFF3D3D3D);
  static const Color textMid = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color bgColor = Color(0xFFF3F1EE);
  static const Color bgWarm = Color(0xFFFAF8F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD6D9DC);

  // Dark mode palette
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF2A2A2A);

  // ─── Light Theme ──────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'SourceSans3',
    colorScheme: const ColorScheme.light(
      primary: teal,
      primaryContainer: tealLight,
      secondary: gold,
      secondaryContainer: goldLight,
      surface: white,
      error: Color(0xFFD32F2F),
      onPrimary: white,
      onSecondary: charcoal,
      onSurface: textColor,
    ),
    scaffoldBackgroundColor: bgColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: teal,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontFamily: 'SourceSans3',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: white,
      ),
    ),
    cardTheme: CardThemeData(
      color: white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: teal,
        foregroundColor: white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontFamily: 'SourceSans3',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: teal,
        side: const BorderSide(color: teal),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: teal, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: teal,
      unselectedItemColor: textLight,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: bgWarm,
      selectedColor: teal,
      labelStyle: const TextStyle(fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  // ─── Dark Theme ───────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'SourceSans3',
    colorScheme: const ColorScheme.dark(
      primary: tealLight,
      primaryContainer: tealDark,
      secondary: goldLight,
      secondaryContainer: goldDark,
      surface: darkCard,
      error: Color(0xFFEF5350),
      onPrimary: charcoal,
      onSecondary: charcoal,
      onSurface: Color(0xFFE0E0E0),
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Color(0xFFE0E0E0),
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontFamily: 'SourceSans3',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE0E0E0),
      ),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tealLight,
        foregroundColor: charcoal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF444444)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF444444)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: tealLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: tealLight,
      unselectedItemColor: Color(0xFF888888),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme:
        const DividerThemeData(color: Color(0xFF333333), thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: darkCard,
      selectedColor: tealDark,
      labelStyle: const TextStyle(fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
