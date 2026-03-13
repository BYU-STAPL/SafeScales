import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/models/lesson_progress.dart';
import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/ui/screens/post_quiz/post_quiz_screen.dart';
import 'package:safe_scales/ui/screens/reading/reading_activity_screen.dart';
import 'package:safe_scales/ui/screens/review_set/review_screen.dart';

import '../../../models/lesson.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/dragon_provider.dart';
import '../../widgets/dragon_image_widget.dart';

class LessonScreen extends StatefulWidget {
  final String moduleId;
  final String? topic; // Keep for backward compatibility

  const LessonScreen({super.key, required this.moduleId, this.topic});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Lesson? _lesson; // Make nullable
  LessonProgress? _lessonProgress; // Make nullable
  bool _isLoading = true; // Add loading state

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initializeData();
    }
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    // Check if provider is initialized
    if (!courseProvider.isInitialized) {
      await courseProvider.initialize();
    }

    setState(() {
      _lesson = courseProvider.lessons[widget.moduleId];
      _lessonProgress = courseProvider.lessonProgress[widget.moduleId];
    });

    // If either lesson or progress is null, show error
    if (_lesson == null || _lessonProgress == null) {
      if (mounted) {
        // Schedule the SnackBar to show after the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Check mounted again as this runs later
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Lesson not found or not properly initialized',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              ),
            );
            Navigator.pop(context);
          }
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Consumer2<DragonProvider, CourseProvider>(
      builder: (context, dragonProvider, courseProvider, child) {
        if (_isLoading || _lesson == null || _lessonProgress == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.topic ?? 'Loading...'),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: theme.colorScheme.onSurface,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: Text(
              widget.topic ?? _lesson!.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: theme.colorScheme.onSurface,
            scrolledUnderElevation: 0,
          ),
          body: courseProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      _buildLessonOverviewCard(dragonProvider),
                      const SizedBox(height: 28),
                      Text(
                        'Activities',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildReadingCard(isUnlocked: true),
                      const SizedBox(height: 12),
                      _buildActivityCard(
                        title: 'Quiz',
                        description: 'Test what you\'ve learned',
                        isCompleted: _lessonProgress!.isPostQuizComplete(),
                        isUnlocked: _lessonProgress!.isReadingComplete,
                        onTap: () => _startQuiz(_lesson!.postQuiz),
                      ),
                      const SizedBox(height: 24),
                      _buildNextLessonAndReviewSection(courseProvider),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildLessonOverviewCard(DragonProvider dragonProvider) {
    final theme = Theme.of(context);
    final dragon = dragonProvider.getDragonByModuleId(widget.moduleId);
    final phaseName = dragon != null
        ? dragonProvider.getPhaseDisplayName(
            dragonProvider.getDragonHighestPhase(dragon.id),
          )
        : 'Egg';
    final growthCount = (_lessonProgress!.isReadingComplete ? 1 : 0) +
        (_lessonProgress!.isPostQuizComplete() ? 1 : 0);
    final bestScore = _lessonProgress!.getHighestPostQuizScore();
    final hasPostQuizAttempts = _lessonProgress!.postQuizAttempts.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageSize = constraints.maxWidth * 0.5;
          return Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: DragonImageWidget(
                    moduleId: widget.moduleId,
                    size: imageSize,
                  ),
                ),
              ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phaseName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Progress ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    ...List.generate(2, (i) {
                      final filled = i < growthCount;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.7)
                                : theme.colorScheme.outline
                                    .withValues(alpha: 0.25),
                          ),
                        ),
                      );
                    }),
                    Text(
                      '$growthCount/2',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasPostQuizAttempts
                        ? 'Best: ${bestScore.toInt()}%'
                        : 'Best: --',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
        },
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String description,
    required bool isCompleted,
    required bool isUnlocked,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isLocked = !isUnlocked;

    final bgColor = isLocked
        ? theme.colorScheme.surfaceContainerLow
        : theme.colorScheme.surfaceContainerLowest;
    final borderColor = isLocked
        ? theme.colorScheme.outline.withValues(alpha: 0.15)
        : theme.colorScheme.outline.withValues(alpha: 0.2);
    final iconBgColor = isLocked
        ? theme.colorScheme.outline.withValues(alpha: 0.12)
        : isCompleted
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.primary.withValues(alpha: 0.1);
    final iconColor = isLocked
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
        : isCompleted
            ? theme.colorScheme.primary.withValues(alpha: 0.9)
            : theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    FontAwesomeIcons.dice,
                    size: 18,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isLocked
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextLessonAndReviewSection(CourseProvider courseProvider) {
    final theme = Theme.of(context);
    final isLessonComplete = courseProvider.isLessonCompleted(widget.moduleId);
    final nextLesson = courseProvider.getNextLesson(widget.moduleId);

    if (!isLessonComplete) {
      return Column(
        children: [
          Text(
            'Complete all activities to unlock the next lesson and review',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _buildLockedActionCard(
            title: 'Next Lesson',
            subtitle: nextLesson?.title ?? 'Next Lesson Name',
          ),
          const SizedBox(height: 12),
          _buildLockedActionCard(
            title: 'Review this Lesson',
            subtitle: 'Test what you\'ve learned',
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildNextLessonButton(courseProvider, nextLesson),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildReviewButton(),
      ],
    );
  }

  Widget _buildLockedActionCard({
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              FontAwesomeIcons.dice,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNextLessonButton(
    CourseProvider courseProvider,
    Lesson? nextLesson,
  ) {
    final theme = Theme.of(context);
    final nextLessonId = courseProvider.getNextLessonInSequence(widget.moduleId);
    final canNavigate = nextLessonId != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canNavigate
            ? () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LessonScreen(
                      moduleId: nextLessonId,
                      topic: nextLesson?.title,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                FontAwesomeIcons.dice,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Lesson',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nextLesson?.title ?? 'Next Lesson Name',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary
                            .withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onPrimary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReview() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final questionSet =
        await courseProvider.getReviewQuestionSetForLesson(widget.moduleId);

    if (!mounted) return;

    if (questionSet == null || questionSet.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'The Teacher has not created a review set for this lesson',
          ),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          questionSet: questionSet,
          needToShowShop: true,
        ),
      ),
    );

    if (mounted) {
      final cp = Provider.of<CourseProvider>(context, listen: false);
      await cp.loadSingleLessonProgress(widget.moduleId);
      setState(() {
        _lessonProgress = cp.lessonProgress[widget.moduleId];
      });
    }
  }

  Widget _buildReviewButton() {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _navigateToReview,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                FontAwesomeIcons.dice,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review this Lesson',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Test what you\'ve learned',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onPrimaryContainer,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingCard({required bool isUnlocked}) {
    return _buildActivityCard(
      title: 'Reading',
      description: 'Learn about ${widget.topic ?? _lesson!.title}',
      isCompleted: _lessonProgress!.isReadingComplete,
      isUnlocked: isUnlocked,
      onTap: () => _navigateToReading(),
    );
  }

  void _navigateToReading() async {
    setState(() => _isLoading = true);

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingActivityScreen(moduleId: widget.moduleId),
      ),
    );

    if (!mounted) return;

    if (completed == true) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(dialogContext).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
                boxShadow: [
                BoxShadow(
                  color: Theme.of(dialogContext).colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Updating progress...',
                  style: Theme.of(dialogContext).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );

      try {
        final courseProvider = Provider.of<CourseProvider>(context, listen: false);
        final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
        await courseProvider.loadSingleLessonProgress(widget.moduleId);
        await dragonProvider.updateAllDragonProgress();

        if (mounted) {
          setState(() {
            _lessonProgress = courseProvider.lessonProgress[widget.moduleId];
            _isLoading = false;
          });
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating progress: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _startQuiz(QuestionSet quiz) {
    // Check if quiz has no questions
    if (quiz.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This quiz is not available yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        ),
      );
      return;
    }

    // Check if quiz is being attempted before reading is completed
    if (quiz.activityType == ActivityType.postQuiz &&
        !_lessonProgress!.isReadingComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please complete the Reading activity first',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        ),
      );
      return;
    }

    final quizScreen = PostQuizScreen(moduleId: widget.moduleId, questionSet: quiz);

    setState(() {
      _isLoading = true; // Show loading state
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => quizScreen),
    ).then((completed) async {
      if (completed == true) {
        if (!mounted) return;
        final courseProvider = Provider.of<CourseProvider>(
          context,
          listen: false,
        );
        final dragonProvider = Provider.of<DragonProvider>(
          context,
          listen: false,
        );

        // Show loading overlay
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow
                            .withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title and close button row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Updating progress...',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ),
                ),
              );
            },
          );
        }

        try {
          // Load new progress
          await courseProvider.loadSingleLessonProgress(widget.moduleId);
          await dragonProvider.updateDragonPhases(widget.moduleId);

          if (mounted) {
            setState(() {
              _lessonProgress = courseProvider.lessonProgress[widget.moduleId];
              _isLoading = false;
            });
            // Close loading dialog
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            // Close loading dialog
            Navigator.of(context).pop();
            // Show error snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating progress: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

}
