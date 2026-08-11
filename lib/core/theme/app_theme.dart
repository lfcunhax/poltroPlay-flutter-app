import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.inter(color: AppColors.textSecondary),
        bodySmall: GoogleFonts.inter(color: AppColors.textMuted),
        labelLarge: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        labelMedium: GoogleFonts.inter(color: AppColors.textSecondary),
        labelSmall: GoogleFonts.inter(color: AppColors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );
  }
}
