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

      if (response == null) {
        print('No quiz found for topic: $topic, activityType: $activityType');
        return null;
      }

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

      print('Created QuestionSet: $questionSet');
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
  }) async {
    try {
      print('Saving quiz progress for user: $userId, quiz: $quizId');
      print('Answers to save: $answers');

      // First get the current quizzes data
      final response =
          await supabase
              .from('users')
              .select('quizzes')
              .eq('id', userId)
              .single();

      print('Current quizzes data from DB: ${response['quizzes']}');

      // Parse existing quizzes data or initialize empty map
      Map<String, dynamic> quizzesData = {};
      if (response['quizzes'] != null) {
        quizzesData = Map<String, dynamic>.from(response['quizzes']);
      }

      // Update or add the new quiz data
      quizzesData[quizId] = answers;

      print('Updated quizzes data to save: $quizzesData');

      // Update the user's quizzes column
      final updateResponse = await supabase
          .from('users')
          .update({'quizzes': quizzesData})
          .eq('id', userId);

      print('Update response: $updateResponse');
      print('Successfully saved quiz progress');
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
}
