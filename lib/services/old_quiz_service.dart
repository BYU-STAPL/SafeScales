import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/models/question.dart';

class OldQuizService {
  final supabase = SupabaseConfig.client;

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
      print('❌Error fetching quiz: $e');
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
  Future<QuestionSet?> getQuizByTopicAndActivityType({required String topic, required String activityType,}) async {
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

      // Parse the questions JSON
      final questionsJson = response['questions'] as List<dynamic>?;

      if (questionsJson == null) {
        print('No questions found in the quiz');
        return null;
      }

      // Convert JSON questions to Question objects
      final questions =
          questionsJson.map((q) {
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

      return questionSet;
    } catch (e) {
      print('❌Error fetching quiz by topic and activity type: $e');
      return null;
    }
  }

  // New method to get quiz by module ID
  Future<QuestionSet?> getQuizByModuleId({required String moduleId, required String activityType,}) async {
    try {
      // Get module details
      final moduleResponse =
          await supabase.from('modules').select().eq('id', moduleId).single();

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

      // Get minimum passing grade from module for postQuiz, default to 80
      int passingScore = 80;
      if (activityType == 'postQuiz') {
        passingScore =
            moduleResponse['minimum_passing_grade'] != null
                ? int.tryParse(
                      moduleResponse['minimum_passing_grade'].toString(),
                    ) ??
                    80
                : 80;
      }

      // Create QuestionSet with module ID as the quiz ID
      final questionSet = QuestionSet(
        id: '${moduleId}_${activityType}', // Unique ID for this quiz
        title: moduleResponse['title'] ?? 'Module Quiz',
        description: '',
        activityType: activityTypeEnum,
        subject: moduleResponse['title'] ?? 'Module',
        passingScore: passingScore,
        showResults: true,
        showCorrectAnswers: activityType == 'preQuiz' ? false : true,
        showExplanations: activityType == 'preQuiz' ? false : true,
        allowRetakes: true,
        questions: questions,
      );

      return questionSet;
    } catch (e) {
      print('❌Error fetching quiz by module ID: $e');
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

        // Fetch all module minimum_passing_grade values in one query
        final moduleDetailsResponse = await supabase
            .from('modules')
            .select('id, minimum_passing_grade')
            .inFilter('id', moduleIds);
        final Map<String, int> modulePassingScores = {};
        for (final mod in moduleDetailsResponse) {
          if (mod['id'] != null) {
            modulePassingScores[mod['id'].toString()] =
                mod['minimum_passing_grade'] != null
                    ? int.tryParse(mod['minimum_passing_grade'].toString()) ??
                        80
                    : 80;
          }
        }

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

            // Calculate progress
            double progress = 0;

            bool isReadingComplete =
                moduleData['reading']?['completed'] == true;
            bool isPreQuizComplete =
                moduleData['preQuiz']?['completed_at'] != null;
            // Use correct passing score for post-quiz
            int passingScore = modulePassingScores[moduleId] ?? 80;
            bool isPostQuizComplete =
                moduleData['postQuiz']?['completed_at'] != null &&
                moduleData['postQuiz']?['score'] != null &&
                moduleData['postQuiz']['score'] >= passingScore;

            if (isPreQuizComplete) {
              progress += 1 / 3 * 100;
            }

            if (isReadingComplete) {
              progress += 1 / 3 * 100;
            }

            if (isPostQuizComplete) {
              progress += 1 / 3 * 100;
            }

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
      print('❌Error getting module progress: $e');
      return {};
    }
  }
}
