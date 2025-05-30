import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safe_scales/config/supabase_config.dart';

class UserStateService {
  static final UserStateService _instance = UserStateService._internal();
  factory UserStateService() => _instance;
  UserStateService._internal();

  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  String? _userId;

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get userId => _userId;

  void setUser(User? user) {
    print('Setting user: ${user?.id}');
    _currentUser = user;
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
      _userProfile = response;
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
      await SupabaseConfig.client.from('QuizProgress').insert({
        'user_id': _userId!,
        'quiz_id': quizId,
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
        'score_percentage': scorePercentage,
        'user_answers': userAnswers,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving quiz progress: $e');
    }
  }
}
