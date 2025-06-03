import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:safe_scales/auth/auth_screen.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/themes/theme_notifier.dart';
import 'package:safe_scales/themes/theme_provider.dart';
import 'package:safe_scales/components/health_check.dart';

import 'main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

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
  bool _supabaseInitialized = true;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ThemeNotifier();
    _themeNotifier.loadSettings(); // Load saved settings
    _checkSupabaseConnection();
  }

  Future<void> _checkSupabaseConnection() async {
    try {
      await SupabaseConfig.client.from('Users').select('count').limit(1);
      setState(() {
        _supabaseInitialized = true;
      });
    } catch (e) {
      setState(() {
        _supabaseInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      themeNotifier: _themeNotifier,
      child: AnimatedBuilder(
        animation: _themeNotifier,
        builder: (context, child) {
          return MaterialApp(
            title: 'Safe Scales',
            theme: AppTheme.buildLightAppTheme(),
            darkTheme: AppTheme.buildDarkAppTheme(),
            themeMode:
                _themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: Builder(
              builder: (context) {
                if (!_supabaseInitialized) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Connection Status')),
                    body: const Center(child: HealthCheck()),
                  );
                }

                // Check if user is already logged in
                final currentUser = SupabaseConfig.client.auth.currentUser;
                if (currentUser != null) {
                  // Initialize user state
                  _userState.setUser(currentUser);
                  _userState.loadUserProfile();

                  return MainNavigation(initialIndex: 0);
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
