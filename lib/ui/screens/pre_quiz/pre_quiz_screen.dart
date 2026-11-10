// =============================================================================
// PRE-QUIZ SCREEN FLOW - Assessment focused, formal,
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/ui/screens/pre_quiz/pre_quiz_results_screen.dart';
import 'package:safe_scales/models/question.dart';

import '../../../providers/course_provider.dart';
import '../../../services/activity_event_service.dart';
import '../../../themes/app_theme.dart';
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

class _PreQuizScreenState extends State<PreQuizScreen>
    with WidgetsBindingObserver {
  int currentQuestionIndex = 0;
  List<List<int>> userAnswers = [];
  bool isStarted = false;
  bool _isFinishing = false;
  bool _showTableOfContents = false;
  final TtsService _ttsService = TtsService();
  final ActivityEventService _activityEvents = ActivityEventService();
  final List<int> _questionDurationsMs = [];
  final Stopwatch _questionStopwatch = Stopwatch();
  final Stopwatch _quizStopwatch = Stopwatch();
  bool _isAppForeground = true;
  String? _attemptId;

  late DateTime _quizStartTime;
  late DateTime _quizEndTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    userAnswers = List.generate(widget.questionSet.questions.length, (_) => []);
    _questionDurationsMs.addAll(
      List<int>.filled(widget.questionSet.questions.length, 0),
    );
    _ttsService.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _questionStopwatch.stop();
    _quizStopwatch.stop();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppForeground = state == AppLifecycleState.resumed;
    if (_isAppForeground && isStarted && !_isFinishing) {
      _questionStopwatch.start();
      _quizStopwatch.start();
    } else {
      _questionStopwatch.stop();
      _quizStopwatch.stop();
    }
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
    final now = DateTime.now();
    setState(() {
      isStarted = true;
      _quizStartTime = now;
    });
    _attemptId = ActivityEventService.createEventId();
    _questionStopwatch
      ..reset()
      ..start();
    _quizStopwatch
      ..reset()
      ..start();
    final userId =
        Provider.of<CourseProvider>(context, listen: false).currentUser?.id;
    if (userId != null) {
      unawaited(
        _recordActivity(() {
          return _activityEvents.recordQuizAttemptStarted(
            userId: userId,
            attemptId: _attemptId!,
            quizId: widget.questionSet.id,
            quizType: 'pre_quiz',
            questionCount: widget.questionSet.questions.length,
          );
        }),
      );
    }
  }

  void _finishPreQuiz() async {
    if (_isFinishing || widget.questionSet.questions.isEmpty) return;

    final endTime = DateTime.now();
    _recordQuestionVisit();
    _questionStopwatch.stop();
    _quizStopwatch.stop();
    setState(() {
      _isFinishing = true;
      _quizEndTime = endTime;
    });

    int correctAnswers = 0;
    for (int i = 0; i < widget.questionSet.questions.length; i++) {
      if (_isAnswerCorrect(i)) correctAnswers++;
    }

    int totalQuestions = widget.questionSet.questions.length;
    int scorePercentage = ((correctAnswers / totalQuestions) * 100).round();

    final userId =
        Provider.of<CourseProvider>(context, listen: false).currentUser?.id;
    if (userId != null && _attemptId != null) {
      await _recordActivity(() {
        return _activityEvents.recordQuizAttemptCompleted(
          userId: userId,
          attemptId: _attemptId!,
          quizId: widget.questionSet.id,
          quizType: 'pre_quiz',
          correctAnswers: correctAnswers,
          totalQuestions: totalQuestions,
          activeDurationMs: _quizStopwatch.elapsedMilliseconds,
          startedAt: _quizStartTime,
          completedAt: _quizEndTime,
          questionResults: _buildQuestionResults(),
        );
      });
    }

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

    // Results pops itself with true. Leave this quiz only then,
    // so a dismissed results screen does not also pop the lesson.
    final returned = await Navigator.push<bool>(
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

    if (!mounted || returned != true) return;

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

  List<Map<String, dynamic>> _buildQuestionResults() {
    return List.generate(widget.questionSet.questions.length, (index) {
      final question = widget.questionSet.questions[index];
      return {
        'question_index': index,
        'question_id': question.id,
        'response': userAnswers[index],
        'is_correct': _isAnswerCorrect(index),
        'duration_ms': _questionDurationsMs[index],
      };
    });
  }

  void _recordQuestionVisit() {
    if (!isStarted) return;
    _questionDurationsMs[currentQuestionIndex] +=
        _questionStopwatch.elapsedMilliseconds;
    _questionStopwatch.reset();
    if (_isAppForeground && !_isFinishing) {
      _questionStopwatch.start();
    }
  }

  Future<void> _recordActivity(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Pre-quiz activity logging failed: $error');
    }
  }

  void _nextQuestion() {
    if (_isFinishing || widget.questionSet.questions.isEmpty) return;

    _ttsService.stop(); // Stop TTS when changing questions
    if (currentQuestionIndex < widget.questionSet.questions.length - 1) {
      _recordQuestionVisit();
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
      _recordQuestionVisit();
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  void _jumpToPage(int index) {
    _ttsService.stop();
    if (index < 0 || index >= widget.questionSet.questions.length) return;

    _recordQuestionVisit();
    setState(() {
      currentQuestionIndex = index;
      _showTableOfContents = false;
    });
  }

  Widget _buildTableOfContents() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: widget.questionSet.questions.length,
      itemBuilder: (context, index) {
        final isAnswered = userAnswers[index].isNotEmpty;
        return ListTile(
          leading: FaIcon(
            isAnswered
                ? FontAwesomeIcons.solidCircleCheck
                : FontAwesomeIcons.circle,
            color:
                isAnswered
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
          ),
          title: Text(
            'Question ${index + 1}',
            style:
                index == currentQuestionIndex
                    ? theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )
                    : theme.textTheme.bodyMedium,
          ),
          onTap: () => _jumpToPage(index),
        );
      },
    );
  }

  Widget _buildStarterDetailRow({
    required IconData icon,
    required String text,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: FaIcon(icon, size: 22, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.35,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
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
                    !_isFinishing &&
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

    AppBar appBar = AppBar(
      centerTitle: true,
      title: const Text('Survey'),
      actions:
          isStarted
              ? [
                IconButton(
                  tooltip:
                      _showTableOfContents
                          ? 'Close table of contents'
                          : 'Open table of contents',
                  icon:
                      _showTableOfContents
                          ? const Icon(Icons.close)
                          : const FaIcon(FontAwesomeIcons.list),
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
      final totalQuestions = widget.questionSet.questions.length;
      return Scaffold(
        appBar: appBar,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.questionSet.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalQuestions Multiple Choice Questions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (widget.questionSet.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.questionSet.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.green),
                  ),
                  child: Text(
                    'Give each question your best guess',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildStarterDetailRow(
                        icon: FontAwesomeIcons.listUl,
                        text:
                            'Use the table of contents to return to previous questions',
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _buildStarterDetailRow(
                        icon: FontAwesomeIcons.volumeHigh,
                        text:
                            'Use the audio feature to listen to questions instead of reading',
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                if (widget.questionSet.questions.isEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'This quiz has no available questions. Please try again later.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 8, 30, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    widget.questionSet.questions.isEmpty
                        ? null
                        : () {
                          _startPreQuiz();
                        },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Start'.toUpperCase(),
                  style: TextStyle(
                    fontSize: theme.textTheme.bodyMedium?.fontSize,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
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
            child:
                _showTableOfContents
                    ? _buildTableOfContents()
                    : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          // Voice button for read aloud (spacing matches image-at-top layout)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: VoiceButton(
                              text: _buildQuestionTextForTTS(
                                currentQuestionIndex,
                              ),
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
                                widget
                                    .questionSet
                                    .questions[currentQuestionIndex]
                                    .id,
                              ),
                              question:
                                  widget
                                      .questionSet
                                      .questions[currentQuestionIndex],
                              selectedAnswers:
                                  userAnswers[currentQuestionIndex],
                              onAnswerChanged: (answers) {
                                setState(() {
                                  userAnswers[currentQuestionIndex] = answers;
                                });
                              },
                              showCorrectAnswer:
                                  widget.questionSet.showCorrectAnswers,
                              showExplanation: false,
                              isResponseLocked: false,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),

          if (!_showTableOfContents)
            TtsProgressBar(
              ttsService: _ttsService,
              cleanText: TtsService.cleanTextForProgress(
                _buildQuestionTextForTTS(currentQuestionIndex),
              ),
            ),

          if (!_showTableOfContents) _buildNavigationBar(),
        ],
      ),
    );
  }
}
