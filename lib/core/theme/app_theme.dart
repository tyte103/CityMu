import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Refined Clean & Minimalist Light Theme following modern aesthetic principles.
abstract final class AppTheme {
  // Pure Minimalist Light Palette
  static const Color backgroundLight = Color(0xFFF8FAFC); // Soft cool white / slate-50
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white cards
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFE2E8F0); // Subtle slate-200 border
  static const Color cardBorderHover = Color(0xFFCBD5E1);

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900 high contrast
  static const Color textSecondary = Color(0xFF475569); // Slate-600 body
  static const Color textTertiary = Color(0xFF94A3B8); // Slate-400 subtle

  // Curated Minimalist Zone Accent Tones
  static const Color primaryBlue = Color(0xFF2563EB); // Royal Blue accent
  static const Color mrtZoneBlue = Color(0xFF0284C7); // Metro Sky Blue
  static const Color parkZoneGreen = Color(0xFF16A34A); // Forest Sage Green
  static const Color waterZoneCyan = Color(0xFF0D9488); // River Teal
  static const Color techZoneAmber = Color(0xFFD97706); // Amber Warmth
  static const Color residentialPurple = Color(0xFF7C3AED); // Urban Lavender

  // Subtle functional colors
  static const Color activeGreen = Color(0xFF10B981);
  static const Color chipBackground = Color(0xFFF1F5F9); // Slate-100

  /// Main Minimalist Light Theme
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: parkZoneGreen,
        surface: surfaceLight,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: cardBorderLight,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.6,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: textTertiary,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: textPrimary,
        ),
        labelSmall: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: textTertiary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorderLight, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorderLight,
        thickness: 1,
        space: 24,
      ),
    );
  }

  /// Optional Dark theme (kept clean and muted for compatibility)
  static ThemeData get darkTheme => lightTheme;
}
