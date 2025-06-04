import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/dragon_service.dart';

import 'lesson/lesson_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final QuizService _quizService = QuizService();
  final _userState = UserStateService();
  final _dragonService = DragonService(QuizService().supabase);
  String? _username;

  List<String> _topics = [];
  Map<String, List<Map<String, dynamic>>> _quizzesByTopic = {};
  Map<String, double> _topicProgress = {};
  Map<String, Map<String, dynamic>> _moduleDragons = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this page
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      final allQuizzes = await _quizService.getAllQuizzes();
      final user = _userState.currentUser;

      // Group quizzes by topic
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var quiz in allQuizzes) {
        final topic = quiz['topic'] ?? 'Unknown Topic';
        if (!grouped.containsKey(topic)) {
          grouped[topic] = [];
        }
        grouped[topic]!.add(quiz);
      }

      // Calculate progress for each topic
      if (user != null) {
        for (var topic in grouped.keys) {
          // Get all quizzes for this topic
          final topicQuizzes = await _quizService.supabase
              .from('quizzes')
              .select()
              .eq('topic', topic)
              .order('created_at', ascending: true);

          // Get user's quiz progress
          final response =
              await _quizService.supabase
                  .from('Users')
                  .select('quizzes')
                  .eq('id', user.id)
                  .single();

          if (response['quizzes'] != null) {
            final quizzesData = Map<String, dynamic>.from(response['quizzes']);

            double preQuizScore = 0;
            double postQuizScore = 0;
            bool hasPreQuiz = false;
            bool hasPostQuiz = false;

            // Find pre and post quiz scores
            for (var quiz in topicQuizzes) {
              final quizId = quiz['id'].toString();
              final activityType =
                  quiz['activity_type'].toString().toLowerCase();

              if (quizzesData.containsKey(quizId)) {
                final quizData = quizzesData[quizId];

                if (activityType == 'prequiz') {
                  preQuizScore = quizData['score'].toDouble();
                  hasPreQuiz = true;
                } else if (activityType == 'postquiz') {
                  postQuizScore = quizData['score'].toDouble();
                  hasPostQuiz = true;
                }
              }
            }

            // Calculate progress
            double progress = 0;
            if (hasPreQuiz && hasPostQuiz) {
              progress = (preQuizScore / 2) + (postQuizScore / 2);
            } else if (hasPreQuiz) {
              progress = preQuizScore / 2;
            } else if (hasPostQuiz) {
              progress = postQuizScore / 2;
            }

            _topicProgress[topic] = progress;
          } else {
            _topicProgress[topic] = 0;
          }
        }
      }

      if (mounted) {
        setState(() {
          _quizzesByTopic = grouped;
          _topics = grouped.keys.toList();
          _isLoading = false;
        });

        await _loadDragonImages();
      }
    } catch (e) {
      print('✗ Error loading quizzes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDragonImages() async {
    try {
      await _dragonService.initialize();

      for (var i = 0; i < _topics.length; i++) {
        final dragonData = await _dragonService.getDragonImagesForModule(i);
        if (mounted) {
          setState(() {
            _moduleDragons[_topics[i]] = dragonData;
          });
        }
      }
    } catch (e) {
      print('✗ Error loading dragon images: $e');
    }
  }

  // Get icon based on topic progress
  Widget _getDragonPhaseIcon(String topic) {
    final progress = _topicProgress[topic] ?? 0.0;
    final dragonData = _moduleDragons[topic];

    if (dragonData == null) {
      print('✗ No dragon data found for topic: $topic');
    }

    String imageUrl = dragonData?['egg'] ?? 'assets/images/other/egg.png';
    List<String> phases = ['egg']; // Always start with egg

    // Add phases based on progress, ensuring all previous phases are included
    if (progress >= 30) {
      phases.add('stage1'); // Add baby phase
    }
    if (progress >= 50) {
      phases.add('stage2'); // Add teen phase
    }
    if (progress >= 80) {
      phases.add('final'); // Add adult phase
    }

    // Save dragon phases if we have a valid dragon ID
    if (dragonData != null && dragonData['id'] != null) {
      final user = _userState.currentUser;
      if (user != null) {
        _dragonService
            .saveDragonPhases(user.id, dragonData['id'].toString(), phases)
            .catchError((e) {
              print('✗ Error saving dragon phases: $e');
            });
      }
    }

    // Set the image URL based on the highest achieved phase
    if (progress >= 80) {
      imageUrl = dragonData?['final'] ?? 'assets/images/other/adult.png';
    } else if (progress >= 50) {
      imageUrl = dragonData?['stage2'] ?? 'assets/images/other/teen.png';
    } else if (progress >= 30) {
      imageUrl = dragonData?['stage1'] ?? 'assets/images/other/young.png';
    }

    // Check if the image URL is a network URL or a local asset
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 64,
        height: 64,
        errorBuilder: (context, error, stackTrace) {
          print('✗ Error loading dragon image for topic $topic: $error');
          return Image.asset(
            'assets/images/other/egg.png',
            width: 64,
            height: 64,
          );
        },
      );
    } else {
      return Image.asset(imageUrl, width: 64, height: 64);
    }
  }

  // Get color based on topic from database
  Color _getColorForTopic(String topic) {
    // Default to grey if no specific color is found
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final cardBg = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final mutedTextColor = theme.colorScheme.onSurfaceVariant;
    final lockedBg = theme.colorScheme.surfaceVariant;
    const borderRadius = 16.0;

    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Continue Learning Card
                if (_topics.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      // Find the latest incomplete activity
                      String? targetTopic;
                      for (var topic in _topics) {
                        final progress = _topicProgress[topic] ?? 0.0;
                        if (progress < 100) {
                          targetTopic = topic;
                          break;
                        }
                      }

                      // If all activities are complete, go to the last topic
                      targetTopic ??= _topics.last;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonPage(topic: targetTopic!),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary.withOpacity(0.9), primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Continue Learning',
                                style: GoogleFonts.poppins(
                                  fontSize: 22 * AppTheme.fontSizeScale,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Builder(
                                builder: (context) {
                                  // Find the target topic
                                  String? targetTopic;
                                  for (var topic in _topics) {
                                    final progress =
                                        _topicProgress[topic] ?? 0.0;
                                    if (progress < 100) {
                                      targetTopic = topic;
                                      break;
                                    }
                                  }
                                  targetTopic ??= _topics.last;

                                  return Text(
                                    targetTopic.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14 * AppTheme.fontSizeScale,
                                      color: Colors.white.withOpacity(0.9),
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  // Find the target topic and its progress
                                  String? targetTopic;
                                  double progress = 0;
                                  for (var topic in _topics) {
                                    final topicProgress =
                                        _topicProgress[topic] ?? 0.0;
                                    if (topicProgress < 100) {
                                      targetTopic = topic;
                                      progress = topicProgress;
                                      break;
                                    }
                                  }
                                  if (targetTopic == null) {
                                    targetTopic = _topics.last;
                                    progress =
                                        _topicProgress[targetTopic] ?? 0.0;
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${progress.toStringAsFixed(0)}% Complete',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12 * AppTheme.fontSizeScale,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 24 * AppTheme.fontSizeScale,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                // Activities Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activities',
                      style: GoogleFonts.poppins(
                        fontSize: 20 * AppTheme.fontSizeScale,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        // Count completed activities (100% progress)
                        final completedCount =
                            _topics
                                .where(
                                  (topic) =>
                                      (_topicProgress[topic] ?? 0.0) >= 100,
                                )
                                .length;

                        return Text(
                          '${completedCount}/${_topics.length} Completed',
                          style: GoogleFonts.poppins(
                            fontSize: 14 * AppTheme.fontSizeScale,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Show loading or activities
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_topics.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No activities available',
                        style: GoogleFonts.poppins(
                          fontSize: 16 * AppTheme.fontSizeScale,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  // Dynamic activities list
                  ..._topics.asMap().entries.map((entry) {
                    final index = entry.key;
                    final topic = entry.value;
                    final quizzes = _quizzesByTopic[topic] ?? [];
                    final isUnlocked =
                        index == 0 ||
                        (_topicProgress[_topics[index - 1]] ?? 0) >= 100;
                    final progress = _topicProgress[topic] ?? 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildActivityCard(
                        context: context,
                        title: topic,
                        isUnlocked: isUnlocked,
                        progress: progress,
                        dragonIcon: _getDragonPhaseIcon(topic),
                        iconColor: _getColorForTopic(topic),
                        unlockRequirement:
                            index > 0 ? 'Complete ${_topics[index - 1]}' : null,
                        onTap: () {
                          if (isUnlocked) {
                            print('Navigating to topic: $topic'); // Debug log
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LessonPage(topic: topic),
                              ),
                            ).then((_) {
                              // Reload quizzes when returning from the lesson page
                              _loadQuizzes();
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),

                const SizedBox(height: 24),

                // Settings Activity - Always shown at the end
                _buildActivityCard(
                  context: context,
                  title: 'SETTINGS',
                  isUnlocked: false,
                  progress: 0.0,
                  dragonIcon: _getDragonPhaseIcon('SETTINGS'),
                  iconColor: Colors.grey[700]!,
                  unlockRequirement: 'Complete all activities',
                  onTap: () {
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required BuildContext context,
    required String title,
    required bool isUnlocked,
    required double progress,
    required Widget dragonIcon,
    required Color iconColor,
    required VoidCallback onTap,
    String? unlockRequirement,
  }) {
    // Get actual progress for this topic
    final actualProgress = _topicProgress[title] ?? 0.0;

    // Check if this activity should be unlocked
    final int currentIndex = _topics.indexOf(title);
    bool shouldBeUnlocked = false;
    String? newUnlockRequirement;

    if (currentIndex == 0) {
      // First activity is always unlocked
      shouldBeUnlocked = true;
    } else if (currentIndex > 0) {
      // Check if previous activity is completed
      final previousTopic = _topics[currentIndex - 1];
      final previousProgress = _topicProgress[previousTopic] ?? 0.0;
      shouldBeUnlocked = previousProgress >= 100;
      if (!shouldBeUnlocked) {
        newUnlockRequirement =
            'Complete ${previousTopic} (${previousProgress.toStringAsFixed(0)}%)';
      }
    }

    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Theme.of(context).colorScheme.secondary;
    final Color cardBg = Theme.of(context).colorScheme.surface;
    final Color lockedBg =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color mutedTextColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final double borderRadius = 24.0;

    // Get quiz info for this topic
    final quizzes = _quizzesByTopic[title] ?? [];
    final hasPreQuiz = quizzes.isNotEmpty && quizzes[0]['has_pre_quiz'] == true;
    final hasPostQuiz =
        quizzes.isNotEmpty && quizzes[0]['has_post_quiz'] == true;
    final description =
        quizzes.isNotEmpty ? quizzes[0]['description'] : 'Learn about $title';

    return GestureDetector(
      onTap: shouldBeUnlocked ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: shouldBeUnlocked ? cardBg : lockedBg,
          borderRadius: BorderRadius.circular(borderRadius),
          border:
              shouldBeUnlocked
                  ? null
                  : Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
          boxShadow:
              shouldBeUnlocked
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20 * AppTheme.fontSizeScale,
                fontWeight: FontWeight.bold,
                color: shouldBeUnlocked ? textColor : mutedTextColor,
                letterSpacing: 0.8,
              ),
            ),
            if (!shouldBeUnlocked &&
                (newUnlockRequirement != null ||
                    unlockRequirement != null)) ...[
              const SizedBox(height: 4),
              Text(
                newUnlockRequirement ?? unlockRequirement ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 12 * AppTheme.fontSizeScale,
                  color: mutedTextColor.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (shouldBeUnlocked) ...[
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14 * AppTheme.fontSizeScale,
                  color: mutedTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasPreQuiz)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.quiz, size: 16, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            'Pre-Quiz',
                            style: GoogleFonts.poppins(
                              fontSize: 12 * AppTheme.fontSizeScale,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hasPreQuiz && hasPostQuiz) const SizedBox(width: 8),
                  if (hasPostQuiz)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment, size: 16, color: secondary),
                          const SizedBox(width: 4),
                          Text(
                            'Post-Quiz',
                            style: GoogleFonts.poppins(
                              fontSize: 12 * AppTheme.fontSizeScale,
                              color: secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Semi-circular progress bar with icon
            SizedBox(
              height: 100,
              width: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Semi-circular progress
                  if (shouldBeUnlocked)
                    CustomPaint(
                      size: const Size(160, 80),
                      painter: _SemiCircleProgressPainter(
                        color: secondary,
                        progress:
                            actualProgress /
                            100, // Convert percentage to decimal
                      ),
                    ),
                  // Icon in circle
                  shouldBeUnlocked
                      ? Positioned(top: 35, child: dragonIcon)
                      : Positioned(
                        top: 10,
                        child: Image.asset(
                          'assets/images/other/lock.png',
                          width: 96,
                          height: 96,
                        ),
                      ),
                ],
              ),
            ),
            if (shouldBeUnlocked) ...[
              Text(
                '${actualProgress.toStringAsFixed(0)}% Complete',
                style: GoogleFonts.poppins(
                  fontSize: 13 * AppTheme.fontSizeScale,
                  color: primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Custom painter for semi-circular progress bar
class _SemiCirclePainter extends CustomPainter {
  final Color color;
  _SemiCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = 16
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    canvas.drawArc(rect, 3.14, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for semi-circular progress bar with progress
class _SemiCircleProgressPainter extends CustomPainter {
  final Color color;
  final double progress;

  _SemiCircleProgressPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Background arc
    final Paint backgroundPaint =
        Paint()
          ..color = color.withOpacity(0.2)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Progress arc
    final Paint progressPaint =
        Paint()
          ..color = color
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    // Draw background arc (full semi-circle)
    canvas.drawArc(rect, 3.14159, 3.14159, false, backgroundPaint);

    // Draw progress arc (partial semi-circle based on progress)
    if (progress > 0) {
      canvas.drawArc(rect, 3.14159, 3.14159 * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SemiCircleProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
