import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


Color royalBlue = const Color(0xff2E83E8);

Color lightRoyalBlue = const Color(0xff70C0EE);

Color darkGrey = const Color(0xff888888);
Color grey = const Color(0xffAAAAAA);
Color lightGrey = const Color(0xffE1E1E1);
Color offWhite = const Color(0xffF4F4F4);

Color green = const Color(0xff74A159);
Color red = const Color(0xffB72512);

ColorScheme appColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: royalBlue,
    onPrimary: offWhite,
    secondary: lightRoyalBlue,
    onSecondary: Colors.black,
    tertiary: lightGrey,
    onTertiary: Colors.black,
    error: red,
    onError: offWhite,
    surface: offWhite,
    onSurface: Colors.black,
    outline: darkGrey,
    shadow: grey,
);


var appTextTheme = TextTheme(
  headlineLarge: GoogleFonts.openSans(color: appColorScheme.onSurface, fontSize: 32, fontWeight: FontWeight.bold,),
  headlineMedium: GoogleFonts.openSans(color: appColorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.normal),
  bodyLarge: GoogleFonts.openSans(color: appColorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.normal),
  bodyMedium: GoogleFonts.openSans(color: appColorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.normal),
  bodySmall: GoogleFonts.openSans(color: appColorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.normal),

  labelMedium: GoogleFonts.openSans(color: appColorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.normal),
);

ThemeData buildLightAppTheme() {
  return ThemeData(
    // Color scheme
    colorScheme: appColorScheme,

    // Typography
    textTheme: appTextTheme,

    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: appColorScheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(
        color: appColorScheme.primary,
        size: 25,
      ),
      // actionsPadding: EdgeInsets.symmetric(horizontal: 100),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: appTextTheme.labelMedium,
        backgroundColor: appColorScheme.primary,
        foregroundColor: appColorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}



ThemeData buildDarkAppTheme() {
  return ThemeData(
    // Color scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),

    // Typography
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
    ),

    // App bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: appColorScheme.tertiary,
      shadowColor: appColorScheme.shadow,
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}