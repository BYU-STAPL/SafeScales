import '../config/supabase_config.dart';
import '../models/lesson_progress.dart';
import '../models/question.dart';
import 'class_service.dart';

class UserProgressService {
  final supabase = SupabaseConfig.client;

  // === Helpers ===
  List<List<int>> _parseResponses(List<dynamic> answers) {
    List<List<int>> responses = [];

    for (final answer in answers) {
      if (answer is List) {
        responses.add(List<int>.from(answer));
      } else {
        responses.add([]); // Empty response for null/invalid answers
      }
    }

    return responses;
  }

  /// Get progress for all lessons
  Future<Map<String, LessonProgress>> loadLessonProgress(String userId) async {

    ClassService _classService = ClassService(supabase);
    final classData = await _classService.getUserClass(userId);
    if (classData.isEmpty) {
      print("Error: No class data");
      return {};
    }
    final lessonsInClass = await _classService.getLessonOrder(classData['id']);


    try {
      final response = await supabase
          .from('Users')
          .select('modules')
          .eq('id', userId)
          .single();

      Map<String, LessonProgress> progress = {};

      final moduleMap = response['modules'];

      // For each lesson get all quizzes for it
      for (var key in moduleMap.keys) {
        final lessonId = key;

        // Don't look at legacy
        if (lessonId == 'legacy') continue;

        // Don't look at progress if lesson is not in the current class
        if (!lessonsInClass.contains(lessonId)) continue;

        final quizMap = moduleMap[lessonId];

        QuizAttempt? preQuizAttempt = null;
        List<QuizAttempt> postQuizAttempts = [];
        bool isReadingComplete = false;

        // For each quiz build the attempt
        for (var type in quizMap.keys) {
          // Get Type
          ActivityType activityType;

          switch (type) {
            case 'preQuiz':
              activityType = ActivityType.preQuiz;
              break;
            case 'postQuiz':
              activityType = ActivityType.postQuiz;
              break;
            case 'review':
              activityType = ActivityType.review;
              break;
            case 'reading':
              activityType = ActivityType.reading;
              break;
            default:
              activityType = ActivityType.reading;
              break;
          }

          // Get Data
          final activityData = quizMap[type] as Map<String, dynamic>;

          if (activityType == ActivityType.reading) {
            isReadingComplete = activityData['completed'];
          }
          else {
            // Either preQuiz, postQuiz, or reviewQuiz
            QuizAttempt attempt = QuizAttempt(
              id: '',
              quizId: '${key}_${type}',
              lessonId: lessonId,
              type: activityType,
              score: activityData['score'] ?? 0.0, // Access from activityData
              correctAnswers: activityData['correct_answers'] ?? 0,
              totalQuestions: activityData['total_questions'] ?? 0,
              responses: _parseResponses(activityData['answers'] ?? []),
              completedAt: DateTime.parse(activityData['completed_at']),
              // attemptNumber: attemptNumber,
              // passed: passed
            );

            if (activityType == ActivityType.postQuiz) {
              postQuizAttempts.add(attempt);
            }
            else if (activityType == ActivityType.preQuiz) {
              preQuizAttempt = attempt;
            }
          }
        }

        progress[lessonId] = LessonProgress(
          lessonId: lessonId,
          isReadingComplete: isReadingComplete,
          preQuizAttempt: preQuizAttempt,
          postQuizAttempts: postQuizAttempts,
        );
      }

      return progress;

    } catch (e) {
      print('❌ Error loading quiz scores: $e');
      return {};
    }
  }

  /// Get progress for one lesson by lesson id
  Future<LessonProgress?> loadSingleLessonProgress(String userId, String lessonId) async {
    ClassService _classService = ClassService(supabase);

    // First verify the lesson is in the user's class
    final classData = await _classService.getUserClass(userId);
    if (classData.isEmpty) {
      print("Error: No class data");
      return null;
    }

    final lessonsInClass = await _classService.getLessonOrder(classData['id']);
    if (!lessonsInClass.contains(lessonId)) {
      print("Lesson is not in current class");
      return null; // Lesson not in current class
    }

    try {
      // Query only the specific lesson's progress using JSON path
      final response = await supabase
          .from('Users')
          .select('modules')
          // .eq('moduleId', lessonId) TODO: Add something to just get one lesson from database
          .eq('id', userId)
          .single();


      final lessonData = response['modules'];

      if (lessonData == null || lessonData[lessonId] == null) {
        return null; // No progress data for this lesson
      }

      final quizMap = lessonData[lessonId];

      QuizAttempt? preQuizAttempt;
      List<QuizAttempt> postQuizAttempts = [];
      bool isReadingComplete = false;

      // Process the lesson data (same logic as your original)
      for (var type in quizMap.keys) {
        ActivityType activityType;

        switch (type) {
          case 'preQuiz':
            activityType = ActivityType.preQuiz;
            break;
          case 'postQuiz':
            activityType = ActivityType.postQuiz;
            break;
          case 'review':
            activityType = ActivityType.review;
            break;
          case 'reading':
            activityType = ActivityType.reading;
            break;
          default:
            activityType = ActivityType.reading;
            break;
        }

        final activityData = quizMap[type] as Map<String, dynamic>;

        if (activityType == ActivityType.reading) {
          isReadingComplete = activityData['completed'];
        } else {
          QuizAttempt attempt = QuizAttempt(
            id: '',
            quizId: '${lessonId}_${type}',
            lessonId: lessonId,
            type: activityType,
            score: activityData['score'] ?? 0,
            correctAnswers: activityData['correct_answers'] ?? 0,
            totalQuestions: activityData['total_questions'] ?? 0,
            responses: _parseResponses(activityData['answers'] ?? []),
            completedAt: DateTime.parse(activityData['completed_at']),
          );

          if (activityType == ActivityType.postQuiz) {
            postQuizAttempts.add(attempt);
          } else if (activityType == ActivityType.preQuiz) {
            preQuizAttempt = attempt;
          }
        }
      }

      return LessonProgress(
        lessonId: lessonId,
        isReadingComplete: isReadingComplete,
        preQuizAttempt: preQuizAttempt,
        postQuizAttempts: postQuizAttempts,
      );

    } catch (e) {
      print('❌ Error loading lesson progress: $e');
      return null;
    }
  }

  /// Save Quiz Progress
  Future<void> saveQuizProgress({required String userId, required String quizId, required List<List<int>> answers, required int correctAnswers, required int totalQuestions,}) async {
    try {
      // Calculate score percentage
      final score = ((correctAnswers / totalQuestions) * 100).round();

      // Get current user data
      final response =
      await supabase
          .from('Users')
          .select('quizzes, modules')
          .eq('id', userId)
          .single();

      // Update existing quizzes column (for backward compatibility)
      Map<String, dynamic> quizzes = {};
      if (response['quizzes'] != null) {
        quizzes = Map<String, dynamic>.from(response['quizzes']);
      }

      // Update quiz data in quizzes column
      quizzes[quizId] = {
        'score': score,
        'answers': answers,
        'completed_at': DateTime.now().toIso8601String(),
        'correct_answers': correctAnswers,
        'total_questions': totalQuestions,
      };

      // Update new modules column
      Map<String, dynamic> modules = {};
      if (response['modules'] != null) {
        modules = Map<String, dynamic>.from(response['modules']);
      }

      // Extract module ID and quiz type from quiz ID
      // Quiz ID format: "{moduleId}_{quizType}" (e.g., "module1_preQuiz")
      String moduleId;
      String quizType;

      print('QUIZ ID: $quizId');
      if (quizId.contains('_')) {
        final parts = quizId.split('_');
        moduleId = parts[0];
        quizType = parts.length > 1 ? parts[1] : 'quiz';
      } else {
        // Fallback for old quiz IDs that don't follow the module format
        moduleId = 'legacy';
        quizType = quizId;
      }

      // Initialize module entry if it doesn't exist
      if (!modules.containsKey(moduleId)) {
        modules[moduleId] = {};
      }

      // Save quiz data in modules format: module_id -> quiz_type -> data
      modules[moduleId][quizType] = {
        'answers': answers,
        'score': score,
        'completed_at': DateTime.now().toIso8601String(),
        'correct_answers': correctAnswers,
        'total_questions': totalQuestions,
      };

      // Save updated data to both columns
      await supabase
          .from('Users')
          .update({'quizzes': quizzes, 'modules': modules})
          .eq('id', userId);

      print('Successfully saved quiz progress for quiz $quizId');
      print(
        'Saved to modules[$moduleId][$quizType]: ${modules[moduleId][quizType]}',
      );
    } catch (e) {
      print('❌Error saving quiz progress: $e');
      throw Exception('Failed to save quiz progress: $e');
    }
  }


  /// Save Reading Progress
  Future<void> saveReadingProgress({required String userId, required String lessonId, required Set<int> bookmarks}) async {
    try {
      ClassService _classService = ClassService(supabase);

      final response = await _classService.supabase
          .from('Users')
          .select('modules')
          .eq('id', userId)
          .single();

      Map<String, dynamic> modulesData = {};
      if (response['modules'] != null) {
        modulesData = Map<String, dynamic>.from(response['modules']);
      }

      if (!modulesData.containsKey(lessonId)) {
        modulesData[lessonId] = {};
      }

      modulesData[lessonId]['reading'] = {
        'completed': true,
        'completed_at': DateTime.now().toIso8601String(),
        'bookmarks': bookmarks.toList(),
      };

      await _classService.supabase
          .from('Users')
          .update({'modules': modulesData})
          .eq('id', userId);

    } catch (e) {
      print('❌CourseProgressProvider: Error saving reading progress: $e');
      rethrow; // Re-throw to be caught by _markAsCompleted
    }
  }

}