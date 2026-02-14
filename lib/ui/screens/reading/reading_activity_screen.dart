import 'package:flutter/material.dart';

// import 'package:page_flip/page_flip.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/extensions/string_extensions.dart';
import 'package:safe_scales/models/lesson_progress.dart';
import 'package:safe_scales/models/reading_slide.dart';
import 'package:safe_scales/services/tts_service.dart';
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

class _ReadingActivityScreenState extends State<ReadingActivityScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  final TtsService _ttsService = TtsService();

  List<ReadingSlide> _readingSlides = [];
  int _currentSlideIndex = 0;
  bool _isLoading = true;
  bool _showTableOfContents = false;
  Set<int> _bookmarkedPages = {};
  // bool _isForward = true;
  // bool _isFirstLoad = true;

  // final GlobalKey<PageFlipWidgetState> _pageFlipKey = GlobalKey<PageFlipWidgetState>();

  bool _isCompleted = false;
  bool _isCompleting = false; // Prevent multiple taps on Complete button

  @override
  void initState() {
    super.initState();
    _loadReading();
    _ttsService.initialize();
    _ttsService.addListener(_onTtsStateChanged);
  }

  void _onTtsStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ttsService.removeListener(_onTtsStateChanged);
    _ttsService.stop();
    _pageController.dispose();
    super.dispose();
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
        setState(() {
          _readingSlides = lesson.reading;
          _bookmarkedPages = lessonProgress.bookmarks;
          _isLoading = false;
        });
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
    setState(() {
      _currentSlideIndex = index;
    });
  }

  Container _buildNavigationBar() {
    ThemeData theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
            onPressed: _isCompleting ? null : _nextSlide,
            label: Text(
              _currentSlideIndex < _readingSlides.length - 1
                  ? 'Next'.toUpperCase()
                  : 'Complete'.toUpperCase(),
            ),
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
          final rawTitle = _readingSlides[index].title;
          final stripped = rawTitle.stripImageLinksForToc();
          final displayTitle =
              stripped.isEmpty ? 'Page ${index + 1}' : stripped;
          return ListTile(
            leading: IconButton(
              iconSize: 22,
              icon: Icon(
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

    final headline = _readingSlides[index].title;
    final content = _readingSlides[index].content;
    final fullText =
        '$headline\n\n${content.isNotEmpty ? content : 'No content available'}';

    return Column(
      children: [
        // Control buttons row: bookmark + read aloud
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 25,
                icon: Icon(
                  _bookmarkedPages.contains(index)
                      ? FontAwesomeIcons.solidBookmark
                      : FontAwesomeIcons.bookmark,
                  color:
                      _bookmarkedPages.contains(index)
                          ? theme.colorScheme.primary
                          : null,
                ),
                onPressed: () {
                  setState(() {
                    if (_bookmarkedPages.contains(index)) {
                      _bookmarkedPages.remove(index);
                    } else {
                      _bookmarkedPages.add(index);
                    }
                  });
                  _saveBookmarks();
                },
              ),
              VoiceButton(
                text: fullText,
                pageIndex: index,
                onStateChanged: () => setState(() {}),
                margin: EdgeInsets.zero,
                size: 40,
              ),
            ],
          ),
        ),

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_currentSlideIndex + 1) / _readingSlides.length;

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
                    ProgressBar(
                      progress: progress,
                      currentSlideIndex: _currentSlideIndex,
                      slideLength: _readingSlides.length,
                      slideName: 'page',
                    ),

                    // Main content
                    Expanded(
                      child:
                          _showTableOfContents
                              ? _buildTableOfContents()
                              : PageView.builder(
                                controller: _pageController,
                                onPageChanged: _onPageChanged,
                                itemCount: _readingSlides.length,
                                itemBuilder: (context, index) {
                                  return _buildPageContentFor(index);
                                },
                              ),
                    ),

                    // Read-aloud progress (only when this page is speaking)
                    if (!_showTableOfContents &&
                        _readingSlides.isNotEmpty &&
                        _ttsService.currentPageIndex == _currentSlideIndex &&
                        !_ttsService.isStopped)
                      TtsProgressBar(
                        ttsService: _ttsService,
                        cleanText: TtsService.cleanTextForProgress(
                          '${_readingSlides[_currentSlideIndex].title}\n\n${_readingSlides[_currentSlideIndex].content.isNotEmpty ? _readingSlides[_currentSlideIndex].content : 'No content available'}',
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
