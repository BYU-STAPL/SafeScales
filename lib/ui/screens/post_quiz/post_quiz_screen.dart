// =============================================================================
// PRE-QUIZ SCREEN FLOW - Assessment focused, formal,
// =============================================================================

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/ui/screens/post_quiz/post_quiz_results_screen.dart';
import 'package:safe_scales/services/user_state_service.dart';

import '../../../providers/course_provider.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/question_widget.dart';

class PostQuizScreen extends StatefulWidget {
  const PostQuizScreen({
    super.key,
    required this.moduleId,
    required this.questionSet,
  });

  final String moduleId;
  final QuestionSet questionSet;

  @override
  _PostQuizScreenState createState() => _PostQuizScreenState();
}

class _PostQuizScreenState extends State<PostQuizScreen> {
  int currentQuestionIndex = 0;
  List<List<int>> userAnswers = [];
  bool isStarted = false;
  bool _showTableOfContents = false;
  final _userState = UserStateService();

  late DateTime _quizStartTime;
  late DateTime _quizEndTime;


  late bool _isForward;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    userAnswers = List.generate(widget.questionSet.questions.length, (_) => []);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startPostQuiz() {
    setState(() {
      isStarted = true;
      _quizStartTime = DateTime.now();
    });
  }

  void _finishPostQuiz() async {

    setState(() {
      _quizEndTime = DateTime.now();
    });

    int correctAnswers = 0;
    for (int i = 0; i < widget.questionSet.questions.length; i++) {
      if (_isAnswerCorrect(i)) correctAnswers++;
    }

    int totalQuestions = widget.questionSet.questions.length;
    int scorePercentage = ((correctAnswers / totalQuestions) * 100).round();

    // Save quiz progress
    try {
      final user = _userState.currentUser;
      if (user != null) {
        await Provider.of<CourseProvider>(
          context,
          listen: false,
        ).saveQuizProgress(
          quizType: widget.questionSet.activityType,
          quizId: widget.questionSet.id,
          userAnswers: userAnswers,
          correctAnswers: correctAnswers,
          totalQuestions: totalQuestions,
          startTime: _quizStartTime,
          endTime: _quizEndTime,
        );
      } else {
        print('No user logged in, skipping post-quiz progress save');
      }
    } catch (e) {
      print('❌ Error saving post-quiz progress: $e');
      // Continue to show results even if saving fails
    }

    if (!mounted) return;

    // Show results screen and then return to previous screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PostQuizResultScreen(
              moduleId: widget.moduleId,
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

  void _nextQuestion() {
    if (currentQuestionIndex < widget.questionSet.questions.length - 1) {
      setState(() {
        _isForward = true;
        _isFirstLoad = false;
      });
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      _finishPostQuiz();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        _isForward = false;
        _isFirstLoad = false;
      });

      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  bool _hasUserAnsweredAllQuestions() {
    bool allAnswered = true;
    for (List<int> questionAnswers in userAnswers) {
      if (questionAnswers.isEmpty) {
        allAnswered = false;
        break;
      }
    }

    return allAnswered;
  }

  bool _isLastQuestion() {
    return currentQuestionIndex == widget.questionSet.questions.length - 1;
  }

  void _showIncompleteDialog() {
    ThemeData theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Incomplete Quiz'),
          backgroundColor: theme.colorScheme.surfaceDim,
          content: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium, // Inherit default text style
              children: [
                TextSpan(
                  text:
                      'Please answer all questions before submitting the quiz.\n\nYou can check the table of contents  ',
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    FontAwesomeIcons.list,
                    size: theme.textTheme.bodyLarge?.fontSize,
                    color: theme.colorScheme.primary,
                  ),
                ),
                TextSpan(text: '  to see all questions'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
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
            onPressed:
                _isLastQuestion() && !_hasUserAnsweredAllQuestions()
                    ? _showIncompleteDialog
                    : _nextQuestion,
            label: Text(_isLastQuestion() ? 'Complete' : 'Next'),
            icon: Icon(Icons.arrow_forward_ios_rounded),
          ),
        ],
      ),
    );
  }

  void _jumpToPage(int index) {
    if (index >= 0 && index < widget.questionSet.questions.length) {
      setState(() {
        _isForward = index > currentQuestionIndex;
        _isFirstLoad = false;
      });
      setState(() {
        currentQuestionIndex = index;
        _showTableOfContents = false;
      });
    }
  }

  Widget _buildTableOfContents() {
    return Container(
      padding: EdgeInsets.all(30),
      color: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        itemCount: widget.questionSet.questions.length,
        itemBuilder: (context, index) {
          // final isBookmarked = _bookmarkedPages.contains(index);
          return ListTile(
            leading: Icon(
              userAnswers[index].isNotEmpty
                  ? FontAwesomeIcons.solidCircleCheck
                  : FontAwesomeIcons.circle,
              color: Colors.black,
            ),
            title: Text(
              'Q${index + 1}: ${widget.questionSet.questions[index].questionText}',
              style:
                  index == currentQuestionIndex
                      ? Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 18)
                      : Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () => _jumpToPage(index),
          );
        },
      ),
    );
  }

  Expanded _buildQuestionContent() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
          isResponseLocked: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    AppBar appBar = AppBar(
      centerTitle: true,
      title: Text('Post-Quiz'),
      actions:
          isStarted
              ? [
                IconButton(
                  icon: Icon(
                    _showTableOfContents ? Icons.close : FontAwesomeIcons.list,
                  ),
                  iconSize: 25,
                  onPressed: () {
                    setState(() {
                      _showTableOfContents = !_showTableOfContents;
                    });
                  },
                ),
              ]
              : null,
    );

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
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.secondary,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${widget.questionSet.passingScore}% or higher is required to pass this quiz',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

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

    final progress =
        (currentQuestionIndex + 1) / widget.questionSet.questions.length;

    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          // Progress bar
          ProgressBar(
            progress: progress,
            currentSlideIndex: currentQuestionIndex,
            slideLength: widget.questionSet.questions.length,
            slideName: 'question',
          ),

          // Main Content
          Expanded(
            child:
                _showTableOfContents
                    ? _buildTableOfContents()
                    : _isFirstLoad
                    ? _buildQuestionContent()
                    : _buildQuestionContent(),
          ),

          // Navigation
          _buildNavigationBar(),

          SizedBox(height: 15),
        ],
      ),
    );
  }
}
