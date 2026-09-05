import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Askesis Art Fest '26 Color Palette
  static const Color cream = Color(0xFFF2ECDC);
  static const Color cream2 = Color(0xFFEAE2CC);
  static const Color ink = Color(0xFF241A12);
  static const Color inkSoft = Color(0xFF5A4E3F);
  static const Color red = Color(0xFF9C2B22);
  static const Color redDeep = Color(0xFF6E1E18);
  static const Color olive = Color(0xFF6E7B3D);
  static const Color mustard = Color(0xFFD7A233);
  static const Color green = Color(0xFF43593F);
  static const Color wood = Color(0xFF2B2119);
  static const Color line = Color(0x24241A12); // rgba(36,26,18,0.14)

  // Standard theme mappings for compatibility
  static const Color primaryColor = red;
  static const Color secondaryColor = olive;
  static const Color accentGold = mustard;
  static const Color darkBackground = wood;
  static const Color darkSurface = Color(0xFF1E1712);
  static const Color lightBackground = cream;
  static const Color lightSurface = cream2;

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.workSansTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: red,
      scaffoldBackgroundColor: cream,
      colorScheme: const ColorScheme.light(
        primary: red,
        secondary: olive,
        surface: cream2,
        error: Colors.redAccent,
        onPrimary: cream,
        onSurface: ink,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.rye(color: ink, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.rye(color: ink, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.rye(color: ink, fontSize: 22, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.rye(color: ink, fontSize: 20, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.rye(color: ink, fontSize: 18, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.workSans(color: ink, fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: GoogleFonts.workSans(color: ink, fontSize: 14),
        bodyMedium: GoogleFonts.workSans(color: inkSoft, fontSize: 13),
      ),
      cardTheme: CardThemeData(
        color: cream2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: line),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: ink),
        titleTextStyle: GoogleFonts.rye(color: ink, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cream,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: red, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        hintStyle: GoogleFonts.workSans(color: const Color(0xFF8A7E6C), fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: red,
          foregroundColor: cream,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.workSans(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cream,
        selectedColor: red,
        secondarySelectedColor: red,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: GoogleFonts.workSans(color: ink, fontWeight: FontWeight.w700, fontSize: 12),
        secondaryLabelStyle: GoogleFonts.workSans(color: cream, fontWeight: FontWeight.w700, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ink, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    // For dark pages like Login Screen or TV view in dark mode
    final baseTextTheme = GoogleFonts.workSansTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: cream,
      displayColor: cream,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: red,
      scaffoldBackgroundColor: wood,
      colorScheme: const ColorScheme.dark(
        primary: red,
        secondary: mustard,
        surface: Color(0xFF1E1712),
        error: Colors.redAccent,
        onPrimary: cream,
        onSurface: cream,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.rye(color: cream, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.rye(color: cream, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.rye(color: cream, fontSize: 22, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.rye(color: cream, fontSize: 20, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.rye(color: cream, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: cream,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide.none,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: wood,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: cream),
        titleTextStyle: GoogleFonts.rye(color: cream, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
