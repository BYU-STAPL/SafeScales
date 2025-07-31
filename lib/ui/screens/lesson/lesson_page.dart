import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/models/lesson_progress.dart';
import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/ui/screens/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/ui/screens/post_quiz/post_quiz_screen.dart';
import 'package:safe_scales/ui/screens/reading/reading_activity_screen.dart';

import '../../../models/lesson.dart';
import '../../../state_management/course_provider.dart';
import '../../../state_management/old_course_provider.dart';
import '../../../state_management/dragon_provider.dart';
import '../../../state_management/old_dragon_provider.dart';
import '../../../themes/app_theme.dart';
import '../../widgets/dragon_image_widget.dart';

class LessonPage extends StatefulWidget {
  final String moduleId;
  final String? topic; // Keep for backward compatibility

  const LessonPage({super.key, required this.moduleId, this.topic,});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  Lesson? _lesson; // Make nullable
  LessonProgress? _lessonProgress; // Make nullable
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    _lesson = (courseProvider.lessons[widget.moduleId])!;
    _lessonProgress = (courseProvider.lessonProgress[widget.moduleId])!;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Consumer2<DragonProvider, CourseProvider>(
      builder: (context, dragonProvider, courseProvider, child) {
        // Show loading if data is not ready
        if (_isLoading || _lesson == null || _lessonProgress == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.topic ?? 'Loading...'),
              centerTitle: true,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.topic ?? _lesson!.title),
            centerTitle: true,
          ),
          body: courseProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dragon image container
              Container(
                width: screenSize.width,
                height: screenSize.height * 0.3, // 30% of screen height
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Center(child: _getDragonImage(dragonProvider)),
              ),

              Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Text(
                  'Lesson Activities',
                  style: theme.textTheme.headlineSmall,
                ),
              ),

              // Existing content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...[
                        _buildQuizCard(
                          title: 'Pre-Quiz',
                          description: 'Test your knowledge before starting',
                          onTap: () => _startQuiz(_lesson!.preQuiz),
                          icon: Icons.quiz,
                          color: theme.colorScheme.primary,
                          isCompleted: _lessonProgress!.isPreQuizComplete,
                          score: _lessonProgress!.preQuizAttempt?.score ?? 0.0,
                          isUnlocked: !_lessonProgress!.isPreQuizComplete, // Only unlock when the pre-quiz is not completed, lock after
                        ),
                        const SizedBox(height: 20),
                      ],
                      _buildReadingCard(isUnlocked: _lessonProgress!.isPreQuizComplete),
                      ...[
                        const SizedBox(height: 20),
                        _buildQuizCard(
                          title: 'Post-Quiz',
                          description: 'Test what you\'ve learned',
                          onTap: () => _startQuiz(_lesson!.postQuiz),
                          icon: Icons.assignment,
                          color: theme.colorScheme.primary,
                          isCompleted: _lessonProgress!.isPostQuizComplete &&
                              (_lessonProgress!.postQuizAttempts.first.score >= _lesson!.postQuiz.passingScore),
                          score: _lessonProgress!.postQuizAttempts.last.score,
                          isUnlocked: _lessonProgress!.isReadingComplete,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuizCard({
    required String title,
    required String description,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required bool isCompleted,
    required bool isUnlocked,
    double? score,
  }) {
    ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color:
        isCompleted
            ? theme.colorScheme.green.withValues(
          alpha: 0.1,
        ) //secondary.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
          isCompleted
              ? theme.colorScheme.green
              : color.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 18 * AppTheme.fontSizeScale,
                            ),
                          ),
                          if (isCompleted) ...[
                            const SizedBox(width: 10),
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.green,
                              size: 18,
                            ),
                          ],
                          if (score != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              '${score.toStringAsFixed(0)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.green,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(description, style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                if (!isUnlocked)
                  Image.asset(
                    'assets/images/other/lock.png',
                    width: 50,
                    height: 50,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadingCard({required bool isUnlocked}) {
    ThemeData theme = Theme.of(context);
    final Color cardBg = theme.colorScheme.surface;
    final Color textColor = theme.colorScheme.onSurface;
    final Color primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
        _lessonProgress!.isReadingComplete
            ? theme.colorScheme.green.withValues(alpha: 0.1)
            : cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
          _lessonProgress!.isReadingComplete
              ? theme.colorScheme.green
              : primary.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
          _lessonProgress!.isPreQuizComplete
              ? () {
            // Navigate to reading activity screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                    ReadingActivityScreen(
                      // topic: widget.topic ?? _moduleTitle,
                      moduleId: widget.moduleId,
                    ),
              ),
            ).then((completed) async {
              if (completed == true) {

                final courseProvider = Provider.of<CourseProvider>(context, listen: false);
                await courseProvider.loadSingleLessonProgress(widget.moduleId);

                await Provider.of<DragonProvider>(context, listen: false).updateAllDragonProgress();


                if (mounted) {
                  setState(() {
                    _lessonProgress = courseProvider.lessonProgress[widget.moduleId];
                  });
                }
              }
            });
          }
              : () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please complete the Pre-Quiz activity first',
                  style: TextStyle(
                    color:
                    Theme
                        .of(context)
                        .colorScheme
                        .onInverseSurface,
                  ),
                ),
                backgroundColor:
                Theme
                    .of(context)
                    .colorScheme
                    .inverseSurface,
              ),
            );
            return;
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: primary.withValues(alpha: 0.1),
                    child: Icon(Icons.menu_book, size: 24, color: primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Reading Activity',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            if (_lessonProgress!.isReadingComplete) ...[
                              const SizedBox(width: 10),
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.green,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Learn about ${widget.topic ?? _lesson!.title}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (!isUnlocked)
                    Image.asset(
                      'assets/images/other/lock.png',
                      width: 50,
                      height: 50,
                      color: textColor.withValues(alpha: 0.5),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 15,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startQuiz(QuestionSet quiz) {
    // Check if quiz has no questions
    if (quiz.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This quiz is not available yet',
            style: TextStyle(
              color: Theme
                  .of(context)
                  .colorScheme
                  .onInverseSurface,
            ),
          ),
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inverseSurface,
        ),
      );
      return;
    }

    // Check if pre-quiz has already been completed
    if (quiz.activityType == ActivityType.preQuiz && _lessonProgress!.isPreQuizComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pre-Quiz has already been completed',
            style: TextStyle(
              color: Theme
                  .of(context)
                  .colorScheme
                  .onInverseSurface,
            ),
          ),
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inverseSurface,
        ),
      );
      return;
    }

    // Check if post-quiz is being attempted before reading is completed
    if (quiz.activityType == ActivityType.postQuiz && !_lessonProgress!.isReadingComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please complete the Reading activity first',
            style: TextStyle(
              color: Theme
                  .of(context)
                  .colorScheme
                  .onInverseSurface,
            ),
          ),
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inverseSurface,
        ),
      );
      return;
    }

    Widget quizScreen;
    if (quiz.activityType == ActivityType.preQuiz) {
      quizScreen = PreQuizScreen(moduleId: widget.moduleId, questionSet: quiz);
    } else {
      quizScreen = PostQuizScreen(moduleId: widget.moduleId, questionSet: quiz);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => quizScreen),
    ).then((completed) async {
      if (completed == true) {
        final courseProvider = Provider.of<CourseProvider>(context, listen: false);
        await courseProvider.loadSingleLessonProgress(widget.moduleId);
        await Provider.of<DragonProvider>(context, listen: false).updateAllDragonProgress();

        if (mounted) {
          setState(() {
            // Update local lesson progress variable
            _lessonProgress = courseProvider.lessonProgress[widget.moduleId];
          });
        }
      }
    });
  }

  Widget _getDragonImage(DragonProvider dragonProvider) {
    return DragonImageWidget(moduleId: widget.moduleId, size: 250);
  }
}