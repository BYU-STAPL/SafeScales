// =============================================================================
// PRE-QUIZ SCREEN FLOW - Assessment focused, formal,
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/ui/screens/pre_quiz/pre_quiz_results_screen.dart';
import 'package:safe_scales/models/question.dart';

import '../../../providers/course_provider.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/question_widget.dart';
import '../../widgets/tts_progress_bar.dart';
import '../../widgets/voice_button.dart';
import '../../../services/tts_service.dart';

class PreQuizScreen extends StatefulWidget {
  final String moduleId;
  final QuestionSet questionSet;

  const PreQuizScreen({
    super.key,
    required this.moduleId,
    required this.questionSet,
  });

  @override
  _PreQuizScreenState createState() => _PreQuizScreenState();
}

class _PreQuizScreenState extends State<PreQuizScreen> {
  int currentQuestionIndex = 0;
  List<List<int>> userAnswers = [];
  bool isStarted = false;
  final TtsService _ttsService = TtsService();

  late DateTime _quizStartTime;
  late DateTime _quizEndTime;

  @override
  void initState() {
    super.initState();
    userAnswers = List.generate(widget.questionSet.questions.length, (_) => []);
    _ttsService.initialize();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  String _buildQuestionTextForTTS(int questionIndex) {
    final question = widget.questionSet.questions[questionIndex];
    final buffer = StringBuffer();

    buffer.write('Question: ${question.questionText}');
    if (question.text != null && question.text!.isNotEmpty) {
      buffer.write('. ${question.text}');
    }
    buffer.write('. Options: ');

    for (int i = 0; i < question.options.length; i++) {
      final letter = String.fromCharCode(65 + i); // A, B, C, D...
      buffer.write('$letter) ${question.options[i]}. ');
    }

    return buffer.toString();
  }

  void _startPreQuiz() {
    setState(() {
      isStarted = true;
      _quizStartTime = DateTime.now();
    });
  }

  void _finishPreQuiz() async {
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
    } catch (e) {
      print('❌ Error saving pre-quiz progress: $e');
      // Continue to show results even if saving fails
    }

    if (!mounted) return;

    // Show results screen and then return to previous screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PreQuizResultScreen(
              moduleId: widget.moduleId,
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
    _ttsService.stop(); // Stop TTS when changing questions
    if (currentQuestionIndex < widget.questionSet.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      _finishPreQuiz();
    }
  }

  void _previousQuestion() {
    _ttsService.stop(); // Stop TTS when changing questions
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  Widget _buildNavigationBar() {
    ThemeData theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomPadding > 0 ? 0 : 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    userAnswers[currentQuestionIndex].isNotEmpty
                        ? _nextQuestion
                        : null,
                label: Text(
                  currentQuestionIndex ==
                          widget.questionSet.questions.length - 1
                      ? 'Complete'
                      : 'Next',
                ),
                icon: Icon(Icons.arrow_forward_ios_rounded),
              ),
            ],
          ),
        ),
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
                          Text(
                            '${widget.questionSet.questions.length} questions',
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
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

    final progress =
        (currentQuestionIndex + 1) / widget.questionSet.questions.length;

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
              child: Column(
                children: [
                  // Voice button for read aloud (spacing matches image-at-top layout)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: VoiceButton(
                      text: _buildQuestionTextForTTS(currentQuestionIndex),
                      pageIndex: currentQuestionIndex,
                      size: 35,
                      onStateChanged: () {
                        setState(() {
                          // Trigger rebuild to update UI state
                        });
                      },
                      margin: EdgeInsets.zero,
                    ),
                  ),
                  // Question widget
                  Expanded(
                    child: QuestionWidget(
                      key: ValueKey(
                        widget.questionSet.questions[currentQuestionIndex].id,
                      ),
                      question:
                          widget.questionSet.questions[currentQuestionIndex],
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
                ],
              ),
            ),
          ),

          TtsProgressBar(
            ttsService: _ttsService,
            cleanText: TtsService.cleanTextForProgress(
              _buildQuestionTextForTTS(currentQuestionIndex),
            ),
          ),

          _buildNavigationBar(),
        ],
      ),
    );
  }
}
