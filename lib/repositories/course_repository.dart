import 'package:safe_scales/models/question.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Repository responsible for all course-related database operations
/// Follows the Repository pattern to separate data access from business logic
class CourseRepository {
  final SupabaseClient _supabase;

  CourseRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseConfig.client;


  // ---------------- CREATE ----------------


  /// Save Quiz Attempt
  Future<void> saveQuizAttempt({required String userId, required String quizId, required ActivityType quizType, required List<List<int>> answers, required int correctAnswers, required int totalQuestions, required DateTime startTime, required DateTime endTime,}) async {
    try {

      if (quizType == ActivityType.postQuiz) {

        // Prep data
        final attemptData = {
          'user_id': userId,
          'quiz_id': quizId,
          'lesson_id': quizId.split('_')[0], // Quiz id is just the lesson_id + preQuiz or postQuiz at end
          'quiz_type': 'post_quiz'.toLowerCase(),
          'question_responses': answers, // Supabase will automatically convert to JSON
          'num_correct_answers': correctAnswers,
          'total_questions': totalQuestions,
          'started_at': startTime.toIso8601String(),
          'completed_at': DateTime.now().toIso8601String(),
          // created_at will be auto-generated if you have a default value
        };

        // Insert into database
        await _supabase
            .from('quiz_attempts')
            .insert(attemptData)
            .select('id') // Return the ID of the created record
            .single();

      }
      else if (quizType == ActivityType.preQuiz) {
        // Check if an attempt for this pre-quiz already exists
        List<dynamic> response = await _supabase
            .from('quiz_attempts')
            .select('*')
            .eq('user_id', userId)
            .eq('quiz_id', quizId)
            .order('completed_at', ascending: true); // oldest first

        if (response.isNotEmpty) {
          return;
        }

        // Prep data
        final attemptData = {
          'user_id': userId,
          'quiz_id': quizId,
          'lesson_id': quizId.split('_')[0], // Quiz id is just the lesson_id + preQuiz or postQuiz at end
          'quiz_type': 'pre_quiz'.toLowerCase(),
          'question_responses': answers, // Supabase will automatically convert to JSON
          'num_correct_answers': correctAnswers,
          'total_questions': totalQuestions,
          'started_at': startTime.toIso8601String(),
          'completed_at': DateTime.now().toIso8601String(),
        };

        // Insert into database
        await _supabase
            .from('quiz_attempts')
            .insert(attemptData)
            .select('id') // Return the ID of the created record
            .single();
      }
      else {
        throw Exception('Missing pre_quiz or post_quiz type');
      }


    } catch (e) {
      throw Exception('CourseRepository SaveQuizAttempt(): Failed to save quiz progress: $e');
    }
  }


  // ---------------- READ ----------------


  // === User Class Operations ===

  /// Get the class that a user is enrolled in
  Future<Map<String, dynamic>?> getUserClass(String userId) async {
    try {
      final userResponse = await _supabase
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
      final classResponse = await _supabase
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
      final classResponse = await _supabase
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
      final moduleResponse = await _supabase
          .from('modules')
          .select()
          .eq('id', moduleId)
          .single();

      return Map<String, dynamic>.from(moduleResponse);
    } catch (e) {
      throw Exception('Failed to get module: $e');
    }
  }

  /// Get class assets
  Future<List<dynamic>?> getClassAssets(String classId) async {
    try {
      final classResponse = await _supabase
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

  /// Get all user progress data
  Future<Map<String, dynamic>?> getUserReadingProgress(String userId) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('reading_progress')
          .eq('id', userId)
          .single();

      return response['reading_progress'];
    } catch (e) {
      throw Exception('Failed to get user progress: $e');
    }
  }

  /// Get all the user's quiz attempts for a lesson
  Future<List<Map<String, dynamic>>> getUserQuizAttempts(String userId, String lessonId) async {
    try {
      final response = await _supabase
          .from('quiz_attempts')
          .select('*')
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .order('completed_at', ascending: true); // oldest first

      return List<Map<String, dynamic>>.from(response);

    } catch (e) {
      throw Exception('Failed to fetch quiz attempts: $e');
    }
  }


  // ---------------- UPDATE ----------------


  /// Save reading progress to database
  Future<void> saveReadingProgress({required String userId, required String lessonId, required Set<int> bookmarks,}) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('reading_progress')
          .eq('id', userId)
          .single();

      Map<String, dynamic> readingData = {};
      if (response['reading_progress'] != null) {
        readingData = Map<String, dynamic>.from(response['reading_progress']);
      }

      if (!readingData.containsKey(lessonId)) {
        readingData[lessonId] = {
          'reading': {
            'completed': false,
            'completed_at': null,
            'bookmarks': [],
          }
        };
      }

      // Update reading progress while preserving other fields
      final currentModule = readingData[lessonId] as Map<String, dynamic>;
      currentModule['reading'] = {
        'completed': true,
        'completed_at': DateTime.now().toIso8601String(),
        'bookmarks': bookmarks.toList(),
      };

      await _supabase
          .from('Users')
          .update({'reading_progress': readingData})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to save reading progress: $e');
    }
  }


  // ---------------- DELETE ----------------





}
