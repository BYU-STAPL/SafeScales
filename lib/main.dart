import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/providers/theme_provider.dart';
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

    runApp(MyApp(appDeps: appDeps));

  } catch (e, stackTrace) {
    print("❌ App initialization failed: $e");
    print("Stack trace: $stackTrace");

    // Run app with error state
    runApp(
      MaterialApp(
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
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final AppDependencies appDeps;

  const MyApp({super.key, required this.appDeps});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appDeps.getProviders(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'SafeScales',
            theme: AppTheme.buildLightAppTheme(),
            darkTheme: AppTheme.buildDarkAppTheme(),
            themeMode:
                themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SelectionScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
