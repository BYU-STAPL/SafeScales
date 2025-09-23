import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/models/user.dart';

class UserStateService {
  static final UserStateService _instance = UserStateService._internal();
  factory UserStateService() => _instance;
  UserStateService._internal();

  supabase.User? _supabaseUser;
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  String? _userId;

  supabase.User? get supabaseUser => _supabaseUser;
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get userId => _userId;

  void setUser(supabase.User? user) {
    _supabaseUser = user;
    _currentUser = user != null ? User.fromSupabaseUser(user) : null;
    _userId = user?.id;

    // If user is null, clear the profile
    if (user == null) {
      _userProfile = null;
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
      print('❌ Error UserStateService getUserSettings Cannot get settings: No user ID available');
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
      print('❌ Error: UserStateService getUserSettings getting user settings: $e');
      return {};
    }
  }

  // Save user's theme and font size settings to the Users table
  Future<void> saveUserSettings({required bool isDarkMode, required double fontSize,}) async {
    if (_userId == null) {
      print('❌ Error: UserStateService saveUserSettings() Cannot save settings: No user ID available');
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
      await SupabaseConfig.client
          .from('Users')
          .update({'settings': settings})
          .eq('id', _userId!);

    } catch (e) {
      print('❌ Error saving user settings: $e');
    }
  }
}
