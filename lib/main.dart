import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/dependencies/app_dependencies.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/ui/screens/login/selection_screen.dart';

void main() {
  print("🔵 [MAIN] Starting main()");
  WidgetsFlutterBinding.ensureInitialized();
  print("🔵 [MAIN] WidgetsFlutterBinding initialized");
  
  // Show app immediately with a loading screen
  print("🔵 [MAIN] About to call runApp");
  runApp(const InitializingApp());
  print("🔵 [MAIN] runApp called");
}

class InitializingApp extends StatefulWidget {
  const InitializingApp({super.key});

  @override
  State<InitializingApp> createState() {
    print("🔵 [INIT] Creating state");
    return _InitializingAppState();
  }
}

class _InitializingAppState extends State<InitializingApp> {
  AppDependencies? appDeps;
  String? errorMessage;
  bool isInitializing = true;

  @override
  void initState() {
    print("🔵 [INIT] initState called");
    super.initState();
    print("🔵 [INIT] About to schedule postFrameCallback");
    // Initialize in the background after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("🔵 [INIT] postFrameCallback executed");
      _initializeApp();
    });
    print("🔵 [INIT] postFrameCallback scheduled");
  }

  Future<void> _initializeApp() async {
    print("🟢 [INIT] _initializeApp started");
    try {
      print("🟢 [INIT] Step 1: About to load .env file");
      // Load environment variables from assets
      await dotenv.load(fileName: ".env");
      print("🟢 [INIT] Step 1: .env file loaded successfully");

      print("🟢 [INIT] Step 2: About to initialize Supabase");
      // Initialize Supabase
      await SupabaseConfig.initialize();
      print("🟢 [INIT] Step 2: Supabase initialized successfully");

      print("🟢 [INIT] Step 3: About to create app dependencies");
      // Create app dependencies (only initialize providers, don't load data yet)
      final deps = createAppDependenciesFromSupabase(Supabase.instance.client);
      print("🟢 [INIT] Step 3: App dependencies created");

      print("🟢 [INIT] Step 4: About to initialize providers");
      await deps.initializeProviders();
      print("🟢 [INIT] Step 4: Providers initialized successfully");

      print("🟢 [INIT] Step 5: About to update state");
      if (mounted) {
        setState(() {
          appDeps = deps;
          isInitializing = false;
        });
        print("🟢 [INIT] Step 5: State updated successfully");
      } else {
        print("⚠️ [INIT] Widget not mounted, cannot update state");
      }
    } catch (e, stackTrace) {
      print("❌ [INIT] App initialization failed: $e");
      print("❌ [INIT] Stack trace: $stackTrace");
      
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isInitializing = false;
        });
        print("❌ [INIT] Error state set");
      } else {
        print("⚠️ [INIT] Widget not mounted, cannot set error state");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🟡 [BUILD] build() called, isInitializing=$isInitializing, errorMessage=$errorMessage");
    
    if (isInitializing) {
      print("🟡 [BUILD] Showing loading screen");
      // Show loading screen while initializing
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Initializing app...'),
              ],
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      print("🟡 [BUILD] Showing error screen");
      // Show error screen
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    print("🟡 [BUILD] Showing main app");
    // App initialized successfully
    return MyApp(appDeps: appDeps!);
  }
}

class MyApp extends StatelessWidget {
  final AppDependencies appDeps;

  const MyApp({super.key, required this.appDeps});

  @override
  Widget build(BuildContext context) {
    print("🟣 [MYAPP] MyApp.build() called");
    return MultiProvider(
      providers: appDeps.getProviders(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          print("🟣 [MYAPP] Consumer builder called");
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
