import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/extensions/string_extensions.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/ui/screens/review_set/review_results_screen.dart';

import '../../../services/activity_event_service.dart';
import '../../../providers/shop_provider.dart';
import '../../widgets/progress_bar.dart';
import '../../../models/question.dart';
import '../../widgets/question_widget.dart';
import '../../widgets/styled_markdown.dart';
import '../../widgets/tts_progress_bar.dart';
import '../../widgets/voice_button.dart';
import '../../../services/tts_service.dart';

class ReviewScreen extends StatefulWidget {
  final QuestionSet questionSet;
  final String? lessonId;
  String? image;
  final bool needToShowShop;

  ReviewScreen({
    super.key,
    required this.questionSet,
    this.lessonId,
    this.image,
    required this.needToShowShop,
  });

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with WidgetsBindingObserver {
  int currentQuestionIndex = 0;
  List<List<int>> userAnswers = [];
  bool isStarted = false;
  final TtsService _ttsService = TtsService();

  bool isCurrentQuestionCorrect = false;
  List<List<List<int>>> attempts = [];

  bool isResponseLocked = false;

  bool _isInitialized = false;
  bool _isCompleted = false;
  final UserStateService _userState = UserStateService();
  final ActivityEventService _activityEvents = ActivityEventService();
  final List<int> _questionDurationsMs = [];
  final Stopwatch _questionStopwatch = Stopwatch();
  final Stopwatch _responseStopwatch = Stopwatch();
  final Stopwatch _reviewStopwatch = Stopwatch();
  bool _isAppForeground = true;
  DateTime? _reviewStartTime;
  String? _attemptId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    userAnswers = List.generate(widget.questionSet.questions.length, (_) => []);
    attempts = List.generate(widget.questionSet.questions.length, (_) => []);
    _questionDurationsMs.addAll(
      List<int>.filled(widget.questionSet.questions.length, 0),
    );
    _ttsService.initialize();

    // Use addPostFrameCallback to ensure initialization happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _questionStopwatch.stop();
    _responseStopwatch.stop();
    _reviewStopwatch.stop();
    _ttsService.dispose();
    if (isStarted && !_isCompleted) {
      final userId = _userState.currentUser?.id;
      if (userId != null && _attemptId != null) {
        unawaited(
          _recordActivity(() {
            return _activityEvents.record(
              userId: userId,
              eventType: 'review_set_abandoned',
              contextType: 'review_set',
              contextId: widget.questionSet.id,
              details: {
                'attempt_id': _attemptId,
                'lesson_id': widget.lessonId,
                'answered_questions':
                    attempts
                        .where(
                          (questionAttempts) => questionAttempts.isNotEmpty,
                        )
                        .length,
              },
            );
          }),
        );
      }
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppForeground = state == AppLifecycleState.resumed;
    if (_isAppForeground && isStarted && !_isCompleted) {
      _questionStopwatch.start();
      _responseStopwatch.start();
      _reviewStopwatch.start();
    } else {
      _questionStopwatch.stop();
      _responseStopwatch.stop();
      _reviewStopwatch.stop();
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

  Future<void> _initializeData() async {
    if (_isInitialized) return;

    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    try {
      // Only initialize if not already initialized
      // Since AppDependencies already calls initialize(), we might not need this
      if (!shopProvider.isLoading) {
        await shopProvider.initialize();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  void _startReview() {
    final now = DateTime.now();
    setState(() {
      isStarted = true;
    });
    _reviewStartTime = now;
    _questionStopwatch
      ..reset()
      ..start();
    _responseStopwatch
      ..reset()
      ..start();
    _reviewStopwatch
      ..reset()
      ..start();
    _attemptId = ActivityEventService.createEventId();
    final userId = _userState.currentUser?.id;
    if (userId != null) {
      unawaited(
        _recordActivity(() {
          return _activityEvents.record(
            userId: userId,
            eventType: 'review_set_started',
            contextType: 'review_set',
            contextId: widget.questionSet.id,
            occurredAt: now,
            details: {
              'attempt_id': _attemptId,
              'lesson_id': widget.lessonId,
              'question_count': widget.questionSet.questions.length,
            },
          );
        }),
      );
    }
  }

  void _finishReview() async {
    if (!mounted) return;
    final completedAt = DateTime.now();
    _recordQuestionTime();
    _isCompleted = true;
    _questionStopwatch.stop();
    _responseStopwatch.stop();
    _reviewStopwatch.stop();
    final userId = _userState.currentUser?.id;
    if (userId != null && _attemptId != null) {
      await _recordActivity(() async {
        await _recordQuestionDurationEvent(
          userId: userId,
          questionIndex: currentQuestionIndex,
          occurredAt: completedAt,
        );
        await _activityEvents.record(
          userId: userId,
          eventType: 'review_set_completed',
          contextType: 'review_set',
          contextId: widget.questionSet.id,
          occurredAt: completedAt,
          details: {
            'attempt_id': _attemptId,
            'lesson_id': widget.lessonId,
            'question_count': widget.questionSet.questions.length,
            'response_attempt_count': attempts.fold<int>(
              0,
              (total, questionAttempts) => total + questionAttempts.length,
            ),
            'duration_ms':
                completedAt
                    .difference(_reviewStartTime ?? completedAt)
                    .inMilliseconds,
            'active_duration_ms': _reviewStopwatch.elapsedMilliseconds,
          },
        );
      });
    }

    // if (widget.isComingFromShopRoute) {
    // Show results screen and then return to previous screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReviewResultsScreen(
              image: widget.image,
              needToShowShop: widget.needToShowShop,
            ),
      ),
    );
    // }
    // else {
    // Show the item selection dialog then the results
    // _openShopPopUp();
    // }

    if (!mounted) return;

    // Return to previous screen with completion status
    Navigator.pop(context, true);
  }

  // Future<void> _openShopPopUp() async {
  //   //TODO: Not working need to think more about this
  //   // TODO: Maybe the results screen should show a shop if no image is given
  //
  //   print("DEBUG: Open shop popup");
  //
  //   final shopProvider = Provider.of<ShopProvider>(context, listen: false);
  //
  //   final items = shopProvider.availableItems;
  //
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("Pick a Reward"),
  //         content: Expanded(
  //           child: GridView.count(
  //             crossAxisCount: 2,
  //             mainAxisSpacing: 20,
  //             crossAxisSpacing: 20,
  //             childAspectRatio: 0.95,
  //             children: [
  //               for (int i = 0; i < items.length; i++)
  //                 ShopItemCard(
  //                   image: items[i].imageUrl,
  //                   name: items[i].name,
  //                   cost: items[i].cost.toString() ?? '1',
  //                   isSelected: false, //selectedIndex == i,
  //                   highlight: Theme.of(context).colorScheme.green.withValues(alpha: 0.25),
  //                   onTap: () {
  //                     // setState(() {
  //                     //   selectedIndex = i;
  //                     // });
  //                   },
  //                 ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(); // Close dialog
  //             },
  //             child: const Text("Cancel"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //
  //               // TODO: Add handle purchase logic like in shop
  //
  //
  //               // Set widget.image to the item
  //
  //               Navigator.of(context).pop(); // Close dialog
  //             },
  //             child: const Text("Save Choice"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
    final now = DateTime.now();
    final responseDuration = _responseStopwatch.elapsedMilliseconds;
    _recordQuestionTime();
    setState(() {
      attempts[currentQuestionIndex].add(
        List<int>.from(userAnswers[currentQuestionIndex]),
      );
    });

    final isCorrect = _isAnswerCorrect(currentQuestionIndex);
    final userId = _userState.currentUser?.id;
    if (userId != null && _attemptId != null) {
      final question = widget.questionSet.questions[currentQuestionIndex];
      _recordActivity(() {
        return _activityEvents.record(
          userId: userId,
          eventType: 'review_question_response',
          contextType: 'review_set',
          contextId: widget.questionSet.id,
          occurredAt: now,
          details: {
            'attempt_id': _attemptId,
            'lesson_id': widget.lessonId,
            'question_id': question.id,
            'question_index': currentQuestionIndex,
            'response': List<int>.from(userAnswers[currentQuestionIndex]),
            'is_correct': isCorrect,
            'attempt_number': attempts[currentQuestionIndex].length,
            'response_duration_ms': responseDuration,
          },
        );
      });
    }
    _responseStopwatch..reset();
    if (_isAppForeground) {
      _responseStopwatch.start();
    }

    if (isCorrect) {
      setState(() {
        isCurrentQuestionCorrect = true;
        // showAnswerMessage = true; // Currently using snack-bar function: showAnswerCheckMessage
        isResponseLocked = true;
      });
    } else {
      isCurrentQuestionCorrect = false;
      setState(() {
        isCurrentQuestionCorrect = false;
        // showAnswerMessage = true;
        isResponseLocked = false;
      });
    }

    showAnswerCheckMessage();
  }

  void _nextQuestion() {
    _ttsService.stop(); // Stop TTS when changing questions
    if (currentQuestionIndex < widget.questionSet.questions.length - 1) {
      final now = DateTime.now();
      _recordQuestionTime();
      final userId = _userState.currentUser?.id;
      if (userId != null && _attemptId != null) {
        _recordActivity(() {
          return _recordQuestionDurationEvent(
            userId: userId,
            questionIndex: currentQuestionIndex,
            occurredAt: now,
          );
        });
      }
      setState(() {
        currentQuestionIndex++;
        isCurrentQuestionCorrect = false;
        // showAnswerMessage = false;
        isResponseLocked = false;
      });
      _responseStopwatch.reset();
      if (_isAppForeground) {
        _responseStopwatch.start();
      }
    } else {
      _finishReview();
    }
  }

  void _recordQuestionTime() {
    if (!isStarted) return;
    _questionDurationsMs[currentQuestionIndex] +=
        _questionStopwatch.elapsedMilliseconds;
    _questionStopwatch.reset();
    if (_isAppForeground && !_isCompleted) {
      _questionStopwatch.start();
    }
  }

  Future<void> _recordQuestionDurationEvent({
    required String userId,
    required int questionIndex,
    required DateTime occurredAt,
  }) {
    final question = widget.questionSet.questions[questionIndex];
    return _activityEvents.record(
      userId: userId,
      eventType: 'review_question_duration',
      contextType: 'review_set',
      contextId: widget.questionSet.id,
      occurredAt: occurredAt,
      details: {
        'attempt_id': _attemptId,
        'lesson_id': widget.lessonId,
        'question_id': question.id,
        'question_index': questionIndex,
        'attempt_count': attempts[questionIndex].length,
        'duration_ms': _questionDurationsMs[questionIndex],
      },
    );
  }

  Future<void> _recordActivity(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Review activity logging failed: $error');
    }
  }

  Container _buildNavigationBar() {
    ThemeData theme = Theme.of(context);

    //Decide what button to show and what function
    String forwardButtonText = 'Next';

    if (!isCurrentQuestionCorrect) {
      // Show check if not correct
      forwardButtonText = 'Check';
    } else if (currentQuestionIndex ==
        widget.questionSet.questions.length - 1) {
      // Answer is correct, check if at end of review set
      forwardButtonText = 'Complete';
    }
    forwardButtonText.toTitleCase();

    //Decide what button function if user has an answer selected
    Function() onForwardTap;

    if (!isCurrentQuestionCorrect) {
      // Check Question if not correct
      onForwardTap = _checkQuestion;
    } else {
      onForwardTap = _nextQuestion;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Spacer(),

          TextButton.icon(
            iconAlignment: IconAlignment.end,
            onPressed:
                userAnswers[currentQuestionIndex].isNotEmpty
                    ? onForwardTap
                    : null,
            label: Text(forwardButtonText),
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

    final progress =
        (currentQuestionIndex + 1) / widget.questionSet.questions.length;

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
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

              // showAnswerMessage ? _buildAnswerCheckCard() : SizedBox.shrink(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  child: Column(
                    children: [
                      // Voice button for read aloud
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
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
                            widget
                                .questionSet
                                .questions[currentQuestionIndex]
                                .id,
                          ),
                          question:
                              widget
                                  .questionSet
                                  .questions[currentQuestionIndex],
                          selectedAnswers: userAnswers[currentQuestionIndex],
                          onAnswerChanged: (answers) {
                            setState(() {
                              userAnswers[currentQuestionIndex] = answers;
                            });
                          },
                          showCorrectAnswer:
                              widget.questionSet.showCorrectAnswers,
                          showExplanation: false,
                          isResponseLocked: isResponseLocked,
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

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void showAnswerCheckMessage() {
    ThemeData theme = Theme.of(context);

    Color bgColor =
        isCurrentQuestionCorrect
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.errorContainer;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ReviewAnswerFeedback(
          isCorrect: isCurrentQuestionCorrect,
          explanation:
              widget.questionSet.questions[currentQuestionIndex].explanation,
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: bgColor,
        // behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Card _buildAnswerCheckCard() {
  //   ThemeData theme = Theme.of(context);
  //
  //   Color color = isCurrentQuestionCorrect ? theme.colorScheme.green : theme.colorScheme.red;
  //   Color bgColor = isCurrentQuestionCorrect ? theme.colorScheme.paleGreen : theme.colorScheme.paleRed;
  //
  //   return Card(
  //         color: bgColor,
  //         shadowColor: Colors.transparent,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           side: BorderSide(
  //             color: color,
  //             width: 2.0,
  //           ),
  //         ),
  //         margin: EdgeInsets.only(left: 30, right: 30, top: 30),
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
  //           child: Row(
  //             children: [
  //               Icon(FontAwesomeIcons.solidCircleCheck, color: color,),
  //               SizedBox(width: 15), // Add spacing between icon and text
  //               Expanded(
  //                   child: Text(
  //                       isCurrentQuestionCorrect ? 'Correct!' : 'Incorrect, try again.',
  //                     style: theme.textTheme.labelLarge?.copyWith(
  //                       color: color,
  //                     ),
  //                   )
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  // }
}

class ReviewAnswerFeedback extends StatelessWidget {
  const ReviewAnswerFeedback({
    super.key,
    required this.isCorrect,
    required this.explanation,
  });

  final bool isCorrect;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        isCorrect ? theme.colorScheme.secondary : theme.colorScheme.error;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.error,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCorrect ? 'Correct!' : 'Incorrect, try again.',
                    style: theme.textTheme.labelLarge?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            if (explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              StyledMarkdown(data: explanation),
            ],
          ],
        ),
      ),
    );
  }
}
