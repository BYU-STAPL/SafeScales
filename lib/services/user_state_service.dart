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
      print('Quizzes data from response: ${response['quizzes']}');
      _userProfile = response;

      // Update current user with quizzes data
      if (_supabaseUser != null) {
        print('Creating user with quizzes data: ${response['quizzes']}');
        _currentUser = User.fromSupabaseUser(
          _supabaseUser!,
          quizzes: response['quizzes'],
        );
        print('Updated current user quizzes: ${_currentUser?.quizzes}');
      }
    } catch (e) {
      print('Error loading user profile: $e');
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
      print('Error getting username: $e');
      return null;
    }
  }

  Future<void> saveQuizProgress({
    required int quizId,
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
      // Get current user's quizzes data
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select('quizzes')
              .eq('id', _userId!)
              .single();

      Map<String, dynamic> quizzes = response['quizzes'] ?? {};

      // Add or update the quiz data
      quizzes[quizId.toString()] = {
        'score': scorePercentage,
        'answers': userAnswers,
        'completed_at': DateTime.now().toIso8601String(),
        'correct_answers': correctAnswers,
        'total_questions': totalQuestions,
        'spent': false, // Initialize spent flag as false
      };

      // Update the quizzes data in the database
      await SupabaseConfig.client
          .from('Users')
          .update({'quizzes': quizzes})
          .eq('id', _userId!);

      // Update local user state
      await loadUserProfile();
    } catch (e) {
      print('Error saving quiz progress: $e');
    }
  }
}
