import 'package:flutter/cupertino.dart';
import 'package:safe_scales/themes/theme_notifier.dart';

class ThemeProvider extends InheritedNotifier<ThemeNotifier> {
  const ThemeProvider({
    super.key,
    required super.child,
    required ThemeNotifier themeNotifier,
  }) : super(notifier: themeNotifier);

  static ThemeNotifier of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>()!
        .notifier!;
  }
}



