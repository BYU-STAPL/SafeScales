import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/extensions/string_extensions.dart';
import 'package:safe_scales/themes/app_theme.dart';

import '../components/progress_bar.dart';
import '../question/question.dart';
import '../question/question_widget.dart';
import '../services/user_state_service.dart';

class ReviewScreen extends StatefulWidget {
  final QuestionSet questionSet;

  const ReviewScreen({
    super.key, required this.questionSet
  });

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int currentQuestionIndex = 0;
  List<List<int>> userAnswers = [];
  bool isStarted = false;
  final _userState = UserStateService();

  bool isCurrentQuestionCorrect = false;
  bool showAnswerMessage = false;
  List<List<List<int>>> attempts = [];

  @override
  void initState() {
    super.initState();
    userAnswers = List.generate(widget.questionSet.questions.length, (_) => []);
    attempts = List.generate(widget.questionSet.questions.length, (_) => []);
  }

  void _startReview() {
    setState(() {
      isStarted = true;
    });
  }

  void _finishReview() async {
    print('=== Starting Review Set Completion ===');
    // int correctAnswers = 0;
    // for (int i = 0; i < widget.questionSet.questions.length; i++) {
    //   if (_isAnswerCorrect(i)) correctAnswers++;
    // }
    //
    // int totalQuestions = widget.questionSet.questions.length;
    //
    // print('Review completed:');
    // print('Quiz ID: ${widget.questionSet.id}');
    // print('Total questions: $totalQuestions');
    // print('User answers: $userAnswers');
    //
    // // Save quiz progress
    // try {
    //   final user = _userState.currentUser;
    //   if (user != null) {
    //     print('Saving pre-quiz progress for user: ${user.id}');
    //     await ReviewService().saveQuizProgress(
    //       userId: user.id,
    //       quizId: widget.questionSet.id,
    //       answers: userAnswers,
    //       correctAnswers: correctAnswers,
    //       totalQuestions: totalQuestions,
    //     );
    //     print('Successfully saved review progress');
    //   } else {
    //     print('No user logged in, skipping review progress save');
    //   }
    // } catch (e) {
    //   print('Error saving review progress: $e');
    //   // Continue to show results even if saving fails
    // }
    //
    // if (!mounted) return;

    // Show results screen and then return to previous screen
    // await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder:
    //         (context) => ReviewResultScreen(
    //
    //     ),
    //   ),
    // );

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

  void _checkQuestion() {
    setState(() {
      attempts[currentQuestionIndex].add(userAnswers[currentQuestionIndex]);
    });

    if (_isAnswerCorrect(currentQuestionIndex)) {
      print("Correct Answer");
      setState(() {
        isCurrentQuestionCorrect = true;
        showAnswerMessage = true;
      });
    }
    else {
      isCurrentQuestionCorrect = false;
      setState(() {
        isCurrentQuestionCorrect = false;
        showAnswerMessage = true;
      });
    }

  }


  void _nextQuestion() {
    if (currentQuestionIndex < widget.questionSet.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        isCurrentQuestionCorrect = false;
        showAnswerMessage = false;
      });
    } else {
      _finishReview();
    }
  }

  // void _previousQuestion() {
  //   if (currentQuestionIndex > 0) {
  //     setState(() {
  //       currentQuestionIndex--;
  //     });
  //   }
  // }

  Container _buildNavigationBar() {

    ThemeData theme = Theme.of(context);

    //Decide what button to show and what function
    String forwardButtonText = 'Next';

    if (!isCurrentQuestionCorrect) {
      // Show check if not correct
      forwardButtonText = 'Check';

    }
    else if (currentQuestionIndex == widget.questionSet.questions.length - 1) {
      // Answer is correct, check if at end of review set
      forwardButtonText = 'Complete';
    }
    forwardButtonText.toTitleCase();


    //Decide what button function if user has an answer selected
    Function() onForwardTap;

    if (!isCurrentQuestionCorrect) {
      // Check Question if not correct
      onForwardTap = _checkQuestion;
    }
    else {
      onForwardTap = _nextQuestion;
    }

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
          // TextButton.icon(
          //   onPressed: currentQuestionIndex > 0 ? _previousQuestion : null,
          //   icon: const Icon(Icons.arrow_back_ios_rounded),
          //   label: const Text('Previous'),
          // ),
          Spacer(),

          TextButton.icon(
            iconAlignment: IconAlignment.end,
            onPressed: userAnswers[currentQuestionIndex].isNotEmpty ? onForwardTap : null,
            label: Text(
                forwardButtonText
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

    AppBar appBar = AppBar(centerTitle: true, title: Text('Review Set'));

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
                    _startReview();
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

          showAnswerMessage ? _buildAnswerCheckCard() : SizedBox.shrink(),

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
              ),
            ),
          ),

          _buildNavigationBar(),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Card _buildAnswerCheckCard() {
    ThemeData theme = Theme.of(context);

    Color color = isCurrentQuestionCorrect ? theme.colorScheme.green : theme.colorScheme.red;
    Color bgColor = isCurrentQuestionCorrect ? theme.colorScheme.paleGreen : theme.colorScheme.paleRed;

    return Card(
          color: bgColor,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: color,
              width: 2.0,
            ),
          ),
          margin: EdgeInsets.only(left: 30, right: 30, top: 30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Icon(FontAwesomeIcons.solidCircleCheck, color: color,),
                SizedBox(width: 15), // Add spacing between icon and text
                Expanded(
                    child: Text(
                        isCurrentQuestionCorrect ? 'Correct' : 'Incorrect',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: color,
                      ),
                    )
                ),
              ],
            ),
          ),
        );
  }

}