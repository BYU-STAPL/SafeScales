import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/quiz/post_quiz_screen.dart';
import 'package:safe_scales/services/quiz_service.dart';

class SocialMediaNormsPage extends StatefulWidget {
  const SocialMediaNormsPage({super.key});

  @override
  State<SocialMediaNormsPage> createState() => _SocialMediaNormsPageState();
}

class _SocialMediaNormsPageState extends State<SocialMediaNormsPage> {
  bool preQuizCompleted = false;
  bool readingCompleted = false;
  bool postQuizCompleted = false;

  final QuizService _quizService = QuizService();
  QuestionSet? _preQuiz;
  QuestionSet? _postQuiz;
  bool _isLoading = true;
  String _topicName = '';

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      // Get pre-quiz for Social Media Norms topic
      final preQuiz = await _quizService.getQuizByTopicAndActivityType(
        topic: 'Social Media Norms',
        activityType: 'preQuiz',
      );

      // Get post-quiz for Social Media Norms topic
      final postQuiz = await _quizService.getQuizByTopicAndActivityType(
        topic: 'Social Media Norms',
        activityType: 'postQuiz',
      );

      setState(() {
        _preQuiz = preQuiz;
        _postQuiz = postQuiz;
        _topicName = 'Social Media Norms';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading quizzes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color cardBg = Theme.of(context).colorScheme.surface;
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _topicName,
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Dragon Display Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Placeholder for dragon image
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.pets,
                              size: 120,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Your Dragon',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Complete activities to help your dragon grow!',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Activities Section
                    Row(
                      children: [
                        Text(
                          'Activities',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${preQuizCompleted ? 1 : 0}/${3} Completed',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Activities List
                    Expanded(
                      child: Column(
                        children: [
                          // Pre-Quiz
                          _buildActivityCard(
                            title: 'Pre-Quiz',
                            subtitle:
                                _preQuiz?.description ??
                                'Test your current knowledge',
                            icon: Icons.quiz,
                            color: primary,
                            isCompleted: preQuizCompleted,
                            isLocked: false,
                            isAvailable: true,
                            onTap: () {
                              if (_preQuiz != null) {
                                _startPreQuiz(context);
                              }
                            },
                          ),
                          const SizedBox(height: 8),

                          // Reading Activity
                          _buildActivityCard(
                            title: 'Reading Activity',
                            subtitle: 'Learn about $_topicName',
                            icon: Icons.menu_book,
                            color: primary,
                            isCompleted: readingCompleted,
                            isLocked: !preQuizCompleted,
                            isAvailable: preQuizCompleted,
                            onTap: () {
                              if (preQuizCompleted) {
                                _startReading(context);
                              }
                            },
                          ),
                          const SizedBox(height: 8),

                          // Post-Quiz
                          _buildActivityCard(
                            title: 'Post-Quiz',
                            subtitle:
                                _postQuiz?.description ??
                                'Test what you learned',
                            icon: Icons.assignment,
                            color: primary,
                            isCompleted: postQuizCompleted,
                            isLocked: !readingCompleted,
                            isAvailable: readingCompleted,
                            onTap: () {
                              if (readingCompleted && _postQuiz != null) {
                                _startPostQuiz(context);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isCompleted,
    required bool isLocked,
    required bool isAvailable,
    VoidCallback? onTap,
  }) {
    final cardColor =
        isLocked
            ? Colors.grey[300]!
            : isCompleted
            ? color.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface;

    final iconColor =
        isLocked
            ? Colors.grey[600]!
            : isCompleted
            ? color
            : color.withOpacity(0.8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? color : Colors.grey[300]!,
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  isLocked
                      ? Image.asset(
                        'assets/images/other/lock.png',
                        width: 64,
                        height: 64,
                      )
                      : Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isLocked ? Colors.grey[600] : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isLocked ? Colors.grey[600] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              Icon(Icons.check_circle, color: color, size: 24)
            else if (!isLocked && isAvailable)
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  void _startPreQuiz(BuildContext context) {
    if (_preQuiz == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pre-quiz not available. Please upload it first.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreQuizScreen(questionSet: _preQuiz!),
      ),
    ).then((completed) {
      if (completed == true) {
        setState(() {
          preQuizCompleted = true;
        });
      }
    });
  }

  void _startReading(BuildContext context) {
    // TODO: Implement reading activity
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reading activity coming soon!')),
    );
    // For now, mark as completed
    setState(() {
      readingCompleted = true;
    });
  }

  void _startPostQuiz(BuildContext context) {
    if (_postQuiz == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post-quiz not available. Please upload it first.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostQuizScreen(questionSet: _postQuiz!),
      ),
    ).then((completed) {
      if (completed == true) {
        setState(() {
          postQuizCompleted = true;
        });
        // Show completion dialog or navigate back
        _showCompletionDialog(context);
      }
    });
  }

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Activity Complete!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'You have completed the $_topicName activity!',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to home
                },
                child: const Text('CONTINUE'),
              ),
            ],
          ),
    );
  }
}
