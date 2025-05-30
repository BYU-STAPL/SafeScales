import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/services/user_state_service.dart';

import 'lesson/lesson_page.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.fontSize,
    required this.onFontSizeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final QuizService _quizService = QuizService();
  final _userState = UserStateService();
  String? _username;

  List<String> _topics = [];
  Map<String, List<Map<String, dynamic>>> _quizzesByTopic = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    try {
      final username = await _userState.getUserName();
      print('Loaded username in home page: $username'); // Debug log
      if (mounted) {
        setState(() {
          _username = username;
        });
      }
    } catch (e) {
      print('Error loading username in home page: $e');
    }
  }

  Future<void> _loadQuizzes() async {
    try {
      final allQuizzes = await _quizService.getAllQuizzes();

      // Group quizzes by topic
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var quiz in allQuizzes) {
        final topic = quiz['topic'] ?? 'Unknown Topic';
        if (!grouped.containsKey(topic)) {
          grouped[topic] = [];
        }
        grouped[topic]!.add(quiz);
      }

      setState(() {
        _quizzesByTopic = grouped;
        _topics = grouped.keys.toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading quizzes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get icon based on topic from database
  IconData _getIconForTopic(String topic) {
    // Default to school icon if no specific icon is found
    return Icons.school;
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
                // Welcome Section
                Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${_username ?? 'User'}!',
                        style: GoogleFonts.poppins(
                          fontSize: 24 * AppTheme.fontSizeScale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ready to learn something new today?',
                        style: GoogleFonts.poppins(
                          fontSize: 16 * AppTheme.fontSizeScale,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Continue Learning Card
                if (_topics.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      // Navigate to the current/next activity
                      final currentTopic = _topics[0];
                      final quizzes = _quizzesByTopic[currentTopic] ?? [];
                      if (quizzes.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => LessonPage(topic: currentTopic),
                          ),
                        );
                      }
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
                              Text(
                                _topics[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 14 * AppTheme.fontSizeScale,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '30% Complete',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12 * AppTheme.fontSizeScale,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
                    Text(
                      '${_topics.isEmpty ? 0 : 1}/${_topics.length} Completed',
                      style: GoogleFonts.poppins(
                        fontSize: 14 * AppTheme.fontSizeScale,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
                        index == 0; // Only first topic is unlocked
                    final progress = index == 0 ? 0.3 : 0.0; // Mock progress

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildActivityCard(
                        context: context,
                        title: topic,
                        isUnlocked: isUnlocked,
                        progress: progress,
                        icon: _getIconForTopic(topic),
                        iconColor: _getColorForTopic(topic),
                        unlockRequirement:
                            index > 0 ? 'Complete ${_topics[index - 1]}' : null,
                        onTap: () {
                          if (isUnlocked && quizzes.isNotEmpty) {
                            // Navigate to the activity page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LessonPage(topic: topic),
                              ),
                            );
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
                  icon: Icons.settings,
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
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    String? unlockRequirement,
  }) {
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
      onTap: isUnlocked ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: isUnlocked ? cardBg : lockedBg,
          borderRadius: BorderRadius.circular(borderRadius),
          border:
              isUnlocked
                  ? null
                  : Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
          boxShadow:
              isUnlocked
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
                color: isUnlocked ? textColor : mutedTextColor,
                letterSpacing: 0.8,
              ),
            ),
            if (!isUnlocked && unlockRequirement != null) ...[
              const SizedBox(height: 4),
              Text(
                unlockRequirement,
                style: GoogleFonts.poppins(
                  fontSize: 12 * AppTheme.fontSizeScale,
                  color: mutedTextColor.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (isUnlocked) ...[
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
                  if (isUnlocked)
                    CustomPaint(
                      size: const Size(160, 80),
                      painter: _SemiCircleProgressPainter(
                        color: secondary,
                        progress: progress,
                      ),
                    ),
                  // Icon in circle
                  Positioned(
                    top: 35,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          isUnlocked ? iconColor : Colors.grey[400],
                      child: Icon(
                        isUnlocked ? icon : Icons.lock,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isUnlocked) ...[
              Text(
                '${(progress * 100).round()}% Complete',
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
