import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CatalogueTheme {
  CatalogueTheme._();

  static const terracotta = Color(0xFFA33E20);
  static const terracottaHover = Color(0xFF983C22);
  static const green = Color(0xFF5FA443);
  static const cream = Color(0xFFFBF5EB);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF242020);
  static const muted = Color(0xFF77716D);
  static const border = Color(0xFFE9E2D9);
  static const softGreen = Color(0xFFEDF4E8);

  static ThemeData light() {
    final text = GoogleFonts.montserratTextTheme().apply(bodyColor: ink, displayColor: ink);
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: const ColorScheme.light(
        primary: terracotta,
        secondary: green,
        surface: white,
        onPrimary: white,
        onSurface: ink,
      ),
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        indicatorColor: softGreen,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: ink),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: ink),
        hintStyle: GoogleFonts.montserrat(color: muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: terracotta, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: terracotta)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: terracotta,
          foregroundColor: white,
          minimumSize: const Size(44, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(44, 48),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
      dividerColor: border,
      splashFactory: InkRipple.splashFactory,
    );
  }
}
