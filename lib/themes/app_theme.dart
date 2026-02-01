import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/* Theme Type Enum */

enum AppThemeType {
  classicBlue,
  forestGreen,
  sunsetOrange,
  oceanTeal,
  royalPurple,
  rosePink,
  indigoNavy,
  amberGold,
}

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

// Helper function to create color schemes for different themes
ColorScheme _createColorScheme({
  required Brightness brightness,
  required Color primary,
  required Color secondary,
  required Color tertiary,
  required Color error,
  required Color onPrimary,
  required Color onSecondary,
  required Color onTertiary,
  required Color onError,
  required Color primaryContainer,
  required Color secondaryContainer,
  required Color tertiaryContainer,
  required Color errorContainer,
  required Color onPrimaryContainer,
  required Color onSecondaryContainer,
  required Color onTertiaryContainer,
  required Color onErrorContainer,
  required Color primaryFixed,
  required Color primaryFixedDim,
  required Color secondaryFixed,
  required Color secondaryFixedDim,
  required Color tertiaryFixed,
  required Color tertiaryFixedDim,
  required Color onPrimaryFixed,
  required Color onPrimaryFixedVariant,
  required Color onSecondaryFixed,
  required Color onSecondaryFixedVariant,
  required Color onTertiaryFixed,
  required Color onTertiaryFixedVariant,
  required Color surfaceDim,
  required Color surface,
  required Color surfaceBright,
  required Color inverseSurface,
  required Color onSurface,
  required Color onSurfaceVariant,
  required Color onInverseSurface,
  required Color outline,
  required Color outlineVariant,
  required Color surfaceContainerLowest,
  required Color surfaceContainerLow,
  required Color surfaceContainer,
  required Color surfaceContainerHigh,
  required Color surfaceContainerHighest,
  required Color scrim,
  required Color shadow,
  required Color inversePrimary,
}) {
  return ColorScheme(
    brightness: brightness,
    primary: primary,
    secondary: secondary,
    tertiary: tertiary,
    error: error,
    onPrimary: onPrimary,
    onSecondary: onSecondary,
    onTertiary: onTertiary,
    onError: onError,
    primaryContainer: primaryContainer,
    secondaryContainer: secondaryContainer,
    tertiaryContainer: tertiaryContainer,
    errorContainer: errorContainer,
    onPrimaryContainer: onPrimaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    onErrorContainer: onErrorContainer,
    primaryFixed: primaryFixed,
    primaryFixedDim: primaryFixedDim,
    secondaryFixed: secondaryFixed,
    secondaryFixedDim: secondaryFixedDim,
    tertiaryFixed: tertiaryFixed,
    tertiaryFixedDim: tertiaryFixedDim,
    onPrimaryFixed: onPrimaryFixed,
    onPrimaryFixedVariant: onPrimaryFixedVariant,
    onSecondaryFixed: onSecondaryFixed,
    onSecondaryFixedVariant: onSecondaryFixedVariant,
    onTertiaryFixed: onTertiaryFixed,
    onTertiaryFixedVariant: onTertiaryFixedVariant,
    surfaceDim: surfaceDim,
    surface: surface,
    surfaceBright: surfaceBright,
    inverseSurface: inverseSurface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    onInverseSurface: onInverseSurface,
    outline: outline,
    outlineVariant: outlineVariant,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    scrim: scrim,
    shadow: shadow,
    inversePrimary: inversePrimary,
  );
}

// ColorScheme definitions - Classic Blue (default)
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

// Forest Green Theme - Light
final ColorScheme lightForestGreenScheme = _createColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xff059669), // Emerald green
  secondary: const Color(0xff10B981), // Green
  tertiary: const Color(0xffF59E0B), // Amber accent
  error: const Color(0xffDC2626),
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onTertiary: Colors.white,
  onError: Colors.white,
  primaryContainer: const Color(0xffD1FAE5), // Pale green
  secondaryContainer: const Color(0xffA7F3D0), // Light green
  tertiaryContainer: const Color(0xffFEF3C7), // Pale amber
  errorContainer: const Color(0xffFEE2E2),
  onPrimaryContainer: const Color(0xff065F46), // Dark green
  onSecondaryContainer: const Color(0xff047857),
  onTertiaryContainer: const Color(0xff92400E),
  onErrorContainer: const Color(0xff991B1B),
  primaryFixed: const Color(0xffD1FAE5),
  primaryFixedDim: const Color(0xffA7F3D0),
  secondaryFixed: const Color(0xffA7F3D0),
  secondaryFixedDim: const Color(0xff6EE7B7),
  tertiaryFixed: const Color(0xffFEF3C7),
  tertiaryFixedDim: const Color(0xffFDE68A),
  onPrimaryFixed: const Color(0xff065F46),
  onPrimaryFixedVariant: const Color(0xff047857),
  onSecondaryFixed: const Color(0xff047857),
  onSecondaryFixedVariant: const Color(0xff059669),
  onTertiaryFixed: const Color(0xff92400E),
  onTertiaryFixedVariant: const Color(0xffD97706),
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
  inversePrimary: const Color(0xff6EE7B7),
);

// Forest Green Theme - Dark
final ColorScheme darkForestGreenScheme = _createColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xff34D399), // Bright emerald
  secondary: const Color(0xff6EE7B7), // Light green
  tertiary: const Color(0xffFBBF24), // Amber
  error: const Color(0xffF87171),
  onPrimary: const Color(0xff065F46),
  onSecondary: const Color(0xff047857),
  onTertiary: const Color(0xff92400E),
  onError: const Color(0xff991B1B),
  primaryContainer: const Color(0xff047857), // Dark green
  secondaryContainer: const Color(0xff065F46), // Darker green
  tertiaryContainer: const Color(0xff78350F),
  errorContainer: const Color(0xff7F1D1D),
  onPrimaryContainer: const Color(0xffD1FAE5),
  onSecondaryContainer: const Color(0xffA7F3D0),
  onTertiaryContainer: const Color(0xffFEF3C7),
  onErrorContainer: const Color(0xffFEE2E2),
  primaryFixed: const Color(0xff047857),
  primaryFixedDim: const Color(0xff065F46),
  secondaryFixed: const Color(0xff065F46),
  secondaryFixedDim: const Color(0xff064E3B),
  tertiaryFixed: const Color(0xff78350F),
  tertiaryFixedDim: const Color(0xff92400E),
  onPrimaryFixed: const Color(0xffD1FAE5),
  onPrimaryFixedVariant: const Color(0xffA7F3D0),
  onSecondaryFixed: const Color(0xffA7F3D0),
  onSecondaryFixedVariant: const Color(0xff6EE7B7),
  onTertiaryFixed: const Color(0xffFEF3C7),
  onTertiaryFixedVariant: const Color(0xffFDE68A),
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
  inversePrimary: const Color(0xff047857),
);

// Sunset Orange Theme - Light
final ColorScheme lightSunsetOrangeScheme = _createColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xffEA580C), // Orange
  secondary: const Color(0xffF97316), // Bright orange
  tertiary: const Color(0xffEAB308), // Yellow
  error: const Color(0xffDC2626),
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onTertiary: Colors.black87,
  onError: Colors.white,
  primaryContainer: const Color(0xffFED7AA), // Pale orange
  secondaryContainer: const Color(0xffFED7AA), // Light orange
  tertiaryContainer: const Color(0xffFEF9C3), // Pale yellow
  errorContainer: const Color(0xffFEE2E2),
  onPrimaryContainer: const Color(0xff9A3412), // Dark orange
  onSecondaryContainer: const Color(0xffC2410C),
  onTertiaryContainer: const Color(0xff854D0E),
  onErrorContainer: const Color(0xff991B1B),
  primaryFixed: const Color(0xffFED7AA),
  primaryFixedDim: const Color(0xffFDBA74),
  secondaryFixed: const Color(0xffFDBA74),
  secondaryFixedDim: const Color(0xffFB923C),
  tertiaryFixed: const Color(0xffFEF9C3),
  tertiaryFixedDim: const Color(0xffFEF08A),
  onPrimaryFixed: const Color(0xff9A3412),
  onPrimaryFixedVariant: const Color(0xffC2410C),
  onSecondaryFixed: const Color(0xffC2410C),
  onSecondaryFixedVariant: const Color(0xffEA580C),
  onTertiaryFixed: const Color(0xff854D0E),
  onTertiaryFixedVariant: const Color(0xffCA8A04),
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
  inversePrimary: const Color(0xffFDBA74),
);

// Sunset Orange Theme - Dark
final ColorScheme darkSunsetOrangeScheme = _createColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xffFB923C), // Bright orange
  secondary: const Color(0xffFDBA74), // Light orange
  tertiary: const Color(0xffFCD34D), // Yellow
  error: const Color(0xffF87171),
  onPrimary: const Color(0xff7C2D12), // Very dark orange
  onSecondary: const Color(0xff9A3412),
  onTertiary: const Color(0xff713F12),
  onError: const Color(0xff991B1B),
  primaryContainer: const Color(0xffC2410C), // Dark orange
  secondaryContainer: const Color(0xff9A3412), // Darker orange
  tertiaryContainer: const Color(0xff854D0E),
  errorContainer: const Color(0xff7F1D1D),
  onPrimaryContainer: const Color(0xffFED7AA),
  onSecondaryContainer: const Color(0xffFDBA74),
  onTertiaryContainer: const Color(0xffFEF9C3),
  onErrorContainer: const Color(0xffFEE2E2),
  primaryFixed: const Color(0xffC2410C),
  primaryFixedDim: const Color(0xff9A3412),
  secondaryFixed: const Color(0xff9A3412),
  secondaryFixedDim: const Color(0xff7C2D12),
  tertiaryFixed: const Color(0xff854D0E),
  tertiaryFixedDim: const Color(0xff713F12),
  onPrimaryFixed: const Color(0xffFED7AA),
  onPrimaryFixedVariant: const Color(0xffFDBA74),
  onSecondaryFixed: const Color(0xffFDBA74),
  onSecondaryFixedVariant: const Color(0xffFB923C),
  onTertiaryFixed: const Color(0xffFEF9C3),
  onTertiaryFixedVariant: const Color(0xffFEF08A),
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
  inversePrimary: const Color(0xffC2410C),
);

// Ocean Teal Theme - Light
final ColorScheme lightOceanTealScheme = _createColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xff0891B2), // Cyan
  secondary: const Color(0xff06B6D4), // Bright cyan
  tertiary: const Color(0xff0EA5E9), // Sky blue
  error: const Color(0xffDC2626),
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onTertiary: Colors.white,
  onError: Colors.white,
  primaryContainer: const Color(0xffCFFAFE), // Pale cyan
  secondaryContainer: const Color(0xffA5F3FC), // Light cyan
  tertiaryContainer: const Color(0xffE0F2FE), // Pale blue
  errorContainer: const Color(0xffFEE2E2),
  onPrimaryContainer: const Color(0xff164E63), // Dark cyan
  onSecondaryContainer: const Color(0xff155E75),
  onTertiaryContainer: const Color(0xff0C4A6E),
  onErrorContainer: const Color(0xff991B1B),
  primaryFixed: const Color(0xffCFFAFE),
  primaryFixedDim: const Color(0xffA5F3FC),
  secondaryFixed: const Color(0xffA5F3FC),
  secondaryFixedDim: const Color(0xff67E8F9),
  tertiaryFixed: const Color(0xffE0F2FE),
  tertiaryFixedDim: const Color(0xffBAE6FD),
  onPrimaryFixed: const Color(0xff164E63),
  onPrimaryFixedVariant: const Color(0xff155E75),
  onSecondaryFixed: const Color(0xff155E75),
  onSecondaryFixedVariant: const Color(0xff0891B2),
  onTertiaryFixed: const Color(0xff0C4A6E),
  onTertiaryFixedVariant: const Color(0xff0284C7),
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
  inversePrimary: const Color(0xff67E8F9),
);

// Ocean Teal Theme - Dark
final ColorScheme darkOceanTealScheme = _createColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xff22D3EE), // Bright cyan
  secondary: const Color(0xff67E8F9), // Light cyan
  tertiary: const Color(0xff38BDF8), // Sky blue
  error: const Color(0xffF87171),
  onPrimary: const Color(0xff164E63),
  onSecondary: const Color(0xff155E75),
  onTertiary: const Color(0xff0C4A6E),
  onError: const Color(0xff991B1B),
  primaryContainer: const Color(0xff155E75), // Dark cyan
  secondaryContainer: const Color(0xff164E63), // Darker cyan
  tertiaryContainer: const Color(0xff075985),
  errorContainer: const Color(0xff7F1D1D),
  onPrimaryContainer: const Color(0xffCFFAFE),
  onSecondaryContainer: const Color(0xffA5F3FC),
  onTertiaryContainer: const Color(0xffE0F2FE),
  onErrorContainer: const Color(0xffFEE2E2),
  primaryFixed: const Color(0xff155E75),
  primaryFixedDim: const Color(0xff164E63),
  secondaryFixed: const Color(0xff164E63),
  secondaryFixedDim: const Color(0xff0E7490),
  tertiaryFixed: const Color(0xff075985),
  tertiaryFixedDim: const Color(0xff0C4A6E),
  onPrimaryFixed: const Color(0xffCFFAFE),
  onPrimaryFixedVariant: const Color(0xffA5F3FC),
  onSecondaryFixed: const Color(0xffA5F3FC),
  onSecondaryFixedVariant: const Color(0xff67E8F9),
  onTertiaryFixed: const Color(0xffE0F2FE),
  onTertiaryFixedVariant: const Color(0xffBAE6FD),
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
  inversePrimary: const Color(0xff155E75),
);

// Royal Purple Theme - Light
final ColorScheme lightRoyalPurpleScheme = _createColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xff7C3AED), // Purple
  secondary: const Color(0xff8B5CF6), // Bright purple
  tertiary: const Color(0xffA855F7), // Violet
  error: const Color(0xffDC2626),
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onTertiary: Colors.white,
  onError: Colors.white,
  primaryContainer: const Color(0xffEDE9FE), // Pale purple
  secondaryContainer: const Color(0xffDDD6FE), // Light purple
  tertiaryContainer: const Color(0xffF3E8FF), // Pale violet
  errorContainer: const Color(0xffFEE2E2),
  onPrimaryContainer: const Color(0xff5B21B6), // Dark purple
  onSecondaryContainer: const Color(0xff6D28D9),
  onTertiaryContainer: const Color(0xff7E22CE),
  onErrorContainer: const Color(0xff991B1B),
  primaryFixed: const Color(0xffEDE9FE),
  primaryFixedDim: const Color(0xffDDD6FE),
  secondaryFixed: const Color(0xffDDD6FE),
  secondaryFixedDim: const Color(0xffC4B5FD),
  tertiaryFixed: const Color(0xffF3E8FF),
  tertiaryFixedDim: const Color(0xffE9D5FF),
  onPrimaryFixed: const Color(0xff5B21B6),
  onPrimaryFixedVariant: const Color(0xff6D28D9),
  onSecondaryFixed: const Color(0xff6D28D9),
  onSecondaryFixedVariant: const Color(0xff7C3AED),
  onTertiaryFixed: const Color(0xff7E22CE),
  onTertiaryFixedVariant: const Color(0xff9333EA),
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
  inversePrimary: const Color(0xffC4B5FD),
);

// Royal Purple Theme - Dark
final ColorScheme darkRoyalPurpleScheme = _createColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xffA78BFA), // Bright purple
  secondary: const Color(0xffC4B5FD), // Light purple
  tertiary: const Color(0xffC084FC), // Violet
  error: const Color(0xffF87171),
  onPrimary: const Color(0xff4C1D95), // Very dark purple
  onSecondary: const Color(0xff5B21B6),
  onTertiary: const Color(0xff6B21A8),
  onError: const Color(0xff991B1B),
  primaryContainer: const Color(0xff6D28D9), // Dark purple
  secondaryContainer: const Color(0xff5B21B6), // Darker purple
  tertiaryContainer: const Color(0xff7E22CE),
  errorContainer: const Color(0xff7F1D1D),
  onPrimaryContainer: const Color(0xffEDE9FE),
  onSecondaryContainer: const Color(0xffDDD6FE),
  onTertiaryContainer: const Color(0xffF3E8FF),
  onErrorContainer: const Color(0xffFEE2E2),
  primaryFixed: const Color(0xff6D28D9),
  primaryFixedDim: const Color(0xff5B21B6),
  secondaryFixed: const Color(0xff5B21B6),
  secondaryFixedDim: const Color(0xff4C1D95),
  tertiaryFixed: const Color(0xff7E22CE),
  tertiaryFixedDim: const Color(0xff6B21A8),
  onPrimaryFixed: const Color(0xffEDE9FE),
  onPrimaryFixedVariant: const Color(0xffDDD6FE),
  onSecondaryFixed: const Color(0xffDDD6FE),
  onSecondaryFixedVariant: const Color(0xffC4B5FD),
  onTertiaryFixed: const Color(0xffF3E8FF),
  onTertiaryFixedVariant: const Color(0xffE9D5FF),
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
  inversePrimary: const Color(0xff6D28D9),
);

// Rose Pink Theme - Light
final ColorScheme lightRosePinkScheme = _createColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xffE11D48), // Rose red
  secondary: const Color(0xffF43F5E), // Pink
  tertiary: const Color(0xffEC4899), // Magenta
  error: const Color(0xffDC2626),
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onTertiary: Colors.white,
  onError: Colors.white,
  primaryContainer: const Color(0xffFCE7F3), // Pale pink
  secondaryContainer: const Color(0xffFDF2F8), // Very pale pink
  tertiaryContainer: const Color(0xffFDF2F8), // Pale pink
  errorContainer: const Color(0xffFEE2E2),
  onPrimaryContainer: const Color(0xff9F1239), // Dark rose
  onSecondaryContainer: const Color(0xffBE185D),
  onTertiaryContainer: const Color(0xffBE185D),
  onErrorContainer: const Color(0xff991B1B),
  primaryFixed: const Color(0xffFCE7F3),
  primaryFixedDim: const Color(0xffFBCFE8),
  secondaryFixed: const Color(0xffFDF2F8),
  secondaryFixedDim: const Color(0xffFCE7F3),
  tertiaryFixed: const Color(0xffFDF2F8),
  tertiaryFixedDim: const Color(0xffFBCFE8),
  onPrimaryFixed: const Color(0xff9F1239),
  onPrimaryFixedVariant: const Color(0xffBE185D),
  onSecondaryFixed: const Color(0xffBE185D),
  onSecondaryFixedVariant: const Color(0xffE11D48),
  onTertiaryFixed: const Color(0xffBE185D),
  onTertiaryFixedVariant: const Color(0xffEC4899),
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
  inversePrimary: const Color(0xffFBCFE8),
);

// Rose Pink Theme - Dark
final ColorScheme darkRosePinkScheme = _createColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xffFB7185), // Bright pink
  secondary: const Color(0xffFBCFE8), // Light pink
  tertiary: const Color(0xffF9A8D4), // Light magenta
  error: const Color(0xffF87171),
  onPrimary: const Color(0xff9F1239), // Very dark rose
  onSecondary: const Color(0xffBE185D),
  onTertiary: const Color(0xffBE185D),
  onError: const Color(0xff991B1B),
  primaryContainer: const Color(0xffBE185D), // Dark rose
  secondaryContainer: const Color(0xff9F1239), // Darker rose
  tertiaryContainer: const Color(0xff831843),
  errorContainer: const Color(0xff7F1D1D),
  onPrimaryContainer: const Color(0xffFCE7F3),
  onSecondaryContainer: const Color(0xffFDF2F8),
  onTertiaryContainer: const Color(0xffFDF2F8),
  onErrorContainer: const Color(0xffFEE2E2),
  primaryFixed: const Color(0xffBE185D),
  primaryFixedDim: const Color(0xff9F1239),
  secondaryFixed: const Color(0xff9F1239),
  secondaryFixedDim: const Color(0xff831843),
  tertiaryFixed: const Color(0xff831843),
  tertiaryFixedDim: const Color(0xff9F1239),
  onPrimaryFixed: const Color(0xffFCE7F3),
  onPrimaryFixedVariant: const Color(0xffFBCFE8),
  onSecondaryFixed: const Color(0xffFDF2F8),
  onSecondaryFixedVariant: const Color(0xffFBCFE8),
  onTertiaryFixed: const Color(0xffFDF2F8),
  onTertiaryFixedVariant: const Color(0xffFBCFE8),
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
  inversePrimary: const Color(0xffBE185D),
);

// Indigo Navy Theme - Light
final ColorScheme lightIndigoNavyScheme = _createColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xff4338CA), // Indigo
  secondary: const Color(0xff4F46E5), // Bright indigo
  tertiary: const Color(0xff6366F1), // Light indigo
  error: const Color(0xffDC2626),
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onTertiary: Colors.white,
  onError: Colors.white,
  primaryContainer: const Color(0xffE0E7FF), // Pale indigo
  secondaryContainer: const Color(0xffE0E7FF), // Light indigo
  tertiaryContainer: const Color(0xffEEF2FF), // Very pale indigo
  errorContainer: const Color(0xffFEE2E2),
  onPrimaryContainer: const Color(0xff312E81), // Dark indigo
  onSecondaryContainer: const Color(0xff3730A3),
  onTertiaryContainer: const Color(0xff4338CA),
  onErrorContainer: const Color(0xff991B1B),
  primaryFixed: const Color(0xffE0E7FF),
  primaryFixedDim: const Color(0xffC7D2FE),
  secondaryFixed: const Color(0xffC7D2FE),
  secondaryFixedDim: const Color(0xffA5B4FC),
  tertiaryFixed: const Color(0xffEEF2FF),
  tertiaryFixedDim: const Color(0xffE0E7FF),
  onPrimaryFixed: const Color(0xff312E81),
  onPrimaryFixedVariant: const Color(0xff3730A3),
  onSecondaryFixed: const Color(0xff3730A3),
  onSecondaryFixedVariant: const Color(0xff4338CA),
  onTertiaryFixed: const Color(0xff4338CA),
  onTertiaryFixedVariant: const Color(0xff4F46E5),
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
  inversePrimary: const Color(0xffA5B4FC),
);

// Indigo Navy Theme - Dark
final ColorScheme darkIndigoNavyScheme = _createColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xff818CF8), // Bright indigo
  secondary: const Color(0xffA5B4FC), // Light indigo
  tertiary: const Color(0xffC7D2FE), // Very light indigo
  error: const Color(0xffF87171),
  onPrimary: const Color(0xff1E1B4B), // Very dark indigo
  onSecondary: const Color(0xff312E81),
  onTertiary: const Color(0xff3730A3),
  onError: const Color(0xff991B1B),
  primaryContainer: const Color(0xff4F46E5), // Dark indigo
  secondaryContainer: const Color(0xff4338CA), // Darker indigo
  tertiaryContainer: const Color(0xff3730A3),
  errorContainer: const Color(0xff7F1D1D),
  onPrimaryContainer: const Color(0xffE0E7FF),
  onSecondaryContainer: const Color(0xffC7D2FE),
  onTertiaryContainer: const Color(0xffEEF2FF),
  onErrorContainer: const Color(0xffFEE2E2),
  primaryFixed: const Color(0xff4F46E5),
  primaryFixedDim: const Color(0xff4338CA),
  secondaryFixed: const Color(0xff4338CA),
  secondaryFixedDim: const Color(0xff3730A3),
  tertiaryFixed: const Color(0xff3730A3),
  tertiaryFixedDim: const Color(0xff312E81),
  onPrimaryFixed: const Color(0xffE0E7FF),
  onPrimaryFixedVariant: const Color(0xffC7D2FE),
  onSecondaryFixed: const Color(0xffC7D2FE),
  onSecondaryFixedVariant: const Color(0xffA5B4FC),
  onTertiaryFixed: const Color(0xffEEF2FF),
  onTertiaryFixedVariant: const Color(0xffE0E7FF),
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
  inversePrimary: const Color(0xff4F46E5),
);

// Amber Gold Theme - Light
final ColorScheme lightAmberGoldScheme = _createColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xffD97706), // Amber
  secondary: const Color(0xffF59E0B), // Bright amber
  tertiary: const Color(0xffFCD34D), // Gold
  error: const Color(0xffDC2626),
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onTertiary: Colors.black87,
  onError: Colors.white,
  primaryContainer: const Color(0xffFEF3C7), // Pale amber
  secondaryContainer: const Color(0xffFEF9C3), // Pale gold
  tertiaryContainer: const Color(0xffFFFBEB), // Very pale gold
  errorContainer: const Color(0xffFEE2E2),
  onPrimaryContainer: const Color(0xff92400E), // Dark amber
  onSecondaryContainer: const Color(0xffB45309),
  onTertiaryContainer: const Color(0xff78350F),
  onErrorContainer: const Color(0xff991B1B),
  primaryFixed: const Color(0xffFEF3C7),
  primaryFixedDim: const Color(0xffFDE68A),
  secondaryFixed: const Color(0xffFEF9C3),
  secondaryFixedDim: const Color(0xffFEF08A),
  tertiaryFixed: const Color(0xffFFFBEB),
  tertiaryFixedDim: const Color(0xffFEF9C3),
  onPrimaryFixed: const Color(0xff92400E),
  onPrimaryFixedVariant: const Color(0xffB45309),
  onSecondaryFixed: const Color(0xffB45309),
  onSecondaryFixedVariant: const Color(0xffD97706),
  onTertiaryFixed: const Color(0xff78350F),
  onTertiaryFixedVariant: const Color(0xff92400E),
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
  inversePrimary: const Color(0xffFDE68A),
);

// Amber Gold Theme - Dark
final ColorScheme darkAmberGoldScheme = _createColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xffFBBF24), // Bright amber
  secondary: const Color(0xffFCD34D), // Light amber
  tertiary: const Color(0xffFDE68A), // Very light gold
  error: const Color(0xffF87171),
  onPrimary: const Color(0xff78350F), // Very dark amber
  onSecondary: const Color(0xff92400E),
  onTertiary: const Color(0xff92400E),
  onError: const Color(0xff991B1B),
  primaryContainer: const Color(0xffB45309), // Dark amber
  secondaryContainer: const Color(0xff92400E), // Darker amber
  tertiaryContainer: const Color(0xff78350F),
  errorContainer: const Color(0xff7F1D1D),
  onPrimaryContainer: const Color(0xffFEF3C7),
  onSecondaryContainer: const Color(0xffFEF9C3),
  onTertiaryContainer: const Color(0xffFFFBEB),
  onErrorContainer: const Color(0xffFEE2E2),
  primaryFixed: const Color(0xffB45309),
  primaryFixedDim: const Color(0xff92400E),
  secondaryFixed: const Color(0xff92400E),
  secondaryFixedDim: const Color(0xff78350F),
  tertiaryFixed: const Color(0xff78350F),
  tertiaryFixedDim: const Color(0xff92400E),
  onPrimaryFixed: const Color(0xffFEF3C7),
  onPrimaryFixedVariant: const Color(0xffFDE68A),
  onSecondaryFixed: const Color(0xffFEF9C3),
  onSecondaryFixedVariant: const Color(0xffFCD34D),
  onTertiaryFixed: const Color(0xffFFFBEB),
  onTertiaryFixedVariant: const Color(0xffFEF9C3),
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
  inversePrimary: const Color(0xffB45309),
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
  static AppThemeType _currentThemeType = AppThemeType.classicBlue;

  static void setFontSizeScale(double scale) {
    _fontSizeScale = scale;
  }

  static double get fontSizeScale => _fontSizeScale;

  static void setThemeType(AppThemeType themeType) {
    _currentThemeType = themeType;
  }

  static AppThemeType get themeType => _currentThemeType;

  static ColorScheme getColorScheme(bool isDarkMode) {
    switch (_currentThemeType) {
      case AppThemeType.classicBlue:
        return isDarkMode ? darkColorScheme : lightColorScheme;
      case AppThemeType.forestGreen:
        return isDarkMode ? darkForestGreenScheme : lightForestGreenScheme;
      case AppThemeType.sunsetOrange:
        return isDarkMode ? darkSunsetOrangeScheme : lightSunsetOrangeScheme;
      case AppThemeType.oceanTeal:
        return isDarkMode ? darkOceanTealScheme : lightOceanTealScheme;
      case AppThemeType.royalPurple:
        return isDarkMode ? darkRoyalPurpleScheme : lightRoyalPurpleScheme;
      case AppThemeType.rosePink:
        return isDarkMode ? darkRosePinkScheme : lightRosePinkScheme;
      case AppThemeType.indigoNavy:
        return isDarkMode ? darkIndigoNavyScheme : lightIndigoNavyScheme;
      case AppThemeType.amberGold:
        return isDarkMode ? darkAmberGoldScheme : lightAmberGoldScheme;
    }
  }

  static TextTheme getTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Don't use font size changes on headlines and labels, maybe some app text shouldn't change?
      // TODO: Getting render errors depending on font size

      headlineLarge: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 24, // * _fontSizeScale,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 20, // * _fontSizeScale,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: GoogleFonts.poppins(
        color: colorScheme.onSurface,
        fontSize: 18, // * _fontSizeScale,
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
    final colorScheme = getColorScheme(false);
    return ThemeData(
      // Color scheme
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // Typography
      textTheme: getTextTheme(colorScheme),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 25,
        titleTextStyle: TextStyle(
          color: colorScheme.primary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 30
        ),
        actionsIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 40,
        ),
        actionsPadding: EdgeInsets.only(right: 20),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: getTextTheme(colorScheme).labelMedium,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: colorScheme.shadow,
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          iconColor: WidgetStateProperty.all(colorScheme.primary),
          shadowColor: WidgetStateProperty.all(colorScheme.shadow),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: colorScheme.surfaceDim,
        shadowColor: colorScheme.shadow,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: getTextTheme(colorScheme).labelMedium,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData buildDarkAppTheme() {
    final colorScheme = getColorScheme(true);
    return ThemeData(
      // Color scheme
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // Typography
      textTheme: getTextTheme(colorScheme),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 25,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 24 * _fontSizeScale,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 30 * _fontSizeScale,
        ),
        actionsIconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 40 * _fontSizeScale,
        ),
        actionsPadding: EdgeInsets.only(right: 20),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: getTextTheme(colorScheme).labelMedium,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: colorScheme.shadow,
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          iconColor: WidgetStateProperty.all(colorScheme.primary),
          shadowColor: WidgetStateProperty.all(colorScheme.shadow),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: colorScheme.surfaceDim,
        shadowColor: colorScheme.shadow,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
