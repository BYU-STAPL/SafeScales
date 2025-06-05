import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/* Color Library */

// For AuthScreen Gradiant and other
Color lightBlue = const Color(0xff93C5FD);

// Light Mode = Main Colors
Color blue = const Color(0xff2E83E8);
Color green = const Color(0xff0DB563);
Color orange = const Color(0xffF59E0B);
Color red = const Color(0xffD22626);

// Dark Mode = Main Colors
Color dmBlue = const Color(0xff60A5FA);
Color dmGreen = const Color(0xff4ADE80);
Color dmOrange = const Color(0xffFBBF24);
Color dmRed = const Color(0xffF87171);

// Light Mode = Container
// Dark Mode = On Primary Container & On Primary Fixed
Color paleBlue = const Color(0xffDBEAFE);
Color paleGreen = const Color(0xffDCFCE7);
Color paleOrange = const Color(0xffFEF3C7);
Color paleRed = const Color(0xffFEE2E2);

// Dark Mode = Primary Container & Primary Fixed
Color dmDarkBlue = const Color(0xff1E3A8A);
Color dmDarkGreen = const Color(0xff14532D);
Color dmDarkOrange = const Color(0xff78350F);
Color dmDarkRed = const Color(0xff7F1D1D);

// Light Mode = On Primary Container & On Primary Fixed
// Dark Mode = On Primary & Primary Fixed Dim
Color darkBlue = const Color(0xff1E40AF);
Color darkGreen = const Color(0xff166534);
Color darkOrange = const Color(0xff92400E);
Color darkRed = const Color(0xff991B1B);

// Light Mode = Primary Fixed Dim
// Dark Mode = On Primary Fixed Variant
Color dimBlue = const Color(0xffBFDBFE);
Color dimGreen = const Color(0xffBBF7D0);
Color dimOrange = const Color(0xffFDE68A);

// Light Mode = On Primary Fixed Variant
Color thickBlue = const Color(0xff3B82F6);
Color thickGreen = const Color(0xff059669);
Color thickOrange = const Color(0xffD97706);

// Color white = const Color(0xffFFFFFF);
Color offWhite = const Color(0xffF5F5F5);
// Color dimWhite = const Color(0xffF1F5F9);
//
// Color grey = const Color(0xffAAAAAA);
// Color dimGrey = const Color(0xffCCD1D8);
// Color paleGrey = const Color(0xffE1E1E1);
//
// Color almostBlack = const Color(0xff1A1A1A);
// Color thickGreyBlue = const Color(0xff64748B);
// Color greyBlue = const Color(0xff94A3B8);
// Color paleGreyBlue = const Color(0xffCBD5E1);
//
//
// // Light Mode = On Surface
// // Dark Mode = Surface & Surface Container low
// Color darkGreyBlue = const Color(0xff1E293B);
//
// // Light Mode = Inverse Surface
// // Dark Mode = Surface Bright & Surface Container
// Color thickGreyBlue2 = const Color(0xff334155);


// Light Mode Surface Colors
Color lmSurfaceDim = const Color(0xffF1F5F9);
Color lmSurface = const Color(0xffF5F5F5);
Color lmSurfaceBright = const Color(0xffFFFFFF);
Color lmInverseSurface = const Color(0xff334155);

Color lmSurfaceContainerLowest = const Color(0xffFFFFFF);
Color lmSurfaceContainerLow = const Color(0xffF5F5F5);
Color lmSurfaceContainer = const Color(0xffE1E1E1);
Color lmSurfaceContainerHigh = const Color(0xffCCD1D8);
Color lmSurfaceContainerHighest = const Color(0xffAAAAAA);

Color lmInverseOnSurface = const Color(0xffF5F5F5);
Color lmInversePrimary = const Color(0xff93C5FD);

Color lmOnSurface = const Color(0xff1E293B);
Color lmOnSurfaceVariant = const Color(0xff64748B);
Color lmOutline = const Color(0xff94A3B8);
Color lmOutlineVariant = const Color(0xffCBD5E1);

Color lmScrim = const Color(0xff1A1A1A).withValues(alpha: 0.5);
Color lmShadow = const Color(0xff1A1A1A);




// Dark Mode Surface Colors
Color dmSurfaceDim = const Color(0xff0F172A);
Color dmSurface = const Color(0xff1E293B);
Color dmSurfaceBright = const Color(0xff334155);
Color dmInverseSurface = const Color(0xffF1F5F9);

Color dmSurfaceContainerLowest = const Color(0xff0C1220);
Color dmSurfaceContainerLow = const Color(0xff1E293B);
Color dmSurfaceContainer = const Color(0xff334155);
Color dmSurfaceContainerHigh = const Color(0xff475569);
Color dmSurfaceContainerHighest = const Color(0xff64748B);

Color dmInverseOnSurface = const Color(0xffF1F5F9);
Color dmInversePrimary = const Color(0xff1E3A8A);

Color dmOnSurface = const Color(0xffF1F5F9);
Color dmOnSurfaceVariant = const Color(0xffCBD5E1);
Color dmOutline = const Color(0xff64748B);
Color dmOutlineVariant = const Color(0xff475569);

Color dmScrim = const Color(0xff000000);
Color dmShadow = const Color(0xff000000);



// Dark theme colors
// Color darkLightRoyalBlue = const Color(0xff4A90E2);
// Color darkDarkGrey = const Color(0xff666666);
// Color darkGrey2 = const Color(0xff444444);
// Color darkLightGrey = const Color(0xff2A2A2A);
// Color darkOffWhite = const Color(0xff1A1A1A);
// // Color darkGreen = const Color(0xff4A7A39);
// // Color darkRed = const Color(0xff8A1A0A);

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

  surfaceDim: lmSurfaceDim,
  surface: lmSurface,
  surfaceBright: lmSurfaceBright,
  inverseSurface: lmInverseSurface,

  onSurface: lmOnSurface,
  onSurfaceVariant: lmOnSurfaceVariant,
  onInverseSurface: lmInverseOnSurface,

  outline: lmOutline,
  outlineVariant: lmOutlineVariant,

  surfaceContainerLowest: lmSurfaceContainerLowest,
  surfaceContainerLow: lmSurfaceContainerLow,
  surfaceContainer: lmSurfaceContainer,
  surfaceContainerHigh: lmSurfaceContainerHigh,
  surfaceContainerHighest: lmSurfaceContainerHighest,

  scrim: lmScrim,
  shadow: lmShadow,
);

/* Dark Mode Color Scheme */
ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: dmBlue,
  secondary: dmGreen,
  tertiary: dmOrange,
  error: dmRed,

  onPrimary: darkBlue,
  onSecondary: darkGreen,
  onTertiary: darkOrange,
  onError: darkRed,

  primaryContainer: dmDarkBlue,
  secondaryContainer: dmDarkGreen,
  tertiaryContainer: dmDarkOrange,
  errorContainer: dmDarkGreen,

  onPrimaryContainer: paleBlue,
  onSecondaryContainer: paleGreen,
  onTertiaryContainer: paleOrange,
  onErrorContainer: paleRed,

  primaryFixed: dmDarkBlue,
  primaryFixedDim: darkBlue,
  secondaryFixed: dmDarkGreen,
  secondaryFixedDim: darkGreen,
  tertiaryFixed: dmDarkOrange,
  tertiaryFixedDim: darkOrange,

  onPrimaryFixed: paleBlue,
  onPrimaryFixedVariant: dimBlue,
  onSecondaryFixed: paleGreen,
  onSecondaryFixedVariant: dimBlue,
  onTertiaryFixed: paleOrange,
  onTertiaryFixedVariant: dimBlue,

  surfaceDim: dmSurfaceDim,
  surface: dmSurface,
  surfaceBright: dmSurfaceBright,
  inverseSurface: dmInverseSurface,

  onSurface: dmOnSurface,
  onSurfaceVariant: dmOnSurfaceVariant,
  onInverseSurface: dmInverseOnSurface,

  outline: dmOutline,
  outlineVariant: dmOutlineVariant,

  surfaceContainerLowest: dmSurfaceContainerLowest,
  surfaceContainerLow: dmSurfaceContainerLow,
  surfaceContainer: dmSurfaceContainer,
  surfaceContainerHigh: dmSurfaceContainerHigh,
  surfaceContainerHighest: dmSurfaceContainerHighest,

  scrim: dmScrim,
  shadow: dmShadow,
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
