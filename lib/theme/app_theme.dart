import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ==================== الألوان الأساسية الثابتة ====================

  // Dark Mode Colors
  static const Color darkBgDefault = Color(0xFF0B0B0C);
  static const Color darkSurfacePrimary = Color(0xFF1C1C1E);
  static const Color darkSurfaceSecondary = Color(0xFF2C2C2E);
  static const Color darkSurfaceTertiary = Color(0xFF3A3A3C);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);

  // Light Mode Colors
  static const Color lightBgDefault = Color(0xFFF5F5F5);
  static const Color lightSurfacePrimary = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF0F0F0);
  static const Color lightSurfaceTertiary = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);

  // Common Colors (ثابتة لكل الثيمات)
  static const Color accentDefault = Color(0xFFE52E36);
  static const Color accentPressed = Color(0xFFB11B22);
  static const Color successGreen = Color(0xFF00B884);
  static const Color warningAmber = Color(0xFFFFB800);
  static const Color infoBlue = Color(0xFF00A8E8);

  // ==================== متغيرات الوضع الداكن (الافتراضي) ====================
  // دي المتغيرات اللي بتستخدم في كل مكان في التطبيق
  // وهي static const عشان تقدر تتعامل مع const widgets

  static const Color bgDefault = darkBgDefault;
  static const Color surfacePrimary = darkSurfacePrimary;
  static const Color surfaceSecondary = darkSurfaceSecondary;
  static const Color surfaceTertiary = darkSurfaceTertiary;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;

  // ==================== دوال الثيمات ====================

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBgDefault,
      colorScheme: const ColorScheme.dark(
        surface: darkBgDefault,
        primary: accentDefault,
        secondary: successGreen,
        onPrimary: darkTextPrimary,
        onSurface: darkTextPrimary,
      ),
      textTheme: GoogleFonts.cairoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
              color: darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 32),
          displayMedium: TextStyle(
              color: darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 24),
          displaySmall: TextStyle(
              color: darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 20),
          headlineMedium: TextStyle(
              color: darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: TextStyle(
              color: darkTextPrimary, fontWeight: FontWeight.w400, fontSize: 16),
          bodyMedium: TextStyle(
              color: darkTextSecondary, fontWeight: FontWeight.w400, fontSize: 14),
          labelLarge: TextStyle(
              color: darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 16),
          labelSmall: TextStyle(
              color: darkTextSecondary, fontWeight: FontWeight.w400, fontSize: 12),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBgDefault,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentDefault,
          foregroundColor: darkTextPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkSurfaceTertiary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentDefault, width: 1.5),
        ),
        labelStyle: GoogleFonts.cairo(color: darkTextSecondary, fontSize: 14),
        hintStyle: GoogleFonts.cairo(color: darkTextSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: darkSurfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurfacePrimary,
        selectedItemColor: accentDefault,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBgDefault,
      colorScheme: const ColorScheme.light(
        surface: lightBgDefault,
        primary: accentDefault,
        secondary: successGreen,
        onPrimary: lightTextPrimary,
        onSurface: lightTextPrimary,
      ),
      textTheme: GoogleFonts.cairoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
              color: lightTextPrimary, fontWeight: FontWeight.w700, fontSize: 32),
          displayMedium: TextStyle(
              color: lightTextPrimary, fontWeight: FontWeight.w700, fontSize: 24),
          displaySmall: TextStyle(
              color: lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 20),
          headlineMedium: TextStyle(
              color: lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: TextStyle(
              color: lightTextPrimary, fontWeight: FontWeight.w400, fontSize: 16),
          bodyMedium: TextStyle(
              color: lightTextSecondary, fontWeight: FontWeight.w400, fontSize: 14),
          labelLarge: TextStyle(
              color: lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 16),
          labelSmall: TextStyle(
              color: lightTextSecondary, fontWeight: FontWeight.w400, fontSize: 12),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurfacePrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentDefault,
          foregroundColor: lightTextPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightSurfaceTertiary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentDefault, width: 1.5),
        ),
        labelStyle: GoogleFonts.cairo(color: lightTextSecondary, fontSize: 14),
        hintStyle: GoogleFonts.cairo(color: lightTextSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: lightSurfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurfacePrimary,
        selectedItemColor: accentDefault,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // الثيم الافتراضي (للتأكد من عدم وجود أخطاء)
  static ThemeData get theme => darkTheme;
}