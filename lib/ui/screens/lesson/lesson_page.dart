import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/ui/screens/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/ui/screens/post_quiz/post_quiz_screen.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/ui/screens/reading/reading_activity_screen.dart';
import 'package:safe_scales/services/class_service.dart';

import '../../../state_management/course_provider.dart';
import '../../../state_management/dragon_provider.dart';
import '../../../themes/app_theme.dart';
import '../../widgets/dragon_image_widget.dart';

class LessonPage extends StatefulWidget {
  final String moduleId;
  final String? topic; // Keep for backward compatibility

  const LessonPage({super.key, required this.moduleId, this.topic,})
      : assert(
  topic != null || moduleId != null,
  'Either topic or moduleId must be provided',
  );

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  bool preQuizCompleted = false;
  bool readingCompleted = false;
  bool postQuizCompleted = false;
  double? preQuizScore;
  double? postQuizScore;

  final QuizService _quizService = QuizService();
  final UserStateService _userState = UserStateService();
  late final ClassService _classService;

  QuestionSet? _preQuiz;
  QuestionSet? _postQuiz;
  bool _isLoading = true;
  Map<String, dynamic>? _dragonData;
  Map<String, dynamic>? _moduleData;
  String _moduleTitle = '';
  double _moduleProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _classService = ClassService(_quizService.supabase);
    _initializeData();
  }

  Future<void> _initializeData() async {
    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
    await dragonProvider.initialize();
    await dragonProvider.loadUserDragons();
    await _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      QuestionSet? preQuiz;
      QuestionSet? postQuiz;

      if (widget.moduleId != null) {
        // Load module data
        _moduleData = await _classService.getModuleById(widget.moduleId!);
        if (_moduleData != null) {
          _moduleTitle = _moduleData!['title'] ?? 'Module';
        }

        // Get module-based quizzes
        preQuiz = await _quizService.getQuizByModuleId(
          moduleId: widget.moduleId!,
          activityType: 'preQuiz',
        );

        postQuiz = await _quizService.getQuizByModuleId(
          moduleId: widget.moduleId!,
          activityType: 'postQuiz',
        );

        // If quizzes have no questions, mark them as complete with 100% score
        if (preQuiz != null && preQuiz.questions.isEmpty) {
          setState(() {
            preQuizCompleted = true;
            preQuizScore = 100.0;
          });
        }

        if (postQuiz != null && postQuiz.questions.isEmpty) {
          setState(() {
            postQuizCompleted = true;
            postQuizScore = 100.0;
          });
        }
      } else if (widget.topic != null) {
        // Fallback to topic-based system for backward compatibility
        _moduleTitle = widget.topic!;

        preQuiz = await _quizService.getQuizByTopicAndActivityType(
          topic: widget.topic!,
          activityType: 'preQuiz',
        );

        postQuiz = await _quizService.getQuizByTopicAndActivityType(
          topic: widget.topic!,
          activityType: 'postQuiz',
        );

        // If quizzes have no questions, mark them as complete with 100% score
        if (preQuiz != null && preQuiz.questions.isEmpty) {
          setState(() {
            preQuizCompleted = true;
            preQuizScore = 100.0;
          });
        }

        if (postQuiz != null && postQuiz.questions.isEmpty) {
          setState(() {
            postQuizCompleted = true;
            postQuizScore = 100.0;
          });
        }
      }

      // Get user's quiz progress
      final user = _userState.currentUser;
      if (user != null) {
        final response =
        await _quizService.supabase
            .from('Users')
            .select('quizzes, modules')
            .eq('id', user.id)
            .single();

        // Check new modules column first
        if (response['modules'] != null && widget.moduleId != null) {
          final modulesData = Map<String, dynamic>.from(response['modules']);

          if (modulesData.containsKey(widget.moduleId!)) {
            final moduleData = Map<String, dynamic>.from(
              modulesData[widget.moduleId!],
            );

            // Check for pre-quiz completion
            if (moduleData.containsKey('preQuiz')) {
              final preQuizData = moduleData['preQuiz'];
              setState(() {
                preQuizCompleted = true;
                preQuizScore = preQuizData['score'].toDouble();
              });
            }

            // Check for reading completion
            if (moduleData.containsKey('reading')) {
              final readingData = moduleData['reading'];
              setState(() {
                readingCompleted = readingData['completed'] == true;
              });
            }

            // Check for post-quiz completion
            if (moduleData.containsKey('postQuiz')) {
              final postQuizData = moduleData['postQuiz'];
              setState(() {
                postQuizCompleted = true;
                postQuizScore = postQuizData['score'].toDouble();
              });
            }
          }
        }

        // Fallback to old quizzes column if not found in modules
        if (response['quizzes'] != null) {
          final quizzesData = Map<String, dynamic>.from(response['quizzes']);

          // Check for module-based quiz IDs first (if not already found in modules column)
          if (widget.moduleId != null &&
              !preQuizCompleted &&
              !postQuizCompleted) {
            final preQuizId = '${widget.moduleId}_preQuiz';
            final postQuizId = '${widget.moduleId}_postQuiz';

            if (quizzesData.containsKey(preQuizId)) {
              final preQuizData = quizzesData[preQuizId];
              setState(() {
                preQuizCompleted = true;
                preQuizScore = preQuizData['score'].toDouble();
              });
            }

            if (quizzesData.containsKey(postQuizId)) {
              final postQuizData = quizzesData[postQuizId];
              setState(() {
                postQuizCompleted = true;
                postQuizScore = postQuizData['score'].toDouble();
              });
            }
          }

          // Fallback to old quiz IDs (for backward compatibility)
          if (preQuiz != null &&
              quizzesData.containsKey(preQuiz.id) &&
              !preQuizCompleted) {
            final preQuizData = quizzesData[preQuiz.id];
            setState(() {
              preQuizCompleted = true;
              preQuizScore = preQuizData['score'].toDouble();
            });
          }

          if (postQuiz != null &&
              quizzesData.containsKey(postQuiz.id) &&
              !postQuizCompleted) {
            final postQuizData = quizzesData[postQuiz.id];
            setState(() {
              postQuizCompleted = true;
              postQuizScore = postQuizData['score'].toDouble();
            });
          }
        }
      }

      setState(() {
        _preQuiz = preQuiz;
        _postQuiz = postQuiz;
        _isLoading = false;
      });
    } catch (e) {
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
        // Use the loaded module progress for module-based lessons
        double topicProgress = _moduleProgress;

        // Fallback to quiz-based calculation for backward compatibility (topic-based lessons)
        if (widget.moduleId == null) {
          if (preQuizCompleted &&
              postQuizCompleted &&
              preQuizScore != null &&
              postQuizScore != null) {
            topicProgress = (preQuizScore! / 2) + (postQuizScore! / 2);
          } else if (preQuizCompleted && preQuizScore != null) {
            topicProgress = preQuizScore! / 2;
          } else if (postQuizCompleted && postQuizScore != null) {
            topicProgress = postQuizScore! / 2;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.topic ?? _moduleTitle),
            centerTitle: true,
          ),
          body: _isLoading
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
                      if (_preQuiz != null) ...[
                        _buildQuizCard(
                          title: 'Pre-Quiz',
                          description: 'Test your knowledge before starting',
                          onTap: () => _startQuiz(_preQuiz!),
                          icon: Icons.quiz,
                          color: theme.colorScheme.primary,
                          isCompleted: preQuizCompleted,
                          score: preQuizScore,
                          isUnlocked: !preQuizCompleted, // Only unlock when the pre-quiz is not completed, lock after
                        ),
                        const SizedBox(height: 20),
                      ],
                      _buildReadingCard(isUnlocked: preQuizCompleted),
                      if (_postQuiz != null) ...[
                        const SizedBox(height: 20),
                        _buildQuizCard(
                          title: 'Post-Quiz',
                          description: 'Test what you\'ve learned',
                          onTap: () => _startQuiz(_postQuiz!),
                          icon: Icons.assignment,
                          color: theme.colorScheme.primary,
                          isCompleted: postQuizCompleted &&
                              (postQuizScore! >= _postQuiz!.passingScore),
                          score: postQuizScore,
                          isUnlocked: readingCompleted,
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
        readingCompleted
            ? theme.colorScheme.green.withValues(alpha: 0.1)
            : cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
          readingCompleted
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
          preQuizCompleted
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
            ).then((completed) {
              if (completed == true) {
                setState(() {
                  readingCompleted = true;

                  // TODO: Move load module progress into a different provider
                  // TODO: Currently loadUser dragons also updates module progress
                  final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
                  dragonProvider.loadUserProgress();
                });
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
                    backgroundColor: primary.withOpacity(0.1),
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
                            if (readingCompleted) ...[
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
                          'Learn about ${widget.topic ?? _moduleTitle}',
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
    if (quiz.activityType == ActivityType.preQuiz && preQuizCompleted) {
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
    if (quiz.activityType == ActivityType.postQuiz && !readingCompleted) {
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
    ).then((completed) {
      if (completed == true) {
        setState(() {
          if (quiz.activityType == ActivityType.preQuiz) {
            preQuizCompleted = true;
          } else if (quiz.activityType == ActivityType.postQuiz &&
              postQuizScore != null &&
              _postQuiz != null &&
              postQuizScore! >= _postQuiz!.passingScore) {
            postQuizCompleted = true;
          }
        });
        _loadQuizzes(); // Reload quizzes to update scores
        // _loadModuleProgress(); // Update dragon


        // Reload dragon data after quiz completion
        final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
        dragonProvider.loadUserDragons();
      }
    });
  }

  Widget _getDragonImage(DragonProvider dragonProvider) {
    return DragonImageWidget(moduleId: widget.moduleId, size: 250);
  }
}