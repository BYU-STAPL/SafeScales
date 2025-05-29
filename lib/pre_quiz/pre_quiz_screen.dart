// =============================================================================
// PRE-QUIZ SCREEN FLOW - Assessment focused, formal,
// =============================================================================

import 'package:flutter/material.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_results_screen.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/config/supabase_config.dart';

import '../question/question_widget.dart';

class PreQuizScreen extends StatefulWidget {
  final QuestionSet questionSet;

  const PreQuizScreen({Key? key, required this.questionSet}) : super(key: key);

  @override
  _PreQuizScreenState createState() => _PreQuizScreenState();
}

class _PreQuizScreenState extends State<PreQuizScreen> {
  int currentQuestionIndex = 0;
  List<List<int>> userAnswers = [];
  bool isStarted = false;

  @override
  void initState() {
    super.initState();
    userAnswers = List.generate(widget.questionSet.questions.length, (_) => []);
  }

  void _startPreQuiz() {
    setState(() {
      isStarted = true;
    });
  }

  void _finishPreQuiz() async {
    print('=== Starting Pre-Quiz Completion ===');
    int correctAnswers = 0;
    for (int i = 0; i < widget.questionSet.questions.length; i++) {
      if (_isAnswerCorrect(i)) correctAnswers++;
    }

    int scorePercentage =
        ((correctAnswers / widget.questionSet.questions.length) * 100).round();

    print('Pre-quiz completed:');
    print('Quiz ID: ${widget.questionSet.id}');
    print('Total questions: ${widget.questionSet.questions.length}');
    print('Correct answers: $correctAnswers');
    print('Score percentage: $scorePercentage');
    print('User answers: $userAnswers');

    // Save quiz progress
    try {
      final supabase = SupabaseConfig.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        print('Saving pre-quiz progress for user: ${user.id}');
        await QuizService().saveQuizProgress(
          userId: user.id,
          quizId: widget.questionSet.id,
          answers: userAnswers,
        );
        print('Successfully saved quiz progress');
      } else {
        print('No user logged in, skipping pre-quiz progress save');
      }
    } catch (e) {
      print('Error saving pre-quiz progress: $e');
      // Continue to show results even if saving fails
    }

    // Navigate to results screen and return completion status
    final result = await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => PreQuizResultScreen(
              questionSet: widget.questionSet,
              score: scorePercentage,
              correctAnswers: correctAnswers,
              totalQuestions: widget.questionSet.questions.length,
              userAnswers: userAnswers,
            ),
      ),
    );

    print('Returning from results screen with status: $result');
    Navigator.pop(context, true); // Return true to indicate completion
  }

  bool _isAnswerCorrect(int questionIndex) {
    final question = widget.questionSet.questions[questionIndex];
    final userAnswer = userAnswers[questionIndex];

    if (userAnswer.length != question.correctAnswerIndices.length) return false;

    final sortedUser = List<int>.from(userAnswer)..sort();
    final sortedCorrect = List<int>.from(question.correctAnswerIndices)..sort();

    for (int i = 0; i < sortedUser.length; i++) {
      if (sortedUser[i] != sortedCorrect[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    AppBar appBar = AppBar(centerTitle: true, title: Text('Pre-Quiz'));

    if (!isStarted) {
      return Scaffold(
        appBar: appBar,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.questionSet.title,
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: 15),

              Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: theme.colorScheme.secondary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${widget.questionSet.questions.length} questions',
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.secondary,
                          ),
                          SizedBox(width: 8),
                          Expanded(child: Text(widget.questionSet.description)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    print('Starting pre-quiz...');
                    _startPreQuiz();
                  },
                  child: Text(
                    'Start'.toUpperCase(),
                    style: TextStyle(
                      fontSize: theme.textTheme.bodyLarge?.fontSize,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: Column(
          children: [
            LinearProgressIndicator(
              value:
                  (currentQuestionIndex + 1) /
                  widget.questionSet.questions.length,
              backgroundColor: theme.colorScheme.tertiary,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 15,
              borderRadius: BorderRadius.circular(10),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: QuestionWidget(
                  question: widget.questionSet.questions[currentQuestionIndex],
                  selectedAnswers: userAnswers[currentQuestionIndex],
                  onAnswerChanged: (answers) {
                    print(
                      'Answer changed for question ${currentQuestionIndex + 1}: $answers',
                    );
                    setState(() {
                      userAnswers[currentQuestionIndex] = answers;
                    });
                  },
                  showCorrectAnswer: widget.questionSet.showCorrectAnswers,
                  showExplanation: widget.questionSet.showExplanations,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  if (currentQuestionIndex > 0)
                    IconButton(
                      onPressed: () {
                        print('Moving to previous question');
                        setState(() {
                          currentQuestionIndex--;
                        });
                      },
                      iconSize: 30,
                      icon: Icon(Icons.arrow_back_ios_rounded),
                    ),
                  Spacer(),
                  if (currentQuestionIndex ==
                      widget.questionSet.questions.length - 1)
                    TextButton(
                      onPressed:
                          userAnswers[currentQuestionIndex].isNotEmpty
                              ? () {
                                print('Submit button pressed on last question');
                                print('Current answers: $userAnswers');
                                _finishPreQuiz();
                              }
                              : null,
                      child: Text(
                        'Submit'.toUpperCase(),
                        style: TextStyle(
                          fontSize: theme.textTheme.bodyLarge?.fontSize,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      onPressed:
                          userAnswers[currentQuestionIndex].isNotEmpty
                              ? () {
                                print('Moving to next question');
                                setState(() {
                                  currentQuestionIndex++;
                                });
                              }
                              : null,
                      iconSize: 30,
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color:
                            userAnswers[currentQuestionIndex].isEmpty
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
