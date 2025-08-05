import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/themes/theme_notifier.dart';
import 'package:safe_scales/themes/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/dependencies/app_dependencies.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/ui/screens/login/selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load();

    // Initialize Supabase
    await SupabaseConfig.initialize();

    // Create app dependencies (only initialize providers, don't load data yet)
    final appDeps = createAppDependenciesFromSupabase(Supabase.instance.client);
    await appDeps.initializeProviders();

    print("🚀 App dependencies initialized successfully");

    runApp(MyApp(appDeps: appDeps));

  } catch (e, stackTrace) {

    print("❌ App initialization failed: $e");
    print("Stack trace: $stackTrace");

    // Run app with error state - you could create an error screen here
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.red),
              SizedBox(height: 16),
              Text(
                'Failed to initialize app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatefulWidget {
  final AppDependencies appDeps;

  const MyApp({Key? key, required this.appDeps}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeNotifier _themeNotifier;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ThemeNotifier();
    // _themeNotifier.loadSettings(); // Load saved settings
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    widget.appDeps.dispose(); // Clean up app dependencies

    _themeNotifier = ThemeNotifier();
    _themeNotifier.loadSettings(); // Load saved settings

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
              title: 'SafeScales',
              theme: AppTheme.buildLightAppTheme(),
              darkTheme: AppTheme.buildDarkAppTheme(),
              themeMode: _themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const SelectionScreen(), // Start with selection screen
              debugShowCheckedModeBanner: false,
            );
          }
        ),
      ),
    );
  }

}