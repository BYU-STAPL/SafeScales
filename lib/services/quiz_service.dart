import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/question/question.dart';

class QuizService {
  final supabase = SupabaseConfig.client;

  // Get all quizzes
  Future<List<Map<String, dynamic>>> getAllQuizzes() async {
    try {
      final response = await supabase
          .from('quizzes')
          .select()
          .order('created_at', ascending: false);

      // Group quizzes by topic
      final Map<String, List<Map<String, dynamic>>> groupedByTopic = {};

      for (var quiz in response) {
        final topic = quiz['topic'] ?? 'Unknown Topic';
        if (!groupedByTopic.containsKey(topic)) {
          groupedByTopic[topic] = [];
        }
        groupedByTopic[topic]!.add(quiz);
      }

      // Convert to a flat list with topic information
      final List<Map<String, dynamic>> result = [];

      groupedByTopic.forEach((topic, quizzes) {
        // Add a single entry for each topic
        if (quizzes.isNotEmpty) {
          result.add({
            'topic': topic,
            'id': quizzes[0]['id'],
            'title': quizzes[0]['title'] ?? topic,
            'description': quizzes[0]['description'] ?? 'Learn about $topic',
            'has_pre_quiz': quizzes.any((q) => q['activity_type'] == 'preQuiz'),
            'has_post_quiz': quizzes.any(
              (q) => q['activity_type'] == 'postQuiz',
            ),
            'created_at': quizzes[0]['created_at'],
          });
        }
      });

      return result;
    } catch (e) {
      throw Exception('Failed to fetch quizzes: $e');
    }
  }

  // Get quiz by ID with questions
  Future<QuestionSet?> getQuizWithQuestions(String quizId) async {
    try {
      // Fetch quiz details
      final quizResponse =
          await supabase.from('quizzes').select().eq('id', quizId).single();

      // Fetch questions for this quiz
      final questionsResponse = await supabase
          .from('questions')
          .select()
          .eq('quiz_id', quizId)
          .order('order_index', ascending: true);

      // Convert to Question objects
      final questions =
          (questionsResponse as List).map((q) {
            return Question(
              id: q['id'],
              text: q['text'],
              questionText: q['question_text'],
              options: List<String>.from(q['options']),
              correctAnswerIndices: List<int>.from(q['correct_answer_indices']),
              isMultipleChoice: q['is_multiple_choice'],
              explanation: q['explanation'],
            );
          }).toList();

      // Convert activity type string back to enum
      final activityTypeString = quizResponse['activity_type'];
      final activityType = ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == activityTypeString,
      );

      // Create QuestionSet
      return QuestionSet(
        id: quizResponse['id'],
        title: quizResponse['title'],
        description: quizResponse['description'],
        activityType: activityType,
        subject: quizResponse['subject'],
        passingScore: quizResponse['passing_score'],
        showResults: quizResponse['show_results'],
        showCorrectAnswers: quizResponse['show_correct_answers'],
        showExplanations: quizResponse['show_explanations'],
        allowRetakes: quizResponse['allow_retakes'],
        questions: questions,
      );
    } catch (e) {
      print('Error fetching quiz: $e');
      return null;
    }
  }

  // Get quizzes by subject/topic
  Future<List<Map<String, dynamic>>> getQuizzesBySubject(String subject) async {
    try {
      final response = await supabase
          .from('quizzes')
          .select()
          .eq('subject', subject)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch quizzes by subject: $e');
    }
  }

  // New method to get quiz by topic and activity type from single table structure
  Future<QuestionSet?> getQuizByTopicAndActivityType({
    required String topic,
    required String activityType,
  }) async {
    try {
      print('Fetching quiz for topic: $topic, activityType: $activityType');

      // Fetch quiz from the database
      final response =
          await supabase
              .from('quizzes')
              .select()
              .eq('topic', topic)
              .eq('activity_type', activityType)
              .single();

      print('Database response: $response');

      // Parse the questions JSON
      final questionsJson = response['questions'] as List<dynamic>?;
      print('Questions JSON: $questionsJson');

      if (questionsJson == null) {
        print('No questions found in the quiz');
        return null;
      }

      // Convert JSON questions to Question objects
      final questions =
          questionsJson.map((q) {
            print('Processing question: $q');
            final questionMap = q as Map<String, dynamic>;
            final questionType = questionMap['question_type'] ?? 'single';

            if (questionType == 'single') {
              // Single answer question
              final correctAnswer = questionMap['correctAnswer'] as String;
              final options = List<String>.from(questionMap['options']);
              final correctIndex = options.indexOf(correctAnswer);

              return Question.singleAnswer(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                questionText: questionMap['question'] ?? '',
                options: options,
                correctAnswerIndex: correctIndex >= 0 ? correctIndex : 0,
                explanation: questionMap['explanation'] ?? '',
              );
            } else {
              // Multiple answer question
              final correctAnswers = List<String>.from(
                questionMap['correctAnswer'],
              );
              final options = List<String>.from(questionMap['options']);
              final correctIndices =
                  correctAnswers
                      .map((answer) => options.indexOf(answer))
                      .where((index) => index >= 0)
                      .toList();

              return Question.multipleAnswer(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                questionText: questionMap['question'] ?? '',
                options: options,
                correctAnswerIndices:
                    correctIndices.isNotEmpty ? correctIndices : [0],
                explanation: questionMap['explanation'] ?? '',
              );
            }
          }).toList();

      print('Converted questions: $questions');

      // Convert activity type string to enum
      final activityTypeEnum = ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == activityType,
        orElse: () => ActivityType.preQuiz,
      );

      // Create QuestionSet
      final questionSet = QuestionSet(
        id: response['id']?.toString() ?? '',
        title: response['title'] ?? '',
        description: response['description'] ?? '',
        activityType: activityTypeEnum,
        subject: response['subject'] ?? topic,
        passingScore: response['passing_score'] ?? 80,
        showResults: response['show_results'] ?? true,
        showCorrectAnswers:
            response['show_correct_answers'] ??
            (activityType == 'preQuiz' ? false : true),
        showExplanations:
            response['show_explanations'] ??
            (activityType == 'preQuiz' ? false : true),
        allowRetakes: response['allow_retakes'] ?? true,
        questions: questions,
      );

      print('Created QuestionSet with ID: ${questionSet.id}');
      print('Database quiz ID: ${response['id']}');
      return questionSet;
    } catch (e) {
      print('Error fetching quiz by topic and activity type: $e');
      return null;
    }
  }

  // Save quiz progress for a user
  Future<void> saveQuizProgress({
    required String userId,
    required String quizId,
    required List<List<int>> answers,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
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
      print('Error saving quiz progress: $e');
      throw Exception('Failed to save quiz progress: $e');
    }
  }

  // Get quiz progress for a user
  Future<Map<String, List<List<int>>>> getQuizProgress(String userId) async {
    try {
      print('Getting quiz progress for user: $userId');

      final response =
          await supabase
              .from('users')
              .select('quizzes')
              .eq('id', userId)
              .single();

      print('Raw quiz progress data: ${response['quizzes']}');

      if (response['quizzes'] == null) {
        print('No quiz progress found for user');
        return {};
      }

      // Convert the JSONB data to a Map<String, List<List<int>>>
      final Map<String, dynamic> quizzesData = response['quizzes'];
      final result = quizzesData.map((key, value) {
        final List<dynamic> outerList = value as List;
        final List<List<int>> convertedList =
            outerList.map((innerList) {
              return List<int>.from(innerList as List);
            }).toList();
        return MapEntry(key, convertedList);
      });

      print('Converted quiz progress: $result');
      return result;
    } catch (e) {
      print('Error getting quiz progress: $e');
      throw Exception('Failed to get quiz progress: $e');
    }
  }

  // New method to get quiz by module ID
  Future<QuestionSet?> getQuizByModuleId({
    required String moduleId,
    required String activityType,
  }) async {
    try {
      print('Fetching quiz for module: $moduleId, activityType: $activityType');

      // Get module details
      final moduleResponse =
          await supabase.from('modules').select().eq('id', moduleId).single();

      if (moduleResponse == null) {
        print('No module found with ID: $moduleId');
        return null;
      }

      print('Module response: $moduleResponse');

      // Get quiz data based on activity type
      final quizData =
          activityType == 'preQuiz'
              ? moduleResponse['pre_quiz']
              : moduleResponse['post_quiz'];

      if (quizData == null || quizData['questions'] == null) {
        print('No $activityType found for module: $moduleId');
        return null;
      }

      // Convert quiz data to QuestionSet
      final questionsJson = quizData['questions'] as List<dynamic>;
      final questions =
          questionsJson.map((q) {
            final questionMap = q as Map<String, dynamic>;

            // Get the answer index from the answer field
            final answerIndex =
                int.tryParse(questionMap['answer']?.toString() ?? '0') ?? 0;

            // Get choices and filter out empty ones
            List<String> choices = [];
            if (questionMap['choices'] != null) {
              choices =
                  (questionMap['choices'] as List)
                      .map((c) => c?.toString() ?? '')
                      .where((c) => c.isNotEmpty)
                      .toList();
            }

            if (choices.isEmpty) {
              choices = ['Option A', 'Option B', 'Option C', 'Option D'];
            }

            return Question.singleAnswer(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              questionText: questionMap['question'] ?? 'Question',
              options: choices,
              correctAnswerIndex: answerIndex,
              explanation: '',
            );
          }).toList();

      // Convert activity type string to enum
      final activityTypeEnum =
          activityType == 'preQuiz'
              ? ActivityType.preQuiz
              : ActivityType.postQuiz;

      // Create QuestionSet with module ID as the quiz ID
      final questionSet = QuestionSet(
        id: '${moduleId}_${activityType}', // Unique ID for this quiz
        title: moduleResponse['title'] ?? 'Module Quiz',
        description: '',
        activityType: activityTypeEnum,
        subject: moduleResponse['title'] ?? 'Module',
        passingScore: 80,
        showResults: true,
        showCorrectAnswers: activityType == 'preQuiz' ? false : true,
        showExplanations: activityType == 'preQuiz' ? false : true,
        allowRetakes: true,
        questions: questions,
      );

      print('Created QuestionSet with ID: ${questionSet.id}');
      return questionSet;
    } catch (e) {
      print('Error fetching quiz by module ID: $e');
      return null;
    }
  }

  // Get module progress for a user
  Future<Map<String, double>> getModuleProgress({
    required String userId,
    required List<String> moduleIds,
  }) async {
    try {
      final Map<String, double> moduleProgress = {};

      // Get user's quiz progress from both old and new columns
      final response =
          await supabase
              .from('Users')
              .select('quizzes, modules')
              .eq('id', userId)
              .single();

      // Check new modules column first (preferred)
      if (response['modules'] != null) {
        final modulesData = Map<String, dynamic>.from(response['modules']);

        for (var moduleId in moduleIds) {
          if (modulesData.containsKey(moduleId)) {
            final moduleData = Map<String, dynamic>.from(modulesData[moduleId]);

            double preQuizScore = 0;
            double postQuizScore = 0;
            bool hasPreQuiz = false;
            bool hasPostQuiz = false;

            // Check for pre-quiz score
            if (moduleData.containsKey('preQuiz')) {
              preQuizScore = (moduleData['preQuiz']['score'] ?? 0).toDouble();
              hasPreQuiz = true;
            }

            // Check for post-quiz score
            if (moduleData.containsKey('postQuiz')) {
              postQuizScore = (moduleData['postQuiz']['score'] ?? 0).toDouble();
              hasPostQuiz = true;
            }

            //TODO: Will need to move and improve logic, moduleProgress shouldn't be based on quiz score
            //TODO: This is a temp fix
            // Calculate progress
            double progress = 0;


            bool isReadingComplete = moduleData['reading']['completed'];
            bool isPreQuizComplete = moduleData['preQuiz']['completed_at'] != null;
            bool isPostQuizComplete = moduleData['postQuiz']['completed_at'] != null && moduleData['postQuiz']['score'] > 80;

            print("---------Calulate Progress---------");
            print(isReadingComplete);
            print(isPreQuizComplete);
            print(isPostQuizComplete);

            if (isPreQuizComplete) {
              progress += 1/3 * 100;
            }

            if (isReadingComplete) {
              progress += 1/3 * 100;
            }

            if (isPostQuizComplete) {
              progress += 1/3 * 100;
            }


            // if (hasPreQuiz && hasPostQuiz) {
            //   progress = (preQuizScore / 2) + (postQuizScore / 2);
            // } else if (hasPreQuiz) {
            //   progress = preQuizScore / 2;
            // } else if (hasPostQuiz) {
            //   progress = postQuizScore / 2;
            // }

            moduleProgress[moduleId] = progress;
          }
        }
      }

      // Fallback to old quizzes column for modules not found in new column
      if (response['quizzes'] != null) {
        final quizzesData = Map<String, dynamic>.from(response['quizzes']);

        for (var moduleId in moduleIds) {
          // Skip if already found in modules column
          if (moduleProgress.containsKey(moduleId)) continue;

          double preQuizScore = 0;
          double postQuizScore = 0;
          bool hasPreQuiz = false;
          bool hasPostQuiz = false;

          // Check for pre-quiz score using old format
          final preQuizId = '${moduleId}_preQuiz';
          if (quizzesData.containsKey(preQuizId)) {
            preQuizScore = (quizzesData[preQuizId]['score'] ?? 0).toDouble();
            hasPreQuiz = true;
          }

          // Check for post-quiz score using old format
          final postQuizId = '${moduleId}_postQuiz';
          if (quizzesData.containsKey(postQuizId)) {
            postQuizScore = (quizzesData[postQuizId]['score'] ?? 0).toDouble();
            hasPostQuiz = true;
          }

          // Calculate progress
          double progress = 0;
          if (hasPreQuiz && hasPostQuiz) {
            progress = (preQuizScore / 2) + (postQuizScore / 2);
          } else if (hasPreQuiz) {
            progress = preQuizScore / 2;
          } else if (hasPostQuiz) {
            progress = postQuizScore / 2;
          }

          if (progress > 0) {
            moduleProgress[moduleId] = progress;
          }
        }
      }

      return moduleProgress;
    } catch (e) {
      print('Error getting module progress: $e');
      return {};
    }
  }
}
