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
    print('Setting user: ${user?.id}');
    _supabaseUser = user;
    _currentUser = user != null ? User.fromSupabaseUser(user) : null;
    _userId = user?.id;

    // If user is null, clear the profile
    if (user == null) {
      _userProfile = null;
    }
  }

  void setUserProfile(Map<String, dynamic>? profile) {
    print('Setting user profile: $profile');
    _userProfile = profile;
  }

  bool get isLoggedIn {
    final isLoggedIn = _currentUser != null && _userId != null;
    print(
      'Checking login status: $isLoggedIn (User: ${_currentUser?.id}, ID: $_userId)',
    );
    return isLoggedIn;
  }

  Future<void> loadUserProfile() async {
    if (_userId == null) {
      print('Cannot load profile: No user ID available');
      return;
    }

    try {
      print('Loading profile for user: $_userId');
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select()
              .eq('id', _userId!)
              .single();

      print('Loaded user profile: $response');
      print('Modules data from response: ${response['modules']}');
      _userProfile = response;

      // Update current user with modules data
      if (_supabaseUser != null) {
        print('Creating user with modules data: ${response['modules']}');
        _currentUser = User.fromSupabaseUser(
          _supabaseUser!,
          modules: response['modules'],
        );
        print('Updated current user modules: ${_currentUser?.modules}');
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
      _userProfile = null;
    }
  }

  Future<String?> getUserName() async {
    if (_userId == null) {
      print('Cannot get username: No user ID available');
      return null;
    }

    try {
      print('Getting username for user: $_userId');
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select('Username')
              .eq('id', _userId!)
              .single();

      print('Got username response: $response');
      final username = response['Username'] as String?;
      print('Extracted username: $username');
      return username;
    } catch (e) {
      print('❌ Error getting username: $e');
      return null;
    }
  }

  Future<void> saveQuizProgress({
    required String moduleId,
    required String quizType, // 'preQuiz' or 'postQuiz'
    required int totalQuestions,
    required int correctAnswers,
    required double scorePercentage,
    required List<List<int>> userAnswers,
  }) async {
    if (_userId == null) {
      print('No user logged in, skipping quiz progress save');
      return;
    }

    try {
      // Get current user's modules data
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select('modules')
              .eq('id', _userId!)
              .single();

      Map<String, dynamic> modules = response['modules'] ?? {};

      // Initialize module if it doesn't exist
      if (!modules.containsKey(moduleId)) {
        modules[moduleId] = {};
      }

      // Add or update the quiz data
      modules[moduleId][quizType] = {
        'score': scorePercentage,
        'answers': userAnswers,
        'completed_at': DateTime.now().toIso8601String(),
        'correct_answers': correctAnswers,
        'total_questions': totalQuestions,
        'spent': false, // Initialize spent flag as false
      };

      // Update the modules data in the database
      await SupabaseConfig.client
          .from('Users')
          .update({'modules': modules})
          .eq('id', _userId!);

      // Update local user state
      await loadUserProfile();
    } catch (e) {
      print('❌ Error saving quiz progress: $e');
    }
  }

  // Get user's theme and font size settings from the Users table
  Future<Map<String, dynamic>> getUserSettings() async {
    if (_userId == null) {
      print('Cannot get settings: No user ID available');
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
      print('❌ Error getting user settings: $e');
      return {};
    }
  }

  // Save user's theme and font size settings to the Users table
  Future<void> saveUserSettings({
    required bool isDarkMode,
    required double fontSize,
  }) async {
    if (_userId == null) {
      print('Cannot save settings: No user ID available');
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
      print('Saved user settings: $settings');
    } catch (e) {
      print('❌ Error saving user settings: $e');
    }
  }
}
