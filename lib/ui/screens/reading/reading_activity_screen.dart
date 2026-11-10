import 'dart:async';

import 'package:flutter/material.dart';

// import 'package:page_flip/page_flip.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/extensions/string_extensions.dart';
import 'package:safe_scales/models/lesson_progress.dart';
import 'package:safe_scales/models/reading_slide.dart';
import 'package:safe_scales/services/tts_service.dart';
import 'package:safe_scales/services/activity_event_service.dart';
import 'package:safe_scales/ui/screens/reading/reading_results_screen.dart';
import 'package:safe_scales/ui/widgets/tts_progress_bar.dart';
import 'package:safe_scales/ui/widgets/voice_button.dart';

import '../../../models/lesson.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/reading_font_adjustment_dialog.dart';
import '../../widgets/styled_markdown.dart';

class ReadingActivityScreen extends StatefulWidget {
  final String moduleId;

  const ReadingActivityScreen({super.key, required this.moduleId});

  @override
  State<ReadingActivityScreen> createState() => _ReadingActivityScreenState();
}

class _ReadingActivityScreenState extends State<ReadingActivityScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController(initialPage: 0);
  final TtsService _ttsService = TtsService();

  List<ReadingSlide> _readingSlides = [];
  int _currentSlideIndex = 0;
  bool _isLoading = true;
  bool _showTableOfContents = false;
  Set<int> _bookmarkedPages = {};
  final Map<int, int> _selectedCheckpointAnswers = {};
  final Map<int, bool> _checkpointResults = {};
  // bool _isForward = true;
  // bool _isFirstLoad = true;

  // final GlobalKey<PageFlipWidgetState> _pageFlipKey = GlobalKey<PageFlipWidgetState>();

  bool _isCompleted = false;
  bool _isCompleting = false; // Prevent multiple taps on Complete button
  bool _isAppForeground = true;
  bool _readingSessionEnded = false;
  String? _readingSessionId;
  String? _readingUserId;
  DateTime? _readingStartedAt;
  final Stopwatch _readingStopwatch = Stopwatch();
  final Stopwatch _pageStopwatch = Stopwatch();
  final ActivityEventService _activityEvents = ActivityEventService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReading();
    _ttsService.initialize();
    _ttsService.addListener(_onTtsStateChanged);
  }

  void _onTtsStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageStopwatch.stop();
    _readingStopwatch.stop();
    if (!_readingSessionEnded) {
      unawaited(_finishReadingSession(completed: false));
    }
    _ttsService.removeListener(_onTtsStateChanged);
    _ttsService.stop();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppForeground = state == AppLifecycleState.resumed;
    if (_isAppForeground &&
        _readingStartedAt != null &&
        !_readingSessionEnded) {
      _pageStopwatch.start();
      _readingStopwatch.start();
    } else {
      _pageStopwatch.stop();
      _readingStopwatch.stop();
    }
  }

  Future<void> _loadReading() async {
    try {
      CourseProvider courseProvider = Provider.of<CourseProvider>(
        context,
        listen: false,
      );

      // Get Lesson
      Lesson? lesson = courseProvider.getLesson(widget.moduleId);
      LessonProgress? lessonProgress = courseProvider.getLessonProgress(
        widget.moduleId,
      );

      if (lesson == null || lessonProgress == null) {
        throw Exception("No Lesson Found for ${widget.moduleId}");
      } else {
        final startedAt = DateTime.now();
        _readingSessionId = ActivityEventService.createEventId();
        _readingStartedAt = startedAt;
        _readingUserId = courseProvider.currentUser?.id;
        setState(() {
          _readingSlides = lesson.reading;
          _bookmarkedPages = lessonProgress.bookmarks;
          _isLoading = false;
        });
        _pageStopwatch.start();
        _readingStopwatch.start();
        final userId = _readingUserId;
        if (userId != null) {
          unawaited(
            _recordActivity(() {
              return _activityEvents.record(
                userId: userId,
                eventType: 'reading_session_started',
                contextType: 'lesson',
                contextId: widget.moduleId,
                occurredAt: startedAt,
                details: {
                  'reading_session_id': _readingSessionId,
                  'page_count': _readingSlides.length,
                },
              );
            }),
          );
          unawaited(
            _recordPageOpened(
              userId: userId,
              pageIndex: _currentSlideIndex,
              occurredAt: startedAt,
            ),
          );
        }
      }
    } catch (e) {
      print('❌Error loading slides: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      CourseProvider courseProvider = Provider.of<CourseProvider>(
        context,
        listen: false,
      );

      courseProvider.saveReadingProgress(
        lessonId: widget.moduleId,
        bookmarks: _bookmarkedPages,
      );
    } catch (e) {
      print('❌Error saving bookmarks: $e');
    }
  }

  Future<void> _markAsCompleted() async {
    // Prevent multiple calls - set flag synchronously before any async work
    // to close the race window where a second tap could get through
    if (_isCompleting || _isCompleted) return;
    if (!mounted) return;
    _isCompleting = true;
    setState(() {});

    try {
      // Save progress immediately when reading is completed
      final success = await Provider.of<CourseProvider>(
        context,
        listen: false,
      ).saveReadingProgress(
        lessonId: widget.moduleId,
        bookmarks: _bookmarkedPages,
      );

      // Only proceed if save was successful
      if (!success) {
        if (mounted) {
          setState(() {
            _isCompleting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving progress. Please try again.'),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
          );
        }
        return;
      }

      await _finishReadingSession(completed: true);

      // Save isComplete flag only after successful save
      if (mounted) {
        setState(() {
          _isCompleted = true;
          _isCompleting = false;
        });

        // Navigate to results screen and wait for it to return
        final shouldPopReading = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder:
                (context) => ReadingResultScreen(modeuleId: widget.moduleId),
          ),
        );

        // Only pop the reading screen if the results screen returned true
        // (meaning the user wants to go back to the lesson)
        if (mounted && shouldPopReading == true) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('❌Error marking reading as completed: $e');
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving progress: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _nextSlide() async {
    final currentSlide = _readingSlides[_currentSlideIndex];
    if (currentSlide.isCheckpoint &&
        !_isCheckpointComplete(_currentSlideIndex)) {
      _checkCheckpointAnswer(_currentSlideIndex);
      return;
    }

    if (_currentSlideIndex < _readingSlides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Properly await the completion process
      await _markAsCompleted();
    }
  }

  bool _isCheckpointComplete(int index) => _checkpointResults[index] == true;

  bool _canMoveForwardTo(int targetIndex) {
    for (var index = _currentSlideIndex; index < targetIndex; index++) {
      if (_readingSlides[index].isCheckpoint && !_isCheckpointComplete(index)) {
        return false;
      }
    }
    return true;
  }

  void _checkCheckpointAnswer(int index) {
    final selectedAnswer = _selectedCheckpointAnswers[index];
    final question = _readingSlides[index].checkpointQuestion;
    if (selectedAnswer == null || question == null) return;

    setState(() {
      _checkpointResults[index] = question.isCorrect([selectedAnswer]);
    });
  }

  void _previousSlide() {
    if (_currentSlideIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // _pageFlipKey.currentState?.previousPage();
    }
  }

  void _onPageChanged(int index) {
    if (index > _currentSlideIndex && !_canMoveForwardTo(index)) {
      _pageController.jumpToPage(_currentSlideIndex);
      return;
    }

    if (index != _currentSlideIndex && _readingStartedAt != null) {
      final now = DateTime.now();
      final userId = _readingUserId;
      if (userId != null) {
        unawaited(
          _recordPageDuration(
            userId: userId,
            pageIndex: _currentSlideIndex,
            occurredAt: now,
          ),
        );
        unawaited(
          _recordPageOpened(userId: userId, pageIndex: index, occurredAt: now),
        );
      }
      _pageStopwatch
        ..stop()
        ..reset();
      if (_isAppForeground && !_readingSessionEnded) {
        _pageStopwatch.start();
      }
    }
    setState(() {
      _currentSlideIndex = index;
    });
  }

  Future<void> _recordPageOpened({
    required String userId,
    required int pageIndex,
    required DateTime occurredAt,
  }) {
    return _recordActivity(() {
      return _activityEvents.record(
        userId: userId,
        eventType: 'reading_page_opened',
        contextType: 'lesson',
        contextId: widget.moduleId,
        occurredAt: occurredAt,
        details: {
          'reading_session_id': _readingSessionId,
          'page_index': pageIndex,
          'page_title':
              pageIndex >= 0 && pageIndex < _readingSlides.length
                  ? _readingSlides[pageIndex].title
                  : null,
        },
      );
    });
  }

  Future<void> _recordPageDuration({
    required String userId,
    required int pageIndex,
    required DateTime occurredAt,
  }) {
    final durationMs = _pageStopwatch.elapsedMilliseconds;
    return _recordActivity(() {
      return _activityEvents.record(
        userId: userId,
        eventType: 'reading_page_duration',
        contextType: 'lesson',
        contextId: widget.moduleId,
        occurredAt: occurredAt,
        details: {
          'reading_session_id': _readingSessionId,
          'page_index': pageIndex,
          'page_title':
              pageIndex >= 0 && pageIndex < _readingSlides.length
                  ? _readingSlides[pageIndex].title
                  : null,
          'duration_ms': durationMs,
        },
      );
    });
  }

  Future<void> _finishReadingSession({required bool completed}) async {
    if (_readingStartedAt == null || _readingSessionEnded) return;
    _readingSessionEnded = true;
    final now = DateTime.now();
    final userId = _readingUserId;
    _pageStopwatch.stop();
    _readingStopwatch.stop();
    if (userId == null) return;

    await _recordPageDuration(
      userId: userId,
      pageIndex: _currentSlideIndex,
      occurredAt: now,
    );
    await _recordActivity(() {
      return _activityEvents.record(
        userId: userId,
        eventType: 'reading_session_ended',
        contextType: 'lesson',
        contextId: widget.moduleId,
        occurredAt: now,
        details: {
          'reading_session_id': _readingSessionId,
          'completed': completed,
          'page_count': _readingSlides.length,
          'duration_ms': _readingStopwatch.elapsedMilliseconds,
        },
      );
    });
  }

  Future<void> _recordActivity(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Reading activity logging failed: $error');
    }
  }

  Container _buildNavigationBar() {
    ThemeData theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentSlide = _readingSlides[_currentSlideIndex];
    final isUnansweredCheckpoint =
        currentSlide.isCheckpoint && !_isCheckpointComplete(_currentSlideIndex);
    final hasSelectedAnswer = _selectedCheckpointAnswers.containsKey(
      _currentSlideIndex,
    );
    final nextLabel =
        isUnansweredCheckpoint
            ? 'Check'
            : _currentSlideIndex < _readingSlides.length - 1
            ? 'Next'
            : 'Complete';

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 10 + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _currentSlideIndex > 0 ? _previousSlide : null,
            icon: const Icon(Icons.arrow_back_ios_rounded),
            label: Text('Previous'.toUpperCase()),
          ),
          TextButton.icon(
            iconAlignment: IconAlignment.end,
            onPressed:
                _isCompleting || (isUnansweredCheckpoint && !hasSelectedAnswer)
                    ? null
                    : _nextSlide,
            label: Text(nextLabel.toUpperCase()),
            icon:
                _isCompleting
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onSurface,
                        ),
                      ),
                    )
                    : Icon(Icons.arrow_forward_ios_rounded),
          ),
        ],
      ),
    );
  }

  void _toggleBookmark(int index) {
    setState(() {
      if (_bookmarkedPages.contains(index)) {
        _bookmarkedPages.remove(index);
      } else {
        _bookmarkedPages.add(index);
      }
    });
    _saveBookmarks();
  }

  void _jumpToPage(int index) {
    if (index >= 0 && index < _readingSlides.length) {
      if (index > _currentSlideIndex && !_canMoveForwardTo(index)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer the checkpoint correctly before continuing.'),
          ),
        );
        return;
      }

      // Check if PageController is attached to a PageView
      if (_pageController.hasClients) {
        // Use jumpToPage for instant navigation without animation
        _pageController.jumpToPage(index);
      } else {
        // If PageController is not attached yet, just update the index
        // and close TOC. The PageView will be built with the correct initial page.

        _onPageChanged(index);

        // Use WidgetsBinding to ensure the PageView is built before jumping
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(index);
          }
        });
      }

      // _pageFlipKey.currentState?.goToPage(index);

      setState(() {
        _showTableOfContents = false;
      });
    }
  }

  Widget _buildTableOfContents() {
    return Container(
      padding: EdgeInsets.all(30),
      color: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        itemCount: _readingSlides.length,
        itemBuilder: (context, index) {
          final isBookmarked = _bookmarkedPages.contains(index);
          final slide = _readingSlides[index];
          final stripped = slide.title.stripImageLinksForToc();
          final displayTitle =
              stripped.isEmpty
                  ? slide.isCheckpoint
                      ? 'Checkpoint Question'
                      : 'Page ${index + 1}'
                  : stripped;
          return ListTile(
            leading: IconButton(
              iconSize: 22,
              icon: FaIcon(
                isBookmarked
                    ? FontAwesomeIcons.solidBookmark
                    : FontAwesomeIcons.bookmark,
                color:
                    isBookmarked ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: () {
                _toggleBookmark(index);
              },
            ),
            title: Text(
              'P${index + 1}: $displayTitle',
              style:
                  index == _currentSlideIndex
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

  Widget _buildPageContentFor(int index) {
    final theme = Theme.of(context);
    final slide = _readingSlides[index];

    if (slide.isCheckpoint) {
      return _buildCheckpointContentFor(index, theme);
    }

    final headline = slide.title;
    final content = slide.content;
    final fullText =
        '$headline\n\n${content.isNotEmpty ? content : 'No content available'}';

    return Column(
      children: [
        _buildPageControls(index: index, spokenText: fullText, theme: theme),

        // Content - wrapped in Expanded
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Consumer<ThemeNotifier>(
              builder: (context, themeNotifier, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StyledMarkdown(
                      data: fullText,
                      fontSizeScale: themeNotifier.readingFontSize,
                    ),
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckpointContentFor(int index, ThemeData theme) {
    final slide = _readingSlides[index];
    final question = slide.checkpointQuestion!;
    final selectedAnswer = _selectedCheckpointAnswers[index];
    final result = _checkpointResults[index];
    final spokenText = [
      slide.title,
      question.questionText,
      ...question.options,
    ].join('\n\n');

    return Column(
      children: [
        _buildPageControls(index: index, spokenText: spokenText, theme: theme),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.title.isEmpty ? 'Checkpoint Question' : slide.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Text(question.questionText, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 20),
                Text(
                  'Choose one option:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                for (
                  var optionIndex = 0;
                  optionIndex < question.options.length;
                  optionIndex++
                )
                  _buildCheckpointOption(
                    checkpointIndex: index,
                    optionIndex: optionIndex,
                    option: question.options[optionIndex],
                    isSelected: selectedAnswer == optionIndex,
                    isLocked: result == true,
                    theme: theme,
                  ),
                if (result != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          result
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            result
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          result ? Icons.check_circle : Icons.info_outline,
                          color:
                              result
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result
                                ? 'Correct! Keep it up!'
                                : 'Not quite, try again.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckpointOption({
    required int checkpointIndex,
    required int optionIndex,
    required String option,
    required bool isSelected,
    required bool isLocked,
    required ThemeData theme,
  }) {
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      label: option,
      child: Material(
        color:
            isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap:
              isLocked
                  ? null
                  : () {
                    setState(() {
                      _selectedCheckpointAnswers[checkpointIndex] = optionIndex;
                      _checkpointResults.remove(checkpointIndex);
                    });
                  },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(option)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageControls({
    required int index,
    required String spokenText,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 25,
            icon: FaIcon(
              _bookmarkedPages.contains(index)
                  ? FontAwesomeIcons.solidBookmark
                  : FontAwesomeIcons.bookmark,
              color:
                  _bookmarkedPages.contains(index)
                      ? theme.colorScheme.primary
                      : null,
            ),
            onPressed: () => _toggleBookmark(index),
          ),
          VoiceButton(
            text: spokenText,
            pageIndex: index,
            onStateChanged: () => setState(() {}),
            margin: EdgeInsets.zero,
            size: 40,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        _readingSlides.isEmpty
            ? 0.0
            : (_currentSlideIndex + 1) / _readingSlides.length;
    final currentSlide =
        _readingSlides.isEmpty ? null : _readingSlides[_currentSlideIndex];

    return PopScope(
      canPop: false, // Prevent default back button behavior
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // If reading is completed, return true to indicate completion
        if (_isCompleted) {
          Navigator.pop(context, true);
        } else {
          // If reading is not completed, just go back normally
          Navigator.pop(context, false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Reading'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.format_size),
              iconSize: 25,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ReadingFontAdjustmentDialog(),
                );
              },
            ),
            IconButton(
              icon:
                  _showTableOfContents
                      ? const Icon(Icons.close)
                      : const FaIcon(FontAwesomeIcons.list),
              iconSize: 25,
              onPressed: () {
                setState(() {
                  _showTableOfContents = !_showTableOfContents;
                });
              },
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _readingSlides.isEmpty
                ? Center(
                  child: Text(
                    'No reading content available',
                    style: theme.textTheme.labelMedium,
                  ),
                )
                : Column(
                  children: [
                    // Progress bar
                    ReadingProgressBar(
                      progress: progress,
                      currentSlideIndex: _currentSlideIndex,
                      slideLength: _readingSlides.length,
                      checkpointIndices: [
                        for (
                          var index = 0;
                          index < _readingSlides.length;
                          index++
                        )
                          if (_readingSlides[index].isCheckpoint) index,
                      ],
                      completedCheckpoints: {
                        for (final entry in _checkpointResults.entries)
                          if (entry.value) entry.key,
                      },
                    ),

                    // Main content
                    Expanded(
                      child:
                          _showTableOfContents
                              ? _buildTableOfContents()
                              : PageView.builder(
                                controller: _pageController,
                                physics:
                                    currentSlide!.isCheckpoint &&
                                            !_isCheckpointComplete(
                                              _currentSlideIndex,
                                            )
                                        ? const NeverScrollableScrollPhysics()
                                        : null,
                                onPageChanged: _onPageChanged,
                                itemCount: _readingSlides.length,
                                itemBuilder: (context, index) {
                                  return _buildPageContentFor(index);
                                },
                              ),
                    ),

                    // Read-aloud progress (only when this page is speaking)
                    if (!_showTableOfContents &&
                        currentSlide != null &&
                        _ttsService.currentPageIndex == _currentSlideIndex &&
                        !_ttsService.isStopped)
                      TtsProgressBar(
                        ttsService: _ttsService,
                        cleanText: TtsService.cleanTextForProgress(
                          currentSlide.isCheckpoint
                              ? [
                                currentSlide.title,
                                currentSlide.checkpointQuestion!.questionText,
                                ...currentSlide.checkpointQuestion!.options,
                              ].join('\n\n')
                              : '${currentSlide.title}\n\n${currentSlide.content.isNotEmpty ? currentSlide.content : 'No content available'}',
                        ),
                        pageIndex: _currentSlideIndex,
                      ),

                    // Navigation controls
                    _buildNavigationBar(),
                  ],
                ),
      ),
    );
  }
}
