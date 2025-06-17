import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Updated color palette for a lighter, modern video player theme
  static const Color primaryColor = Color(0xFF00695C); // Teal for text/icons
  static const Color accentColor = Color(0xFF26A69A); // Light teal for buttons/highlights
  static const Color backgroundColor = Color(0xFFF5F5F5); // Soft gray background
  static const Color cardColor = Color(0xFFFFFFFF); // White for cards
  static const Color textColor = Color(0xFF212121); // Dark gray text
  static const Color secondaryColor = Color(0xFFB0BEC5); // Light gray for secondary accents
  static const Color highlightColor = Color(0xFF80CBC4); // Light teal for highlights
  static const Color surfaceColor = Color(0xFFFFFFFF); // White for surfaces (nav bar)
  static const Color gradientStart = Color(0xFFE0F2F1); // Very light teal gradient start
  static const Color gradientEnd = Color(0xFFF5F5F5); // Soft gray gradient end
  static const Color mintColor = Color(0xFF26A69A); // Light teal for accents
  static const Color borderColor = Color(0xFFE0E0E0); // Light gray for borders

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
        onBackground: textColor,
        tertiary: secondaryColor,
        onTertiary: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textColor, size: 24),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Reduced radius
            side: const BorderSide(color: borderColor, width: 1),
          ),
          elevation: 3,
          shadowColor: accentColor.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Reduced radius
          side: const BorderSide(color: borderColor, width: 1),
        ),
        color: cardColor,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      sliderTheme: SliderThemeData(
        thumbColor: accentColor,
        activeTrackColor: accentColor,
        inactiveTrackColor: secondaryColor,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayColor: accentColor.withOpacity(0.2),
        trackHeight: 4,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          color: textColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.poppins(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.poppins(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        bodyLarge: GoogleFonts.poppins(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        bodyMedium: GoogleFonts.poppins(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        labelLarge: GoogleFonts.poppins(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryColor,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Reduced radius
          side: const BorderSide(color: borderColor, width: 1),
        ),
        backgroundColor: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: secondaryColor,
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Reduced radius
          side: const BorderSide(color: borderColor, width: 1),
        ),
        elevation: 2,
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return Colors.grey[300];
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentColor;
          }
          return Colors.grey[400];
        }),
      ),
    );
  }

  // Subtle gradient for cards
  static LinearGradient get cardGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF), // White
          Color(0xFFE0F2F1), // Very light teal
        ],
        stops: [0.0, 1.0],
      );

  // Teal gradient for featured cards
  static LinearGradient get featuredCardGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF80CBC4), // Light teal
          Color(0xFF26A69A), // Teal
        ],
        stops: [0.0, 1.0],
      );

  // Teal gradient for accent cards
  static LinearGradient get accentCardGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF26A69A), // Light teal
          Color(0xFF00695C), // Teal
        ],
        stops: [0.0, 1.0],
      );

  // Dark teal gradient for primary elements
  static LinearGradient get darkGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF00695C), // Teal
          Color(0xFF004D40), // Darker teal
        ],
        stops: [0.0, 1.0],
      );

  // Light gradient for backgrounds
  static LinearGradient get lightGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE0F2F1), // Very light teal
          Color(0xFFF5F5F5), // Soft gray
        ],
        stops: [0.0, 1.0],
      );
}