import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/models/user.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStateService {
  static final UserStateService _instance = UserStateService._internal();
  factory UserStateService() => _instance;
  UserStateService._internal();

  supabase.User? _supabaseUser;
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  String? _userId;

  // Keys for shared preferences
  static const String _keyUserId = 'saved_user_id';
  static const String _keyUserEmail = 'saved_user_email';

  supabase.User? get supabaseUser => _supabaseUser;
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get userId => _userId;

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
    _userProfile = profile;
  }

  bool get isLoggedIn {
    final isLoggedIn = _currentUser != null && _userId != null;
    return isLoggedIn;
  }

  Future<void> loadUserProfile() async {
    if (_userId == null) {
      print('Cannot load profile: No user ID available');
      return;
    }

    try {
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select()
              .eq('id', _userId!)
              .single();

      _userProfile = response;

      // Update current user with modules data
      // TODO: module progress in user table is now reading_progress. Quiz attempts are a separate table
      if (_supabaseUser != null) {
        _currentUser = User.fromSupabaseUser(
          _supabaseUser!,
          modules: response['reading_progress'],
        );
      }
    } catch (e) {
      print('loadUserProfile: ❌ Error loading user profile: $e');
      _userProfile = null;
    }
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

  // Restore user session from device storage
  Future<bool> restoreUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString(_keyUserId);
      final savedUserEmail = prefs.getString(_keyUserEmail);

      if (savedUserId == null) {
        print('No saved session found');
        return false;
      }

      print('🔄 Attempting to restore session for user: $savedUserId');

      // Verify user still exists in database
      try {
        final response =
            await SupabaseConfig.client
                .from('Users')
                .select()
                .eq('id', savedUserId)
                .single();

        // Validate email matches if we have it saved
        if (savedUserEmail != null &&
            response['Email'] != null &&
            response['Email'] != savedUserEmail) {
          print('⚠️ Saved email does not match database, clearing session');
          await clearUserSession();
          return false;
        }

        // Create supabase user object from saved data
        final userEmail = response['Email']?.toString() ?? savedUserEmail ?? '';
        final createdAtStr = response['created_at']?.toString() ?? '';
        final supabaseUser = supabase.User(
          id: savedUserId,
          email: userEmail,
          createdAt: createdAtStr,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          role: 'authenticated',
        );

        // Restore user state
        _supabaseUser = supabaseUser;
        _currentUser = User.fromSupabaseUser(supabaseUser);
        _userId = savedUserId;
        _userProfile = response;

        // Update current user with modules data
        _currentUser = User.fromSupabaseUser(
          supabaseUser,
          modules: response['reading_progress'],
        );

        print('✅ User session restored successfully');
        return true;
      } catch (e) {
        print('❌ Error verifying user in database: $e');
        // User might not exist anymore, clear saved session
        await clearUserSession();
        return false;
      }
    } catch (e) {
      print('❌ Error restoring user session: $e');
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
}
