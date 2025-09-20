import 'package:safe_scales/models/question.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Repository responsible for all course-related database operations
/// Follows the Repository pattern to separate data access from business logic
class CourseRepository {
  final SupabaseClient _supabase;

  CourseRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseConfig.client;

  // === User Class Operations ===

  /// Get the class that a user is enrolled in
  Future<Map<String, dynamic>?> getUserClass(String userId) async {
    try {
      final userResponse =
          await _supabase
              .from('Users')
              .select('joined_classes')
              .eq('id', userId)
              .single();

      if (userResponse['joined_classes'] == null ||
          (userResponse['joined_classes'] as List).isEmpty) {
        return null;
      }

      final classId = (userResponse['joined_classes'] as List).first;
      final classResponse =
          await _supabase.from('classes').select().eq('id', classId).single();

      return Map<String, dynamic>.from(classResponse);
    } catch (e) {
      throw Exception('Failed to get user class: $e');
    }
  }

  // === Class Content Operations ===

  /// Get all modules/lessons for a specific class
  Future<List<Map<String, dynamic>>> getClassModules(String classId) async {
    try {
      final classResponse =
          await _supabase
              .from('classes')
              .select('course_modules')
              .eq('id', classId)
              .single();

      if (classResponse['course_modules'] == null) {
        return [];
      }

      final moduleIds = List<String>.from(classResponse['course_modules']);
      final modulesResponse = await _supabase
          .from('modules')
          .select()
          .inFilter('id', moduleIds)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(modulesResponse);
    } catch (e) {
      throw Exception('Failed to get class modules: $e');
    }
  }

  /// Get lesson order for a class
  Future<List<String>> getLessonOrder(String classId) async {
    try {
      final classResponse =
          await _supabase
              .from('classes')
              .select('course_modules')
              .eq('id', classId)
              .single();

      if (classResponse['course_modules'] == null) {
        return [];
      }

      final moduleIds = List<String>.from(classResponse['course_modules']);
      final modulesResponse = await _supabase
          .from('modules')
          .select('id, created_at')
          .inFilter('id', moduleIds)
          .order('created_at', ascending: true);

      return modulesResponse
          .map<String>((module) => module['id'].toString())
          .toList();
    } catch (e) {
      throw Exception('Failed to get lesson order: $e');
    }
  }

  /// Get a specific module by ID
  Future<Map<String, dynamic>?> getModuleById(String moduleId) async {
    try {
      final moduleResponse =
          await _supabase.from('modules').select().eq('id', moduleId).single();

      return Map<String, dynamic>.from(moduleResponse);
    } catch (e) {
      throw Exception('Failed to get module: $e');
    }
  }

  /// Get class assets
  Future<List<dynamic>?> getClassAssets(String classId) async {
    try {
      final classResponse =
          await _supabase
              .from('classes')
              .select('assets')
              .eq('id', classId)
              .single();

      return classResponse['assets'] != null
          ? List<dynamic>.from(classResponse['assets'])
          : null;
    } catch (e) {
      throw Exception('Failed to get class assets: $e');
    }
  }

  // === User Progress Operations ===

  /// Get all user progress data
  Future<Map<String, dynamic>?> getUserProgressData(String userId) async {
    try {
      final response =
          await _supabase
              .from('Users')
              .select('modules')
              .eq('id', userId)
              .single();

      return response['modules'];
    } catch (e) {
      throw Exception('Failed to get user progress: $e');
    }
  }


  /// Save Quiz Attempt
  Future<void> saveQuizAttempt({
    required String userId,
    required String quizId,
    required ActivityType quizType,
    required List<List<int>> answers,
    required int correctAnswers,
    required int totalQuestions,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {

      if (quizType == ActivityType.postQuiz) {

        //Double check quiz id old version with type as a postfix
        // String correctedQuizId = quizId.split('_')[0];

        // Prep data
        final attemptData = {
          'user_id': userId,
          'quiz_id': quizId,
          'quiz_type': 'post_quiz'.toLowerCase(),
          'question_responses': answers, // Supabase will automatically convert to JSON
          'num_correct_answers': correctAnswers,
          'total_questions': totalQuestions,
          'started_at': startTime.toIso8601String(),
          'completed_at': DateTime.now().toIso8601String(),
          // created_at will be auto-generated if you have a default value
        };

        // Insert into database
        final response = await _supabase
            .from('quiz_attempts')
            .insert(attemptData)
            .select('id') // Return the ID of the created record
            .single();

        print('Quiz attempt saved successfully with ID: ${response['id']}');




      }
      else if (quizType == ActivityType.preQuiz) {
        // Check if an attempt for this pre-quiz already exists

        // Prep data


      }
      else {
        throw Exception('Missing pre_quiz or post_quiz type');
      }


    } catch (e) {
      throw Exception('CourseRepository SaveQuizAttempt(): Failed to save quiz progress: $e');
    }
  }




  /// Save quiz progress to database
  Future<void> saveQuizProgress({
    required String userId,
    required String quizId,
    required ActivityType quizType,
    required List<List<int>> answers,
    required int correctAnswers,
    required int totalQuestions,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {

      await saveQuizAttempt(
        userId: userId,
        quizId: quizId,
        quizType: quizType,
        answers: answers,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        startTime: startTime,
        endTime: endTime,
      );

      final score = ((correctAnswers / totalQuestions) * 100).round();

      // Get current user data
      final response =
          await _supabase
              .from('Users')
              .select('quizzes, modules')
              .eq('id', userId)
              .single();

      // Update legacy quizzes column
      Map<String, dynamic> quizzes = {};
      if (response['quizzes'] != null) {
        quizzes = Map<String, dynamic>.from(response['quizzes']);
      }

      quizzes[quizId] = {
        'score': score,
        'answers': answers,
        'completed_at': DateTime.now().toIso8601String(),
        'correct_answers': correctAnswers,
        'total_questions': totalQuestions,
      };

      // Update modules column
      Map<String, dynamic> modules = {};
      if (response['modules'] != null) {
        modules = Map<String, dynamic>.from(response['modules']);
      }

      // Parse quiz ID to get module and quiz type
      String moduleId;
      String quizTypeText;

      if (quizId.contains('_')) {
        final parts = quizId.split('_');
        moduleId = parts[0];
        quizTypeText = parts.length > 1 ? parts[1] : 'quiz';
      } else {
        moduleId = 'legacy';
        quizTypeText = quizId;
      }

      // Initialize module entry if it doesn't exist
      if (!modules.containsKey(moduleId)) {
        modules[moduleId] = {
          'reading': {
            'completed': false,
            'completed_at': null,
            'bookmarks': [],
          },
          'preQuiz': {
            'score': 0,
            'spent': false,
            'answers': [],
            'completed_at': null,
            'correct_answers': 0,
            'total_questions': 0,
          },
          'postQuiz': {
            'score': 0,
            'spent': false,
            'answers': [],
            'completed_at': null,
            'correct_answers': 0,
            'total_questions': 0,
          },
        };
      }

      // Update the specific quiz
      modules[moduleId][quizTypeText] = {
        'answers': answers,
        'score': score,
        'spent': true,
        'completed_at': DateTime.now().toIso8601String(),
        'correct_answers': correctAnswers,
        'total_questions': totalQuestions,
      };

      // Save to database
      await _supabase
          .from('Users')
          .update({'quizzes': quizzes, 'modules': modules})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to save quiz progress: $e');
    }
  }

  /// Save reading progress to database
  Future<void> saveReadingProgress({
    required String userId,
    required String lessonId,
    required Set<int> bookmarks,
  }) async {
    try {
      final response =
          await _supabase
              .from('Users')
              .select('modules')
              .eq('id', userId)
              .single();

      Map<String, dynamic> modulesData = {};
      if (response['modules'] != null) {
        modulesData = Map<String, dynamic>.from(response['modules']);
      }

      if (!modulesData.containsKey(lessonId)) {
        modulesData[lessonId] = {
          'reading': {
            'completed': false,
            'completed_at': null,
            'bookmarks': [],
          },
          'preQuiz': {
            'score': 0,
            'spent': false,
            'answers': [],
            'completed_at': null,
            'correct_answers': 0,
            'total_questions': 0,
          },
          'postQuiz': {
            'score': 0,
            'spent': false,
            'answers': [],
            'completed_at': null,
            'correct_answers': 0,
            'total_questions': 0,
          },
        };
      }

      // Update reading progress while preserving other fields
      final currentModule = modulesData[lessonId] as Map<String, dynamic>;
      currentModule['reading'] = {
        'completed': true,
        'completed_at': DateTime.now().toIso8601String(),
        'bookmarks': bookmarks.toList(),
      };

      await _supabase
          .from('Users')
          .update({'modules': modulesData})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to save reading progress: $e');
    }
  }
}
