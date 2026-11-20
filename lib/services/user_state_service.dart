import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/models/user.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/utils/supabase_errors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Columns that exist on public."Users" after the Auth migration.
/// Prefer [reading_progress] over legacy progress fields; do not select
/// non-existent columns such as quizzes.
const String kProfileSelect =
    'id, Username, Email, role, dragons, acquired_accessories, '
    'acquired_environments, joined_classes, settings, reading_progress, '
    'dragon_dressup, dragon_environments, dragon_preferred_phases, '
    'deleted_classes';

class UserStateService {
  static final UserStateService _instance = UserStateService._internal();
  factory UserStateService() => _instance;
  UserStateService._internal();

  supabase.User? _supabaseUser;
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  String? _userId;
  bool _passwordRecovery = false;
  bool _authListenerStarted = false;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  /// UI listens so password-recovery can open Set Password without deadlocking.
  final ValueNotifier<bool> passwordRecoveryNotifier = ValueNotifier<bool>(false);

  // Keys for shared preferences
  static const String _keyUserId = 'saved_user_id';
  static const String _keyUserEmail = 'saved_user_email';

  supabase.User? get supabaseUser => _supabaseUser;
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get userId => _userId;
  bool get passwordRecovery => _passwordRecovery;

  void setPasswordRecovery(bool value) {
    _passwordRecovery = value;
    if (passwordRecoveryNotifier.value != value) {
      passwordRecoveryNotifier.value = value;
    }
  }

  void setUser(supabase.User? user) {
    _supabaseUser = user;
    _currentUser = user != null ? User.fromSupabaseUser(user) : null;
    _userId = user?.id;

    // If user is null, clear the profile and persisted session
    if (user == null) {
      _userProfile = null;
      clearUserSession();
    } else {
      // Save session when user is set
      saveUserSession(user.id, user.email);
    }
  }

  void setUserProfile(Map<String, dynamic>? profile) {
    _userProfile = profile == null ? null : _normalizeProfile(profile);
  }

  bool get isLoggedIn {
    final isLoggedIn = _currentUser != null && _userId != null;
    return isLoggedIn;
  }

  /// Start once after Supabase.initialize. Defers async work so we never
  /// await auth/session calls inside the sync onAuthStateChange path
  /// (that deadlocks GoTrue's lock and hangs updateUser/password set).
  void startAuthListener() {
    if (_authListenerStarted) return;
    _authListenerStarted = true;

    _authSubscription = SupabaseConfig.client.auth.onAuthStateChange.listen(
      (data) {
        // Defer out of the auth callback (equivalent to setTimeout(0)).
        // Awaiting Supabase calls inside the sync callback can deadlock GoTrue.
        scheduleMicrotask(() {
          unawaited(_handleAuthStateChange(data));
        });
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('Auth state stream error: $error');
      },
    );
  }

  Future<void> _handleAuthStateChange(supabase.AuthState data) async {
    final event = data.event;
    final session = data.session;

    if (event == supabase.AuthChangeEvent.passwordRecovery) {
      setPasswordRecovery(true);
    }

    if (event == supabase.AuthChangeEvent.signedOut || session?.user == null) {
      if (event == supabase.AuthChangeEvent.signedOut) {
        _supabaseUser = null;
        _currentUser = null;
        _userId = null;
        _userProfile = null;
        setPasswordRecovery(false);
        await clearUserSession();
      }
      return;
    }

    // Keep local auth user in sync; load profile without blocking recovery.
    setUser(session!.user);
    try {
      await loadUserProfile(required: false);
    } catch (err) {
      debugPrint('Error loading profile after auth change: $err');
      // During recovery, keep the Auth session even if profile load fails.
    }
  }

  Map<String, dynamic> _normalizeProfile(Map<String, dynamic> row) {
    final normalized = Map<String, dynamic>.from(row);
    final reading = row['reading_progress'];
    final legacyModules = row['modules'];
    if (reading is Map) {
      normalized['reading_progress'] = Map<String, dynamic>.from(reading);
      // App models historically called this "modules" progress.
      normalized['modules'] = Map<String, dynamic>.from(reading);
    } else if (legacyModules is Map) {
      normalized['modules'] = Map<String, dynamic>.from(legacyModules);
      normalized['reading_progress'] = Map<String, dynamic>.from(legacyModules);
    } else {
      normalized['reading_progress'] = <String, dynamic>{};
      normalized['modules'] = <String, dynamic>{};
    }
    return normalized;
  }

  Future<void> loadUserProfile({bool required = false}) async {
    if (_userId == null) {
      print('Cannot load profile: No user ID available');
      if (required) {
        throw ProfileNotLinkedException(
          'Cannot load profile: no Auth user id available.',
        );
      }
      return;
    }

    try {
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select(kProfileSelect)
              .eq('id', _userId!)
              .single();

      _userProfile = _normalizeProfile(Map<String, dynamic>.from(response));

      if (_supabaseUser != null) {
        final modules = _userProfile!['reading_progress'];
        _currentUser = User.fromSupabaseUser(
          _supabaseUser!,
          modules: modules is Map<String, dynamic> ? modules : null,
        );
      }
    } catch (e) {
      print('loadUserProfile: ❌ Error loading user profile: $e');
      _userProfile = null;

      if (isMissingProfileError(e)) {
        throw ProfileNotLinkedException();
      }
      if (required) {
        throw Exception(getErrorMessage(e, 'Could not load user profile'));
      }
    }
  }

  /// Migrated / pre-Auth independent accounts must set an Auth password once.
  /// Class-code synthetic emails never use this gate.
  bool needsPasswordSetup([Map<String, dynamic>? profile]) {
    if (_passwordRecovery) return true;
    final raw = profile ?? _userProfile;
    if (raw == null) return false;
    final settings = _parseSettings(raw['settings']);
    if (settings['auth_password_confirmed_at'] != null) return false;
    if (settings['must_set_password'] == false) return false;

    final email = (_supabaseUser?.email ?? raw['Email'] ?? '')
        .toString()
        .toLowerCase();
    if (email.endsWith('@class.safescales.internal')) return false;

    // Explicit migration flag, or independent email account without confirmation.
    if (settings['must_set_password'] == true) return true;
    return email.contains('@');
  }

  Map<String, dynamic> _parseSettings(dynamic raw) {
    if (raw == null) return {};
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
        return {};
      } catch (_) {
        return {};
      }
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Future<void> markPasswordConfirmed() async {
    if (_userId == null) {
      throw Exception('No user id for password confirmation');
    }

    await loadUserProfile(required: false);
    final settings = _parseSettings(_userProfile?['settings']);
    settings['must_set_password'] = false;
    settings['auth_password_confirmed_at'] =
        DateTime.now().toUtc().toIso8601String();

    try {
      final response =
          await SupabaseConfig.client
              .from('Users')
              .update({'settings': settings})
              .eq('id', _userId!)
              .select(kProfileSelect)
              .single();
      setUserProfile(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception(
        getErrorMessage(
          e,
          'Could not save password confirmation on your profile',
        ),
      );
    }

    // Best-effort metadata sync — do not block if this hangs or fails.
    unawaited(() async {
      try {
        await SupabaseConfig.client.auth.updateUser(
          supabase.UserAttributes(
            data: {
              'auth_password_confirmed_at':
                  settings['auth_password_confirmed_at'],
              'must_set_password': false,
            },
          ),
        );
      } catch (err) {
        debugPrint(
          'Could not sync auth metadata after password confirm: $err',
        );
      }
    }());
  }

  Future<String?> getUserName() async {
    if (_userId == null) {
      print('❌ Error: Cannot get username: No user ID available');
      return null;
    }

    try {
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select('Username')
              .eq('id', _userId!)
              .single();

      final username = response['Username'] as String?;
      print('Extracted username: $username');

      return username;
    } catch (e) {
      print('❌ Error getting username: $e');
      return null;
    }
  }

  // Get user's theme and font size settings from the Users table
  Future<Map<String, dynamic>> getUserSettings() async {
    if (_userId == null) {
      print(
        '❌ Error UserStateService getUserSettings Cannot get settings: No user ID available',
      );
      return {};
    }
    try {
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select('settings')
              .eq('id', _userId!)
              .single();
      if (response['settings'] != null) {
        return Map<String, dynamic>.from(response['settings']);
      }
      return {};
    } catch (e) {
      print(
        '❌ Error: UserStateService getUserSettings getting user settings: $e',
      );
      return {};
    }
  }

  // Save user's theme and font size settings to the Users table
  Future<void> saveUserSettings({
    required bool isDarkMode,
    required double fontSize,
    required double readingFontSize,
    double? readingSpeed,
    AppThemeType? themeType,
  }) async {
    if (_userId == null) {
      print(
        '❌ Error: UserStateService saveUserSettings() Cannot save settings: No user ID available',
      );
      return;
    }
    try {
      // Get current settings
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select('settings')
              .eq('id', _userId!)
              .single();
      Map<String, dynamic> settings = {};
      if (response['settings'] != null) {
        settings = Map<String, dynamic>.from(response['settings']);
      }
      settings['isDarkMode'] = isDarkMode;
      settings['fontSize'] = fontSize;
      settings['readingFontSize'] = readingFontSize;
      if (readingSpeed != null) {
        settings['readingSpeed'] = readingSpeed;
      }
      if (themeType != null) {
        settings['themeType'] = themeType.name;
      }
      await SupabaseConfig.client
          .from('Users')
          .update({'settings': settings})
          .eq('id', _userId!);
    } catch (e) {
      print('❌ Error saving user settings: $e');
    }
  }

  // Save user session to device storage
  Future<void> saveUserSession(String userId, String? email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId);
      if (email != null) {
        await prefs.setString(_keyUserEmail, email);
      }
      print('✅ User session saved to device');
    } catch (e) {
      print('❌ Error saving user session: $e');
    }
  }

  // Restore user session from Supabase Auth (JWT), not a forged local user.
  Future<bool> restoreUserSession() async {
    try {
      final session = SupabaseConfig.client.auth.currentSession;
      final authUser = SupabaseConfig.client.auth.currentUser;

      if (session == null || authUser == null) {
        print('No Supabase Auth session found');
        await clearUserSession();
        return false;
      }

      print('Attempting to restore Auth session for user: ${authUser.id}');

      setUser(authUser);
      try {
        await loadUserProfile(required: true);
      } catch (e) {
        print('Auth session present but profile load failed: $e');
        // During password recovery, keep the Auth session so set-password works.
        if (_passwordRecovery) {
          return true;
        }
        setUser(null);
        await clearUserSession();
        return false;
      }

      print('User session restored successfully from Auth');
      return true;
    } catch (e) {
      print('Error restoring user session: $e');
      if (!_passwordRecovery) {
        await clearUserSession();
      }
      return false;
    }
  }

  // Clear user session from device storage
  Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserEmail);
      print('✅ User session cleared from device');
    } catch (e) {
      print('❌ Error clearing user session: $e');
    }
  }

  void disposeAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _authListenerStarted = false;
  }
}
