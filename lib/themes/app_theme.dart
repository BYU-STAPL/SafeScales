import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Light theme colors
Color blue = const Color(0xff2E83E8);
Color green = const Color(0xff0DB563);
Color orange = const Color(0xffF59E0B);
Color red = const Color(0xffD22626);

Color paleBlue = const Color(0xffDBEAFE);
Color paleGreen = const Color(0xffDCFCE7);
Color paleOrange = const Color(0xffFEF3C7);
Color paleRed = const Color(0xffFEE2E2);

Color darkBlue = const Color(0xff1E40AF);
Color darkGreen = const Color(0xff166534);
Color darkOrange = const Color(0xff92400E);
Color darkRed = const Color(0xff991B1B);

Color dimBlue = const Color(0xffBFDBFE);
Color dimGreen = const Color(0xffBBF7D0);
Color dimOrange = const Color(0xffFDE68A);

Color thickBlue = const Color(0xff3B82F6);
Color thickGreen = const Color(0xff059669);
Color thickOrange = const Color(0xffD97706);

Color white = const Color(0xffFFFFFF);
Color offWhite = const Color(0xffF5F5F5);
Color dimWhite = const Color(0xffF1F5F9);

Color grey = const Color(0xffAAAAAA);
Color dimGrey = const Color(0xffCCD1D8);
Color paleGrey = const Color(0xffE1E1E1);

// Color paleGrey = const Color(0xffF1F5F9);

Color almostBlack = const Color(0xff1A1A1A);
Color darkGreyBlue = const Color(0xff1E293B);
Color thickGreyBlue2 = const Color(0xff334155);
Color thickGreyBlue = const Color(0xff64748B);
Color greyBlue = const Color(0xff94A3B8);
Color paleGreyBlue = const Color(0xffCBD5E1);

Color lightBlue = const Color(0xff93C5FD);

// lor darkGrey = const Color(0xff888888);

// Dark theme colors
// Color darkRoyalBlue = const Color(0xff1E63B8);
Color darkLightRoyalBlue = const Color(0xff4A90E2);
Color darkDarkGrey = const Color(0xff666666);
Color darkGrey2 = const Color(0xff444444);
Color darkLightGrey = const Color(0xff2A2A2A);
Color darkOffWhite = const Color(0xff1A1A1A);
// Color darkGreen = const Color(0xff4A7A39);
// Color darkRed = const Color(0xff8A1A0A);

ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: blue,
  secondary: green,
  tertiary: orange,
  error: red,

  onPrimary: offWhite,
  onSecondary: offWhite,
  onTertiary: offWhite,
  onError: offWhite,

  primaryContainer: paleBlue,
  secondaryContainer: paleGreen,
  tertiaryContainer: paleOrange,
  errorContainer: paleRed,

  onPrimaryContainer: darkBlue,
  onSecondaryContainer: darkGreen,
  onTertiaryContainer: darkOrange,
  onErrorContainer: darkRed,

  primaryFixed: paleBlue,
  primaryFixedDim: dimBlue,
  secondaryFixed: paleGreen,
  secondaryFixedDim: dimGreen,
  tertiaryFixed: paleOrange,
  tertiaryFixedDim: dimOrange,

  onPrimaryFixed: darkBlue,
  onPrimaryFixedVariant: thickBlue,
  onSecondaryFixed: darkGreen,
  onSecondaryFixedVariant: thickGreen,
  onTertiaryFixed: darkOrange,
  onTertiaryFixedVariant: thickOrange,

  surfaceDim: dimWhite,
  surface: offWhite,
  surfaceBright: white,
  inverseSurface: thickGreyBlue2,

  onSurface: darkGreyBlue,
  onSurfaceVariant: thickGreyBlue,
  onInverseSurface: offWhite,

  outline: greyBlue,
  outlineVariant: paleGreyBlue,

  surfaceContainerLowest: white,
  surfaceContainerLow: offWhite,
  surfaceContainer: paleGrey,
  surfaceContainerHigh: dimGrey,
  surfaceContainerHighest: grey,

  scrim: almostBlack.withValues(alpha: 0.5),
  shadow: almostBlack,
);

ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: darkBlue,
  onPrimary: darkOffWhite,
  secondary: darkLightRoyalBlue,
  onSecondary: Colors.white,
  tertiary: darkGrey2,
  onTertiary: Colors.white,
  error: darkRed,
  onError: darkOffWhite,
  surface: darkOffWhite,
  onSurface: Colors.white,
  surfaceDim: darkLightGrey,
  surfaceContainer: darkLightGrey,
  onSurfaceVariant: darkGrey2,
  outline: darkDarkGrey,
  outlineVariant: darkGrey2,
  shadow: Colors.black,
  scrim: Colors.black.withValues(alpha: 0.5),
  // background: darkOffWhite,
  // onBackground: Colors.white,
);

class AppTheme {
  static double _fontSizeScale = 1.0;

  static void setFontSizeScale(double scale) {
    _fontSizeScale = scale;
  }

  static double get fontSizeScale => _fontSizeScale;

  static TextTheme getTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      headlineLarge: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 32 * _fontSizeScale,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 28 * _fontSizeScale,
        fontWeight: FontWeight.normal,
      ),
      headlineSmall: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 25 * _fontSizeScale,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 22 * _fontSizeScale,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 18 * _fontSizeScale,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 15 * _fontSizeScale,
        fontWeight: FontWeight.normal,
      ),
      labelMedium: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 18 * _fontSizeScale,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  static ThemeData buildLightAppTheme() {
    return ThemeData(
      // Color scheme
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: lightColorScheme.surface,

      // Typography
      textTheme: getTextTheme(lightColorScheme),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 25,
        titleTextStyle: TextStyle(
          color: lightColorScheme.primary,
          fontSize: 30 * _fontSizeScale,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: lightColorScheme.primary,
          size: 30 * _fontSizeScale,
        ),
        actionsIconTheme: IconThemeData(
          color: lightColorScheme.primary,
          size: 40 * _fontSizeScale,
        ),
        actionsPadding: EdgeInsets.only(right: 20),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: getTextTheme(lightColorScheme).labelMedium,
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: lightColorScheme.shadow,
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          iconColor: MaterialStateProperty.all(lightColorScheme.primary),
          shadowColor: MaterialStateProperty.all(lightColorScheme.shadow),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: lightColorScheme.surfaceDim,
        shadowColor: lightColorScheme.shadow,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightColorScheme.surface,
        selectedItemColor: lightColorScheme.primary,
        unselectedItemColor: lightColorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData buildDarkAppTheme() {
    return ThemeData(
      // Color scheme
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: darkColorScheme.surface,

      // Typography
      textTheme: getTextTheme(darkColorScheme),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 25,
        titleTextStyle: TextStyle(
          color: darkColorScheme.onSurface,
          fontSize: 30 * _fontSizeScale,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: darkColorScheme.onSurface,
          size: 30 * _fontSizeScale,
        ),
        actionsIconTheme: IconThemeData(
          color: darkColorScheme.onSurface,
          size: 40 * _fontSizeScale,
        ),
        actionsPadding: EdgeInsets.only(right: 20),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: getTextTheme(darkColorScheme).labelMedium,
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: darkColorScheme.shadow,
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          iconColor: WidgetStateProperty.all(darkColorScheme.primary),
          shadowColor: WidgetStateProperty.all(darkColorScheme.shadow),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: darkColorScheme.surfaceDim,
        shadowColor: darkColorScheme.shadow,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkColorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkColorScheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkColorScheme.surface,
        selectedItemColor: darkColorScheme.primary,
        unselectedItemColor: darkColorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
