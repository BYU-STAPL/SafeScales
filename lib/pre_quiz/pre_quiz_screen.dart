// =============================================================================
// PRE-QUIZ SCREEN FLOW - Assessment focused, formal,
// =============================================================================

import 'package:flutter/material.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_results_screen.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/services/user_state_service.dart';

import '../components/progress_bar.dart';
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
  final _userState = UserStateService();

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

    int totalQuestions = widget.questionSet.questions.length;
    int scorePercentage = ((correctAnswers / totalQuestions) * 100).round();

    print('Pre-quiz completed:');
    print('Quiz ID: ${widget.questionSet.id}');
    print('Total questions: $totalQuestions');
    print('Correct answers: $correctAnswers');
    print('Score percentage: $scorePercentage');
    print('User answers: $userAnswers');

    // Save quiz progress
    try {
      final user = _userState.currentUser;
      if (user != null) {
        print('Saving pre-quiz progress for user: ${user.id}');
        await QuizService().saveQuizProgress(
          userId: user.id,
          quizId: widget.questionSet.id,
          answers: userAnswers,
          correctAnswers: correctAnswers,
          totalQuestions: totalQuestions,
        );
        print('Successfully saved quiz progress');
      } else {
        print('No user logged in, skipping pre-quiz progress save');
      }
    } catch (e) {
      print('Error saving pre-quiz progress: $e');
      // Continue to show results even if saving fails
    }

    if (!mounted) return;

    // Show results screen and then return to previous screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PreQuizResultScreen(
              questionSet: widget.questionSet,
              score: scorePercentage,
              correctAnswers: correctAnswers,
              totalQuestions: totalQuestions,
              userAnswers: userAnswers,
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


  void _nextQuestion() {
    if (currentQuestionIndex < widget.questionSet.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      _finishPreQuiz();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  Container _buildNavigationBar() {

    ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: currentQuestionIndex > 0 ? _previousQuestion : null,
            icon: const Icon(Icons.arrow_back_ios_rounded),
            label: const Text('Previous'),
          ),

          TextButton.icon(
            iconAlignment: IconAlignment.end,
            onPressed: userAnswers[currentQuestionIndex].isNotEmpty ? _nextQuestion : null,
            label: Text(
              currentQuestionIndex == widget.questionSet.questions.length - 1
                  ? 'Complete'
                  : 'Next',
            ),
            icon: Icon(Icons.arrow_forward_ios_rounded),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    AppBar appBar = AppBar(centerTitle: true, title: Text('Pre-Quiz'));

    if (!isStarted) {
      return Scaffold(
        appBar: appBar,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 25),
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
                      fontSize: theme.textTheme.bodyMedium?.fontSize,
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

    final progress = (currentQuestionIndex + 1) / widget.questionSet.questions.length;

    return Scaffold(
      appBar: appBar,
      body: Column(
          children: [

            ProgressBar(
              progress: progress,
              currentSlideIndex: currentQuestionIndex,
              slideLength: widget.questionSet.questions.length,
              slideName: 'questions',
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
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
                  isResponseLocked: false,
                ),
              ),
            ),

            _buildNavigationBar(),

            SizedBox(height: 15),
          ],
        ),
    );
  }
}
