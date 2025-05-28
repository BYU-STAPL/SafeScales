// =============================================================================
// PRE-QUIZ SCREEN FLOW - Assessment focused, formal,
// =============================================================================

import 'package:flutter/material.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_results_screen.dart';
import 'package:safe_scales/question/question.dart';

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

  void _finishPreQuiz() {

    int correctAnswers = 0;
    for (int i = 0; i < widget.questionSet.questions.length; i++) {
      if (_isAnswerCorrect(i)) correctAnswers++;
    }

    int scorePercentage = ((correctAnswers / widget.questionSet.questions.length) * 100).round();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PreQuizResultScreen(
          questionSet: widget.questionSet,
          score: scorePercentage,
          correctAnswers: correctAnswers,
          totalQuestions: widget.questionSet.questions.length,
          userAnswers: userAnswers,
        ),
      ),
    );
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

    // TODO: Is there a different way to access the Theme?
    ThemeData theme = Theme.of(context);

    AppBar appBar = AppBar(
      centerTitle: true,
      title: Text('Pre-Quiz'),
      // backgroundColor: Colors.orange,
    );

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
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.help_outline, color: theme.colorScheme.secondary),
                          SizedBox(width: 8),
                          Text('${widget.questionSet.questions.length} questions'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: theme.colorScheme.secondary),
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
                  onPressed: _startPreQuiz,
                  child: Text(
                    'Start'.toUpperCase(),
                    style: TextStyle(
                      fontSize: theme.textTheme.bodyLarge?.fontSize,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
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
              value: (currentQuestionIndex + 1) / widget.questionSet.questions.length,
              backgroundColor: theme.colorScheme.tertiary,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
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
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentQuestionIndex--;
                        });
                      },
                      child: Text('Previous'),
                    ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: userAnswers[currentQuestionIndex].isNotEmpty
                        ? () {
                      if (currentQuestionIndex < widget.questionSet.questions.length - 1) {
                        setState(() {
                          currentQuestionIndex++;
                        });
                      } else {
                        _finishPreQuiz();
                      }
                    }
                        : null,
                    child: Text(
                      currentQuestionIndex == widget.questionSet.questions.length - 1
                          ? 'Finish'
                          : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}