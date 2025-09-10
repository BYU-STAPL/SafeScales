import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Theme-specific dependencies manager
class ThemeDependencies {
  final SupabaseClient supabase;
  final UserStateService userStateService;

  late final ThemeNotifier _themeNotifier;

  ThemeDependencies({required this.supabase, required this.userStateService}) {
    _initializeThemeDependencies();
  }

  void _initializeThemeDependencies() {
    _themeNotifier = ThemeNotifier(userStateService: userStateService);
  }

  /// Get the theme notifier
  ThemeNotifier get notifier => _themeNotifier;

  /// Initialize theme settings (load from storage)
  Future<void> initialize() async {
    try {

      await _themeNotifier.loadSettings();

    } catch (e) {
      print("❌ Theme initialization failed: $e");
      rethrow;
    }
  }

  /// Dispose theme resources
  void dispose() {
    _themeNotifier.dispose();
  }

  /// Health check for theme dependencies
  bool get isHealthy {
    return _themeNotifier != null;
  }
}
