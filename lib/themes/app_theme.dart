import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/* Color Library */

// Base color definitions organized by category
class AppColors {
  // Universal colors (used in both themes)
  static const Color lightBlue = Color(0xff93C5FD);
  static const Color offWhite = Color(0xffF5F5F5);

  // Pale colors (used in both themes)
  static const Color paleBlue = Color(0xffDBEAFE);
  static const Color paleGreen = Color(0xffDCFCE7);
  static const Color paleOrange = Color(0xffFEF3C7);
  static const Color paleRed = Color(0xffFEE2E2);

  // Light mode main colors
  static const Color blue = Color(0xff2E83E8);
  static const Color green = Color(0xff0DB563);
  static const Color orange = Color(0xffF59E0B);
  static const Color red = Color(0xffD22626);

  // Dark mode main colors
  static const Color dmBlue = Color(0xff60A5FA);
  static const Color dmGreen = Color(0xff4ADE80);
  static const Color dmOrange = Color(0xffFBBF24);
  static const Color dmRed = Color(0xffF87171);

  // Dark variants (used in both themes)
  static const Color darkBlue = Color(0xff1E40AF);
  static const Color darkGreen = Color(0xff166534);
  static const Color darkOrange = Color(0xff92400E);
  static const Color darkRed = Color(0xff991B1B);

  // Dark mode container colors
  static const Color dmDarkBlue = Color(0xff1E3A8A);
  static const Color dmDarkGreen = Color(0xff14532D);
  static const Color dmDarkOrange = Color(0xff78350F);
  static const Color dmDarkRed = Color(0xff7F1D1D);

  // Dim colors
  static const Color dimBlue = Color(0xffBFDBFE);
  static const Color dimGreen = Color(0xffBBF7D0);
  static const Color dimOrange = Color(0xffFDE68A);

  // Thick colors
  static const Color thickBlue = Color(0xff3B82F6);
  static const Color thickGreen = Color(0xff059669);
  static const Color thickOrange = Color(0xffD97706);

  // Light mode surface colors
  static const Color lmSurfaceDim = Color(0xffF1F5F9);
  static const Color lmSurface = Color(0xffF5F5F5);
  static const Color lmSurfaceBright = Color(0xffFFFFFF);
  static const Color lmInverseSurface = Color(0xff334155);
  static const Color lmSurfaceContainerLowest = Color(0xffFFFFFF);
  static const Color lmSurfaceContainerLow = Color(0xffF5F5F5);
  static const Color lmSurfaceContainer = Color(0xffE1E1E1);
  static const Color lmSurfaceContainerHigh = Color(0xffCCD1D8);
  static const Color lmSurfaceContainerHighest = Color(0xffAAAAAA);
  static const Color lmInverseOnSurface = Color(0xffF5F5F5);
  static const Color lmInversePrimary = Color(0xff93C5FD);
  static const Color lmOnSurface = Color(0xff1E293B);
  static const Color lmOnSurfaceVariant = Color(0xff64748B);
  static const Color lmOutline = Color(0xff94A3B8);
  static const Color lmOutlineVariant = Color(0xffCBD5E1);
  static final Color lmScrim = const Color(0xff1A1A1A).withValues(alpha: 0.5);
  static const Color lmShadow = Color(0xff1A1A1A);

  // Dark mode surface colors
  static const Color dmSurfaceDim = Color(0xff0F172A);
  static const Color dmSurface = Color(0xff1E293B);
  static const Color dmSurfaceBright = Color(0xff334155);
  static const Color dmInverseSurface = Color(0xffF1F5F9);
  static const Color dmSurfaceContainerLowest = Color(0xff0C1220);
  static const Color dmSurfaceContainerLow = Color(0xff1E293B);
  static const Color dmSurfaceContainer = Color(0xff334155);
  static const Color dmSurfaceContainerHigh = Color(0xff475569);
  static const Color dmSurfaceContainerHighest = Color(0xff64748B);
  static const Color dmInverseOnSurface = Color(0xff334155);
  static const Color dmInversePrimary = Color(0xff1E3A8A);
  static const Color dmOnSurface = Color(0xffF1F5F9);
  static const Color dmOnSurfaceVariant = Color(0xffCBD5E1);
  static const Color dmOutline = Color(0xff64748B);
  static const Color dmOutlineVariant = Color(0xff475569);
  static const Color dmScrim = Color(0xff000000);
  static const Color dmShadow = Color(0xff000000);
}

// ColorScheme definitions
final ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.blue,
  secondary: AppColors.green,
  tertiary: AppColors.orange,
  error: AppColors.red,

  onPrimary: AppColors.offWhite,
  onSecondary: AppColors.offWhite,
  onTertiary: AppColors.offWhite,
  onError: AppColors.offWhite,

  primaryContainer: AppColors.paleBlue,
  secondaryContainer: AppColors.paleGreen,
  tertiaryContainer: AppColors.paleOrange,
  errorContainer: AppColors.paleRed,

  onPrimaryContainer: AppColors.darkBlue,
  onSecondaryContainer: AppColors.darkGreen,
  onTertiaryContainer: AppColors.darkOrange,
  onErrorContainer: AppColors.darkRed,

  primaryFixed: AppColors.paleBlue,
  primaryFixedDim: AppColors.dimBlue,
  secondaryFixed: AppColors.paleGreen,
  secondaryFixedDim: AppColors.dimGreen,
  tertiaryFixed: AppColors.paleOrange,
  tertiaryFixedDim: AppColors.dimOrange,

  onPrimaryFixed: AppColors.darkBlue,
  onPrimaryFixedVariant: AppColors.thickBlue,
  onSecondaryFixed: AppColors.darkGreen,
  onSecondaryFixedVariant: AppColors.thickGreen,
  onTertiaryFixed: AppColors.darkOrange,
  onTertiaryFixedVariant: AppColors.thickOrange,

  surfaceDim: AppColors.lmSurfaceDim,
  surface: AppColors.lmSurface,
  surfaceBright: AppColors.lmSurfaceBright,
  inverseSurface: AppColors.lmInverseSurface,

  onSurface: AppColors.lmOnSurface,
  onSurfaceVariant: AppColors.lmOnSurfaceVariant,
  onInverseSurface: AppColors.lmInverseOnSurface,

  outline: AppColors.lmOutline,
  outlineVariant: AppColors.lmOutlineVariant,

  surfaceContainerLowest: AppColors.lmSurfaceContainerLowest,
  surfaceContainerLow: AppColors.lmSurfaceContainerLow,
  surfaceContainer: AppColors.lmSurfaceContainer,
  surfaceContainerHigh: AppColors.lmSurfaceContainerHigh,
  surfaceContainerHighest: AppColors.lmSurfaceContainerHighest,

  scrim: AppColors.lmScrim,
  shadow: AppColors.lmShadow,

  inversePrimary: AppColors.lmInversePrimary,
);

final ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.dmBlue,
  secondary: AppColors.dmGreen,
  tertiary: AppColors.dmOrange,
  error: AppColors.dmRed,

  onPrimary: AppColors.darkBlue,
  onSecondary: AppColors.darkGreen,
  onTertiary: AppColors.darkOrange,
  onError: AppColors.darkRed,

  primaryContainer: AppColors.dmDarkBlue,
  secondaryContainer: AppColors.dmDarkGreen,
  tertiaryContainer: AppColors.dmDarkOrange,
  errorContainer: AppColors.dmDarkRed,

  onPrimaryContainer: AppColors.paleBlue,
  onSecondaryContainer: AppColors.paleGreen,
  onTertiaryContainer: AppColors.paleOrange,
  onErrorContainer: AppColors.paleRed,

  primaryFixed: AppColors.dmDarkBlue,
  primaryFixedDim: AppColors.darkBlue,
  secondaryFixed: AppColors.dmDarkGreen,
  secondaryFixedDim: AppColors.darkGreen,
  tertiaryFixed: AppColors.dmDarkOrange,
  tertiaryFixedDim: AppColors.darkOrange,

  onPrimaryFixed: AppColors.paleBlue,
  onPrimaryFixedVariant: AppColors.dimBlue,
  onSecondaryFixed: AppColors.paleGreen,
  onSecondaryFixedVariant: AppColors.dimGreen,
  onTertiaryFixed: AppColors.paleOrange,
  onTertiaryFixedVariant: AppColors.dimOrange,

  surfaceDim: AppColors.dmSurfaceDim,
  surface: AppColors.dmSurface,
  surfaceBright: AppColors.dmSurfaceBright,
  inverseSurface: AppColors.dmInverseSurface,

  onSurface: AppColors.dmOnSurface,
  onSurfaceVariant: AppColors.dmOnSurfaceVariant,
  onInverseSurface: AppColors.dmInverseOnSurface,

  outline: AppColors.dmOutline,
  outlineVariant: AppColors.dmOutlineVariant,

  surfaceContainerLowest: AppColors.dmSurfaceContainerLowest,
  surfaceContainerLow: AppColors.dmSurfaceContainerLow,
  surfaceContainer: AppColors.dmSurfaceContainer,
  surfaceContainerHigh: AppColors.dmSurfaceContainerHigh,
  surfaceContainerHighest: AppColors.dmSurfaceContainerHighest,

  scrim: AppColors.dmScrim,
  shadow: AppColors.dmShadow,

  inversePrimary: AppColors.dmInversePrimary,
);

// Extension for any additional custom colors you might need
extension CustomColorScheme on ColorScheme {
  // Universal colors that don't change with theme
  Color get lightBlue => AppColors.lightBlue;
  Color get offWhite => AppColors.offWhite;

  // If you need direct access to specific color variants
  Color get green => AppColors.green;
  Color get paleGreen => AppColors.paleGreen;
  Color get red => AppColors.red;
  Color get paleRed => AppColors.paleRed;
  Color get orange => AppColors.orange;
}

/* Full App Theme */

class AppTheme {
  static double _fontSizeScale = 1.0;

  static void setFontSizeScale(double scale) {
    _fontSizeScale = scale;
  }

  static double get fontSizeScale => _fontSizeScale;

  static TextTheme getTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Don't use font size changes on headlines and labels, maybe some app text shouldn't change?
      // TODO: Getting render errors depending on font size

      headlineLarge: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 30, // * _fontSizeScale,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 25, // * _fontSizeScale,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 22, // * _fontSizeScale,
        fontWeight: FontWeight.bold,
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



      labelLarge: GoogleFonts.poppins(
        color: colorScheme.onSurfaceVariant,
        fontSize: 18, // * _fontSizeScale,
        fontWeight: FontWeight.normal,
      ),
      labelMedium: GoogleFonts.poppins(
        color: colorScheme.onSurfaceVariant,
        fontSize: 15,
        fontWeight: FontWeight.normal,
      ),
      labelSmall: GoogleFonts.poppins(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
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
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: lightColorScheme.primary,
          size: 30
        ),
        actionsIconTheme: IconThemeData(
          color: lightColorScheme.primary,
          size: 40,
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
          iconColor: WidgetStateProperty.all(lightColorScheme.primary),
          shadowColor: WidgetStateProperty.all(lightColorScheme.shadow),
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
        hintStyle: getTextTheme(lightColorScheme).labelMedium,
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
