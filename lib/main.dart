import 'package:flutter/material.dart';
import 'package:safe_scales/auth/auth_screen.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/services/user_state_service.dart';

import 'main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase before running the app
  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  double _fontSize = 1.0;
  final _userState = UserStateService();

  void _updateTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  void _updateFontSize(double fontSize) {
    setState(() {
      _fontSize = fontSize;
      AppTheme.setFontSizeScale(fontSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Scales',
      theme: AppTheme.buildLightAppTheme(),
      darkTheme: AppTheme.buildDarkAppTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Builder(
        builder: (context) {
          // Check if user is already logged in
          final currentUser = SupabaseConfig.client.auth.currentUser;
          if (currentUser != null) {
            // Initialize user state
            _userState.setUser(currentUser);
            _userState.loadUserProfile();

            return MainNavigation(
              onThemeChanged: _updateTheme,
              onFontSizeChanged: _updateFontSize,
              isDarkMode: _isDarkMode,
              fontSize: _fontSize,
              initialIndex: 0,
            );
          }

          return AuthScreen(
            onThemeChanged: _updateTheme,
            onFontSizeChanged: _updateFontSize,
            isDarkMode: _isDarkMode,
            fontSize: _fontSize,
          );
        },
      ),
    );
  }
}
