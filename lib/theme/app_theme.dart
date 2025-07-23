import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class AppTheme {
  // Ana renkler - Daha elegant renk paleti
  static const Color primaryColor = Color(0xFF3F51B5); // Indigo
  static const Color accentColor = Color(0xFF5C6BC0);  // Light Indigo
  static const Color secondaryColor = Color(0xFF9FA8DA); // Even lighter Indigo
  static const Color backgroundColor = Color(0xFFF8F9FA); // Very light gray with blue hint
  static const Color cardShadowColor = Color(0xFFE0E0E0); // Light gray
  static const Color textPrimaryColor = Color(0xFF212121); // Very dark gray
  static const Color textSecondaryColor = Color(0xFF757575); // Medium gray
  
  // Ek renkler
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white
  static const Color errorColor = Color(0xFFE53935); // Red for errors
  static const Color successColor = Color(0xFF43A047); // Green for success
  static const Color infoColor = Color(0xFF4299E1); // Info blue
  static const Color warningColor = Color(0xFFECC94B); // Warning yellow
  static const Color dividerColor = Color(0xFFEEEEEE); // Light gray for dividers
  
  // Gradient renkleri - Daha elegant ve yumuşak geçişler
  static List<Color> blueGradient = [
    const Color(0xFF3949AB), // Darker Indigo
    const Color(0xFF5C6BC0), // Lighter Indigo
  ];
  
  static List<Color> greenGradient = [
    const Color(0xFF2E7D32), // Dark Green
    const Color(0xFF66BB6A), // Light Green
  ];
  
  static List<Color> purpleGradient = [
    const Color(0xFF5E35B1), // Dark Purple
    const Color(0xFF7E57C2), // Light Purple
  ];
  
  static List<Color> amberGradient = [
    const Color(0xFFFF8F00), // Dark Amber
    const Color(0xFFFFB74D), // Light Amber
  ];

  // Modern subtle gradients for cards
  static List<Color> subtleBlueGradient = [
    const Color(0xFFE8EAF6), // Very light Indigo
    const Color(0xFFC5CAE9), // Light Indigo
  ];

  static List<Color> subtleGreenGradient = [
    const Color(0xFFE8F5E9), // Very light Green
    const Color(0xFFC8E6C9), // Light Green
  ];
  
  // Light tema
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: primaryColor),
      titleTextStyle: TextStyle(
        color: textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 4,
      shadowColor: cardShadowColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: textPrimaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: textSecondaryColor,
        fontSize: 12,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: primaryColor,
      secondary: accentColor,
    ),
  );

  // Metin renkleri
  static const Color textLightColor = Color(0xFFFAFAFA); // Beyaz

  // Arka plan varyasyonları
  static const Color backgroundVariant1 = Color(0xFFEBF4FF); // Açık mavi
  static const Color backgroundVariant2 = Color(0xFFFFF9EB); // Açık amber

  // Kart renkleri
  static const Color cardColor = Color(0xFFFFFFFF); // Beyaz

  // darkTheme ve karanlık mod ile ilgili kodlar kaldırıldı
}

// Renk tonu koyulaştırma uzantısı
extension ColorExtension on Color {
  Color darker(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(
      alpha,
      (red * value).round(),
      (green * value).round(),
      (blue * value).round(),
    );
  }

  Color lighter(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = 1 + percent / 100;
    return Color.fromARGB(
      alpha,
      math.min(255, (red * value).round()),
      math.min(255, (green * value).round()),
      math.min(255, (blue * value).round()),
    );
  }
}
