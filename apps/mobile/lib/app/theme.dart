import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const limeGreen = Color(0xFF7ED321);
  static const darkBackground = Color(0xFF0E0E0E);
  static const lightBackground = Color(0xFFF8F9FA);
  static const redAccent = Color(0xFFFF4B4B);
  
  // Digital Curator (Light Theme)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: limeGreen,
        secondary: Colors.black,
        surface: Colors.white,
        background: lightBackground,
        error: redAccent,
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.black),
        displayMedium: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.black),
        titleLarge: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: Colors.black),
        bodyLarge: GoogleFonts.inter(color: Colors.black87),
        bodyMedium: GoogleFonts.inter(color: Colors.black87),
        labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: limeGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: limeGreen, width: 2),
        ),
      ),
    );
  }

  // Neon Guardian (Dark Theme)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: limeGreen,
        secondary: Colors.white,
        surface: const Color(0xFF1E1E1E),
        background: darkBackground,
        error: redAccent,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.inter(color: Colors.white70),
        bodyMedium: GoogleFonts.inter(color: Colors.white70),
        labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: limeGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: limeGreen, width: 2),
        ),
      ),
    );
  }
}
