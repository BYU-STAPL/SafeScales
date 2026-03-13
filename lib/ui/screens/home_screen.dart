import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/extensions/string_extensions.dart';
import 'package:safe_scales/models/lesson_progress.dart';
import 'package:safe_scales/ui/widgets/lesson_card.dart';
import 'package:safe_scales/providers/course_provider.dart';
import 'package:safe_scales/providers/dragon_provider.dart';
import '../../models/lesson.dart';
import '../widgets/learning_action_widget.dart';
import 'lesson/lesson_screen.dart';
import 'pre_quiz/pre_quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigateToShop});

  final Function() onNavigateToShop;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Lesson? getTargetLesson() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    final lessons = courseProvider.lessons;
    final lessonProgressMap = courseProvider.lessonProgress;

    // Find first incomplete lesson
    for (var lessonId in courseProvider.lessonOrder) {
      final progress = lessonProgressMap[lessonId]?.getProgressPercent() ?? 0.0;
      if (progress < 100) {
        return lessons[lessonId];
      }
    }

    // If all lessons are complete, return null
    if (courseProvider.lessonOrder.isNotEmpty) {
      return null;
    }

    return null;
  }

  Widget _buildContinueLearningSection({
    required CourseProvider courseProvider,
    required DragonProvider dragonProvider,
  }) {
    final targetModule = getTargetLesson();

    if (targetModule == null) {
      return LearningActionWidget(
        actionType: ActionType.review,
        title: 'Head over to the Shop',
        progress: 100,
        onTap: () {
          widget.onNavigateToShop();
        },
      );
    } else if (courseProvider.lessonOrder.isNotEmpty) {
      return LearningActionWidget(
        actionType: ActionType.continueLearning,
        title: targetModule.title.toString(),
        progress:
            courseProvider.lessonProgress[targetModule.lessonId]
                ?.getProgressPercent() ??
            0.0,
        onTap: () {
          _navigateToLesson(
            context,
            courseProvider,
            dragonProvider,
            targetModule,
          );
        },
      );
    }

    return SizedBox.shrink();
  }

  void _navigateToLesson(
    BuildContext context,
    CourseProvider courseProvider,
    DragonProvider dragonProvider,
    Lesson lesson,
  ) {
    final lessonProgress = courseProvider.lessonProgress[lesson.lessonId];
    final preQuizComplete = lessonProgress?.isPreQuizComplete ?? false;

    void onReturn() {
      courseProvider.loadSingleLessonProgress(lesson.lessonId);
      courseProvider.loadUserProgress();
      dragonProvider.updateAllDragonProgress();
    }

    if (preQuizComplete) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonScreen(moduleId: lesson.lessonId),
        ),
      ).then((_) => onReturn());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreQuizScreen(
            moduleId: lesson.lessonId,
            questionSet: lesson.preQuiz,
          ),
        ),
      ).then((_) => onReturn());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Now you can access ThemeNotifier if needed for settings/preferences
    return Consumer2<DragonProvider, CourseProvider>(
      builder: (context, dragonProvider, courseProvider, child) {
        // Show loading if data is still being loaded
        if (courseProvider.isLoading) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your content...',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContinueLearningSection(
                      courseProvider: courseProvider,
                      dragonProvider: dragonProvider,
                    ),

                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Lessons'.toTitleCase(),
                            style: theme.textTheme.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Builder(
                          builder: (context) {
                            // Count completed modules (100% progress)
                            final completedCount =
                                courseProvider.lessonOrder
                                    .where(
                                      (lessonId) =>
                                          (courseProvider
                                                  .lessonProgress[lessonId]
                                                  ?.getProgressPercent() ??
                                              0.0) >=
                                          100,
                                    )
                                    .length;

                            return Flexible(
                              child: Text(
                                '$completedCount/${courseProvider.lessonOrder.length} Completed'
                                    .toTitleCase(),
                                style: theme.textTheme.labelMedium,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Show empty state or lesson list
                    if (courseProvider.lessonOrder.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                courseProvider.lessons.isEmpty
                                    ? 'No class assigned'
                                    : 'No modules available',
                                style: theme.textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Lesson Card List
                      ...courseProvider.lessonOrder.asMap().entries.map((
                        entry,
                      ) {
                        int index = entry.key;
                        String lessonId = entry.value;

                        Lesson? lesson = courseProvider.lessons[lessonId];
                        LessonProgress? lessonProgress =
                            courseProvider.lessonProgress[lessonId];

                        if (lesson == null) {
                          return const SizedBox.shrink();
                        }

                        // Calculate unlock status
                        bool shouldBeUnlocked = false;
                        String? newUnlockRequirement;

                        if (index == 0) {
                          shouldBeUnlocked = true;
                        } else if (index > 0) {
                          String previousLessonId =
                              courseProvider.lessonOrder[index - 1];
                          Lesson? previousLesson =
                              courseProvider.lessons[previousLessonId];
                          LessonProgress? previousModule =
                              courseProvider.lessonProgress[previousLessonId];

                          final previousProgress =
                              previousModule?.getProgressPercent() ?? 0.0;
                          shouldBeUnlocked = previousProgress.round() >= 100;

                          if (!shouldBeUnlocked) {
                            newUnlockRequirement =
                                'Complete ${previousLesson?.title ?? 'previous module'} (${previousProgress.toStringAsFixed(0)}%)';
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: LessonCard(
                            moduleId: lessonId,
                            title: lesson.title,
                            description: 'Learn about ${lesson.title}',
                            actualProgress:
                                lessonProgress?.getProgressPercent() ?? 0.0,
                            shouldBeUnlocked: shouldBeUnlocked,
                            newUnlockRequirement: newUnlockRequirement,
                            unlockRequirement:
                                index > 0 ? 'Complete previous module' : null,
                            onTapCard: () {
                              if (shouldBeUnlocked) {
                                _navigateToLesson(
                                  context,
                                  courseProvider,
                                  dragonProvider,
                                  lesson,
                                );
                              }
                            },
                          ),
                        );
                      }),

                    // const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
