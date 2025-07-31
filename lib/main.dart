import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/state_management/dragon_provider.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/themes/theme_notifier.dart';
import 'package:safe_scales/themes/theme_provider.dart';
import 'package:safe_scales/ui/health_check.dart';
import 'package:safe_scales/ui/screens/login/selection_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dependencies/app_dependencies.dart';
import 'ui/screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  await SupabaseConfig.initialize();

  final appDeps = createAppDependenciesFromSupabase(Supabase.instance.client);
  await appDeps.initializeProviders();

  runApp(MyApp(appDeps: appDeps));
}

class MyApp extends StatefulWidget {
  final AppDependencies appDeps;

  const MyApp({Key? key, required this.appDeps}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
    widget.appDeps.dispose(); // Clean up app dependencies
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: widget.appDeps.getProviders(),
      child: ThemeProvider(
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
                    // Initialize user state using the dependency
                    widget.appDeps.userStateService.setUser(currentUser);
                    widget.appDeps.userStateService.loadUserProfile().then((_) {
                      _themeNotifier
                          .loadSettings(); // Reload settings after profile is loaded

                      // Load user dragons after profile is loaded
                      final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
                      dragonProvider.loadUserDragons();
                    });
                    return MainNavigation(initialIndex: 0);
                  }

                  return const SelectionScreen();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}