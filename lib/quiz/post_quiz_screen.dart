// =============================================================================
// PRE-QUIZ SCREEN FLOW - Assessment focused, formal,
// =============================================================================

import 'package:flutter/material.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_results_screen.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/quiz/post_quiz_results_screen.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/services/user_state_service.dart';

import '../question/question_widget.dart';

class PostQuizScreen extends StatefulWidget {
  final QuestionSet questionSet;

  const PostQuizScreen({Key? key, required this.questionSet}) : super(key: key);

  @override
  _PostQuizScreenState createState() => _PostQuizScreenState();
}

class _PostQuizScreenState extends State<PostQuizScreen> {
  int currentQuestionIndex = 0;
  List<List<int>> userAnswers = [];
  bool isStarted = false;
  final _userState = UserStateService();

  @override
  void initState() {
    super.initState();
    userAnswers = List.generate(widget.questionSet.questions.length, (_) => []);
  }

  void _startPostQuiz() {
    setState(() {
      isStarted = true;
    });
  }

  void _finishPostQuiz() async {
    print('=== Starting Post-Quiz Completion ===');
    int correctAnswers = 0;
    for (int i = 0; i < widget.questionSet.questions.length; i++) {
      if (_isAnswerCorrect(i)) correctAnswers++;
    }

    int totalQuestions = widget.questionSet.questions.length;
    int scorePercentage = ((correctAnswers / totalQuestions) * 100).round();

    print('Post-quiz completed:');
    print('Quiz ID: ${widget.questionSet.id}');
    print('Total questions: $totalQuestions');
    print('Correct answers: $correctAnswers');
    print('Score percentage: $scorePercentage');
    print('User answers: $userAnswers');

    // Save quiz progress
    try {
      final user = _userState.currentUser;
      if (user != null) {
        print('Saving post-quiz progress for user: ${user.id}');
        await QuizService().saveQuizProgress(
          userId: user.id,
          quizId: widget.questionSet.id,
          answers: userAnswers,
          correctAnswers: correctAnswers,
          totalQuestions: totalQuestions,
        );
        print('Successfully saved quiz progress');
      } else {
        print('No user logged in, skipping post-quiz progress save');
      }
    } catch (e) {
      print('Error saving post-quiz progress: $e');
      // Continue to show results even if saving fails
    }

    if (!mounted) return;

    // Show results screen and then return to previous screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PostQuizResultScreen(
              questionSet: widget.questionSet,
              score: scorePercentage,
              correctAnswers: correctAnswers,
              totalQuestions: totalQuestions,
              userAnswers: userAnswers,
              passingScore: widget.questionSet.passingScore,
            ),
      ),
    );

    if (!mounted) return;

    // Return to previous screen with completion status
    Navigator.pop(context, true);
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

    AppBar appBar = AppBar(centerTitle: true, title: Text('Post-Quiz'));

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
                      SizedBox(height: 10),

                      Text(
                        '${widget.questionSet.passingScore}% or higher is required to pass',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: theme.colorScheme.secondary,
                          ),
                          SizedBox(width: 10),
                          Text(
                            '${widget.questionSet.questions.length} questions',
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.secondary,
                          ),
                          SizedBox(width: 10),
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
                  onPressed: _startPostQuiz,
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
              backgroundColor: theme.colorScheme.primaryContainer,
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
                        setState(() {
                          currentQuestionIndex--;
                        });
                      },
                      iconSize: 30,
                      icon: Icon(Icons.arrow_back_ios_rounded),
                    ),
                  Spacer(),

                  currentQuestionIndex ==
                          widget.questionSet.questions.length - 1
                      ? TextButton(
                        onPressed:
                            userAnswers[currentQuestionIndex].isNotEmpty
                                ? () {
                                  if (currentQuestionIndex <
                                      widget.questionSet.questions.length - 1) {
                                    setState(() {
                                      currentQuestionIndex++;
                                    });
                                  } else {
                                    _finishPostQuiz();
                                  }
                                }
                                : null,
                        child: Text(
                          'Submit'.toUpperCase(),
                          style: TextStyle(
                            fontSize: theme.textTheme.bodyLarge?.fontSize,
                          ),
                        ),
                      )
                      : IconButton(
                        onPressed:
                            userAnswers[currentQuestionIndex].isNotEmpty
                                ? () {
                                  if (currentQuestionIndex <
                                      widget.questionSet.questions.length - 1) {
                                    setState(() {
                                      currentQuestionIndex++;
                                    });
                                  } else {
                                    _finishPostQuiz();
                                  }
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
