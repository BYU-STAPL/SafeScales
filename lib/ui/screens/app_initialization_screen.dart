import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/providers/theme_provider.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/providers/course_provider.dart';
import 'package:safe_scales/providers/dragon_provider.dart';
import 'package:safe_scales/providers/item_provider.dart';
import 'package:safe_scales/ui/screens/main_navigation.dart';
import 'package:safe_scales/ui/screens/login/selection_screen.dart';

/// This screen handles the initialization of all app data after authentication
/// It shows a loading screen while data is being loaded
class AppInitializationScreen extends StatefulWidget {
  const AppInitializationScreen({super.key});

  @override
  State<AppInitializationScreen> createState() => _AppInitializationScreenState();
}

class _AppInitializationScreenState extends State<AppInitializationScreen> {
  bool _isInitializing = true;
  String _loadingMessage = 'Initializing app...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      final userState = UserStateService();

      // Check if user is authenticated
      if (userState.currentUser == null) {
        _navigateToSelection();
        return;
      }

      setState(() {
        _loadingMessage = 'Loading your data...';
      });

      // Get providers
      final themeProvider = Provider.of<ThemeNotifier>(context, listen: false);

      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);

      // Initialize providers one by one with progress updates
      setState(() {
        _loadingMessage = 'Loading course content...';
      });

      if (!courseProvider.isInitialized) {
        await courseProvider.initialize();
      }
      await courseProvider.loadCourseContent();
      await courseProvider.loadUserProgress();

      setState(() {
        _loadingMessage = 'Loading your dragons...';
      });

      if (!dragonProvider.isInitialized) {
        await dragonProvider.initialize();
      }
      await dragonProvider.loadUserDragons();

      setState(() {
        _loadingMessage = 'Loading items...';
      });

      // Only initialize item provider if we have a class
      if (courseProvider.lessons.isNotEmpty) {
        if (!itemProvider.isInitialized) {
          await itemProvider.initialize();
        }
      }

      setState(() {
        _loadingMessage = 'Finalizing...';
      });

      // Pull in User Preferred Settings
      themeProvider.loadSettings();

      // Small delay to show completion
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to main app
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigation(initialIndex: 0),
          ),
        );
      }

    } catch (e) {
      print('❌ App initialization failed: $e');
      
      // Check if the error is due to a deleted class
      final errorString = e.toString();
      if (errorString.contains('DeletedClassException') || 
          errorString.contains('deleted') ||
          (errorString.contains('PGRST116') && errorString.contains('0 rows'))) {
        // Class was deleted - clear user session and redirect to class selection
        print('⚠️ User\'s class was deleted, clearing session and redirecting...');
        
        final userState = UserStateService();
        await userState.clearUserSession();
        userState.setUser(null);
        
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'The class you were enrolled in has been deleted. Please join a new class.';
          });
          
          // Show a dialog or navigate after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _navigateToSelection();
            }
          });
        }
        return;
      }
      
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to load app data: ${e.toString()}';
      });
    }
  }

  void _navigateToSelection() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SelectionScreen(),
        ),
      );
    }
  }

  void _retry() {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _loadingMessage = 'Retrying...';
    });
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Icon(
                    Icons.school,
                    size: 80,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'SafeScales',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (_isInitializing) ...[
                    // Loading indicator
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      _loadingMessage,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (_errorMessage != null) ...[
                    // Error state
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.errorContainer,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _retry,
                          child: const Text('Retry'),
                        ),
                        TextButton(
                          onPressed: _navigateToSelection,
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          child: const Text('Back to Login'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}