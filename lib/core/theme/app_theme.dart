import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme Palette
  static const lPrimary = Color(0xFF96A78D);
  static const lSecondary = Color(0xFFB6CEB4);
  static const lAccent = Color(0xFFD9E9CF);
  static const lBackground = Color(0xFFF0F0F0);
  
  // Dark Theme Palette
  static const dBackground = Color(0xFF091413);
  static const dPrimary = Color(0xFF285A48);
  static const dSecondary = Color(0xFF408A71);
  static const dAccent = Color(0xFFB0E4CC);

  // Aliases for compatibility with existing code
  static const primaryColor = lPrimary;
  static const secondaryColor = lSecondary;
  static const accentColor = lAccent;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: lPrimary,
      primary: lPrimary,
      onPrimary: Colors.white,
      secondary: lSecondary,
      tertiary: lAccent,
      surface: lBackground,
    ),
    textTheme: GoogleFonts.outfitTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: lPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: lPrimary),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: lPrimary,
      labelStyle: const TextStyle(color: Colors.black),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: dPrimary,
      brightness: Brightness.dark,
      primary: dPrimary,
      onPrimary: Colors.white,
      secondary: dSecondary,
      tertiary: dAccent,
      surface: dBackground,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: dAccent, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: dAccent),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF152221), 
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: dPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF152221),
      selectedColor: dPrimary,
      labelStyle: const TextStyle(color: Colors.white),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
