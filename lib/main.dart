import 'package:flutter/material.dart';
import 'package:safe_scales/auth/auth_screen.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/themes/theme_notifier.dart';
import 'package:safe_scales/themes/theme_provider.dart';

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
  final _userState = UserStateService();
  late ThemeNotifier _themeNotifier;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ThemeNotifier();
    _themeNotifier.loadSettings(); // Load saved settings
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      themeNotifier: _themeNotifier, // Use the same instance
      child: AnimatedBuilder(
        animation: _themeNotifier, // Listen to changes
        builder: (context, child) {
          return MaterialApp(
            title: 'Safe Scales',
            theme: AppTheme.buildLightAppTheme(),
            darkTheme: AppTheme.buildDarkAppTheme(),
            themeMode: _themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: Builder(
              builder: (context) {
                // Check if user is already logged in
                final currentUser = SupabaseConfig.client.auth.currentUser;
                if (currentUser != null) {
                  // Initialize user state
                  _userState.setUser(currentUser);
                  _userState.loadUserProfile();

                  return MainNavigation(
                    initialIndex: 0,
                  );
                }

                return AuthScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
