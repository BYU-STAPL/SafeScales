import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/extensions/string_extensions.dart';
import 'package:safe_scales/models/lesson_progress.dart';
import 'package:safe_scales/ui/widgets/lesson_card.dart';
import 'package:safe_scales/state_management/old_dragon_provider.dart';

import '../../models/lesson.dart';
import '../../state_management/old_course_provider.dart';
import '../../state_management/dragon_provider.dart';
import '../widgets/continue_learning_widget.dart';
import 'lesson/lesson_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final courseProvider = Provider.of<OldCourseProvider>(context, listen: false);
    await courseProvider.initialize();

    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
    await dragonProvider.initialize();
  }

  Lesson? getTargetLesson() {

    OldCourseProvider courseProvider = Provider.of<OldCourseProvider>(context, listen: false);

    final lessons = courseProvider.lessons;
    final lessonProgressMap = courseProvider.lessonProgress;

    Lesson? targetModule;
    for (var lessonId in lessonProgressMap.keys) {
      final progress = lessonProgressMap[lessonId]?.getProgressPercent() ?? 0.0;
      if (progress < 100) {
        targetModule = lessons[lessonId];
        break;
      }
    }

    return targetModule;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<DragonProvider, OldCourseProvider>(
      builder: (context, dragonProvider, courseProvider, child) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class Header
                    Text(
                      courseProvider.className,
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 10),

                    courseProvider.description.isNotEmpty
                        ? Text(courseProvider.description, style: theme.textTheme.labelMedium,)
                        : SizedBox.shrink(),


                    const SizedBox(height: 20),


                    // Continue Learning Card
                    if (courseProvider.lessonOrder.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          // Find the latest incomplete module

                          Lesson? targetModule = getTargetLesson();

                          // If all modules are complete, go to the last module
                          targetModule ??= courseProvider.lessons[courseProvider.lessonOrder.last];

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LessonPage(moduleId: targetModule?.lessonId ?? ''),
                            ),
                          ).then((_) {
                            // Reload data when returning from lesson
                            // Provider.of<CourseProvider>(context, listen: false).loadSingleLessonProgress(lessonId);
                            Provider.of<OldCourseProvider>(context, listen: false).loadUserProgress();
                            Provider.of<DragonProvider>(context, listen: false).updateAllDragonProgress();
                          });
                        },
                        child: ContinueLearningWidget(title: getTargetLesson()?.title ?? 'Module', progress: courseProvider.lessonProgress[getTargetLesson()?.lessonId]?.getProgressPercent() ?? 0.0),
                      ),


                    const SizedBox(height: 30),

                    // Lesson Heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lessons'.toTitleCase(),
                          style: theme.textTheme.headlineSmall,
                        ),
                        Builder(
                          builder: (context) {
                            // Count completed modules (100% progress)
                            final completedCount = courseProvider.lessonOrder
                                .where((lessonId) => (courseProvider.lessonProgress[lessonId]?.getProgressPercent() ?? 0.0) >= 100)
                                .length;

                            return Text(
                              '${completedCount}/${courseProvider.lessonOrder.length} Completed'.toTitleCase(),
                              style: theme.textTheme.labelMedium,
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Show loading or lesson List
                    if (courseProvider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (courseProvider.lessonOrder.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            courseProvider.lessons.isEmpty ? 'No class assigned' : 'No modules available',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                      )
                    else
                      // Lesson Card List
                      ...courseProvider.lessonOrder.asMap().entries.map((entry) {

                        int index = entry.key;
                        String lessonId = entry.value;

                        Lesson? lesson = courseProvider.lessons[lessonId];
                        LessonProgress? lessonProgress = courseProvider.lessonProgress[lessonId];

                        if (lesson == null) {
                          return SizedBox.shrink();
                        }

                        if (lessonProgress == null) {
                          return SizedBox.shrink();
                        }

                        // Calculate unlock status
                        bool shouldBeUnlocked = false;
                        String? newUnlockRequirement;


                        if (index == 0) {
                          shouldBeUnlocked = true;
                        }
                        else if (index > 0) {
                          String previousLessonId = courseProvider.lessonOrder[index - 1];
                          Lesson? previousLesson = courseProvider.lessons[previousLessonId];

                          LessonProgress? previousModule = courseProvider.lessonProgress[previousLessonId];

                          final previousProgress = previousModule?.getProgressPercent() ?? 0.0;

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
                            actualProgress: lessonProgress.getProgressPercent(),
                            shouldBeUnlocked: shouldBeUnlocked,
                            newUnlockRequirement: newUnlockRequirement,
                            unlockRequirement: index > 0
                                ? 'Complete previous module'
                                : null,
                            onTapCard: () {
                              if (shouldBeUnlocked) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LessonPage(moduleId: lessonId),
                                  ),
                                ).then((_) {
                                  // Reload data when returning from the lesson page
                                  Provider.of<OldCourseProvider>(context, listen: false).loadSingleLessonProgress(lessonId);
                                  Provider.of<DragonProvider>(context, listen: false).updateAllDragonProgress();
                                  // _loadClassData();
                                });
                              }
                            },
                          ),
                        );
                      }),

                    const SizedBox(height: 20),
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