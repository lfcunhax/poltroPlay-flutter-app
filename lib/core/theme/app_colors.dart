import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF16213E);
  
  static const Color primary = Color(0xFF7B2FF7);
  static const Color primaryLight = Color(0xFF9D5CFF);
  
  static const Color accent = Color(0xFF00D4FF);
  static const Color accentAlt = Color(0xFFE94560);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF6C6C6C);
  
  static Color cardBackground = const Color(0xFF1A1A2E).withValues(alpha: 0.8);
  
  static const Color shimmerBase = Color(0xFF1A1A2E);
  static const Color shimmerHighlight = Color(0xFF2A2A4E);
  
  static const Color ratingStar = Color(0xFFFFD700);
  
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.amber;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
