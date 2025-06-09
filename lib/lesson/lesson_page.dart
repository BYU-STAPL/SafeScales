import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/quiz/post_quiz_screen.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/dragon_service.dart';
import 'package:safe_scales/reading/reading_activity_screen.dart';
import 'package:safe_scales/services/class_service.dart';

import '../themes/app_theme.dart';

class LessonPage extends StatefulWidget {
  final String? topic; // Keep for backward compatibility
  final String? moduleId; // New parameter

  const LessonPage({super.key, this.topic, this.moduleId})
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
  final DragonService _dragonService = DragonService(QuizService().supabase);
  late final ClassService _classService;

  QuestionSet? _preQuiz;
  QuestionSet? _postQuiz;
  bool _isLoading = true;
  Map<String, dynamic>? _dragonData;
  Map<String, dynamic>? _moduleData;
  String _moduleTitle = '';

  @override
  void initState() {
    super.initState();
    _classService = ClassService(_quizService.supabase);
    _loadQuizzes();
    _loadDragonImages();
  }

  Future<void> _loadDragonImages() async {
    try {
      // If using module-based system
      if (widget.moduleId != null) {
        // Try to get dragon from class assets first
        // This will be implemented when we have access to class assets
        // For now, use the fallback system
      }

      // Fallback to old system for backward compatibility
      await _dragonService.initialize();

      // Get the index of the current topic
      final allQuizzes = await _quizService.getAllQuizzes();
      final topics =
          allQuizzes.map((q) => q['topic'] as String).toSet().toList();
      final topicIndex = topics.indexOf(widget.topic ?? _moduleTitle);

      if (topicIndex != -1) {
        final dragonData = await _dragonService.getDragonImagesForModule(
          topicIndex,
        );
        if (mounted) {
          setState(() {
            _dragonData = dragonData;
          });
        }
      }
    } catch (e) {
      print('Error loading dragon images: $e');
    }
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

    double topicProgress = 0.0;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic ?? _moduleTitle),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
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
                    child: Center(child: _getDragonPhaseIcon(topicProgress)),
                  ),
                  // Existing content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_preQuiz != null) ...[
                            _buildQuizCard(
                              title: 'Pre-Quiz',
                              description:
                                  'Test your knowledge before starting',
                              onTap: () => _startQuiz(_preQuiz!),
                              icon: Icons.quiz,
                              color: theme.colorScheme.primary,
                              isCompleted: preQuizCompleted,
                              score: preQuizScore,
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildReadingCard(),
                          if (_postQuiz != null) ...[
                            const SizedBox(height: 16),
                            _buildQuizCard(
                              title: 'Post-Quiz',
                              description: 'Test what you\'ve learned',
                              onTap: () => _startQuiz(_postQuiz!),
                              icon: Icons.assignment,
                              color: theme.colorScheme.primary,
                              isCompleted: postQuizCompleted,
                              score: postQuizScore,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildQuizCard({
    required String title,
    required String description,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required bool isCompleted,
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
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (isCompleted) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.green,
                              size: 16,
                            ),
                            if (score != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${score.toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.green,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadingCard() {
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
                            (context) => ReadingActivityScreen(
                              topic: widget.topic ?? _moduleTitle,
                            ),
                      ),
                    ).then((completed) {
                      if (completed == true) {
                        setState(() {
                          readingCompleted = true;
                        });
                      }
                    });
                  }
                  : null,
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
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            if (readingCompleted) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Learn about ${widget.topic ?? _moduleTitle}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (!preQuizCompleted)
                    Image.asset(
                      'assets/images/other/lock.png',
                      width: 56,
                      height: 56,
                      color: textColor.withOpacity(0.5),
                    )
                  else if (!readingCompleted)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: textColor.withOpacity(0.5),
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
    // Check if post-quiz is being attempted before reading is completed
    if (quiz.activityType == ActivityType.postQuiz && !readingCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please complete the reading activity first',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        ),
      );
      return;
    }

    Widget quizScreen;
    if (quiz.activityType == ActivityType.preQuiz) {
      quizScreen = PreQuizScreen(questionSet: quiz);
    } else {
      quizScreen = PostQuizScreen(questionSet: quiz);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => quizScreen),
    ).then((completed) {
      if (completed == true) {
        setState(() {
          if (quiz.activityType == ActivityType.preQuiz) {
            preQuizCompleted = true;
          } else if (quiz.activityType == ActivityType.postQuiz) {
            postQuizCompleted = true;
          }
        });
        _loadQuizzes(); // Reload quizzes to update scores
      }
    });
  }

  Widget _getDragonPhaseIcon(double progress) {
    String imageUrl = _dragonData?['egg'] ?? 'assets/images/other/egg.png';

    if (progress >= 80) {
      imageUrl = _dragonData?['final'] ?? 'assets/images/other/adult.png';
    } else if (progress >= 50) {
      imageUrl = _dragonData?['stage2'] ?? 'assets/images/other/teen.png';
    } else if (progress >= 30) {
      imageUrl = _dragonData?['stage1'] ?? 'assets/images/other/young.png';
    }

    // Check if the image URL is a network URL or a local asset
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 240,
        height: 240,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/other/egg.png',
            width: 240,
            height: 240,
          );
        },
      );
    } else {
      return Image.asset(imageUrl, width: 240, height: 240);
    }
  }
}
