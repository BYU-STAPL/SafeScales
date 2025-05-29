import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/quiz/post_quiz_screen.dart';

class SocialMediaNormsPage extends StatefulWidget {
  const SocialMediaNormsPage({super.key});

  @override
  State<SocialMediaNormsPage> createState() => _SocialMediaNormsPageState();
}

class _SocialMediaNormsPageState extends State<SocialMediaNormsPage> {
  bool preQuizCompleted = false;
  bool readingCompleted = false;
  bool postQuizCompleted = false;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color cardBg = Theme.of(context).colorScheme.surface;
    final Color greyColor = Colors.grey[400]!;
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: primary, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'SOCIAL MEDIA NORMS',
                      style: GoogleFonts.poppins(
                        fontSize: 18 * AppTheme.fontSizeScale,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            // Dragon name with arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Boskaris Dragon',
                    style: GoogleFonts.poppins(
                      fontSize: 16 * AppTheme.fontSizeScale,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.red, size: 20),
                ],
              ),
            ),
            // Dragon egg
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Egg container
                    Container(
                      width: 160,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(80),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Egg pattern
                          Container(
                            width: 140,
                            height: 180,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.green[300]!,
                                  Colors.green[400]!,
                                  Colors.green[500]!,
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(70),
                                topRight: Radius.circular(70),
                                bottomLeft: Radius.circular(60),
                                bottomRight: Radius.circular(60),
                              ),
                            ),
                          ),
                          // Dots pattern
                          ...List.generate(15, (index) {
                            final random = index * 37;
                            return Positioned(
                              top: 30 + (random % 100).toDouble(),
                              left: 20 + (random % 80).toDouble(),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green[700]!.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Do an activity to help me grow',
                      style: GoogleFonts.poppins(
                        fontSize: 16 * AppTheme.fontSizeScale,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Activity buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Pre-Quiz button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          preQuizCompleted
                              ? null
                              : () {
                                _startPreQuiz(context);
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: preQuizCompleted ? greyColor : primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: preQuizCompleted ? 0 : 3,
                      ),
                      child: Text(
                        'PRE-QUIZ',
                        style: GoogleFonts.poppins(
                          fontSize: 18 * AppTheme.fontSizeScale,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Reading button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          !preQuizCompleted || readingCompleted
                              ? null
                              : () {
                                _startReading(context);
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (!preQuizCompleted || readingCompleted)
                                ? greyColor
                                : primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation:
                            (!preQuizCompleted || readingCompleted) ? 0 : 3,
                      ),
                      child: Text(
                        'READING',
                        style: GoogleFonts.poppins(
                          fontSize: 18 * AppTheme.fontSizeScale,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Post-Quiz button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          !readingCompleted || postQuizCompleted
                              ? null
                              : () {
                                _startPostQuiz(context);
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (!readingCompleted || postQuizCompleted)
                                ? greyColor
                                : primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation:
                            (!readingCompleted || postQuizCompleted) ? 0 : 3,
                      ),
                      child: Text(
                        'POST-QUIZ',
                        style: GoogleFonts.poppins(
                          fontSize: 18 * AppTheme.fontSizeScale,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startPreQuiz(BuildContext context) {
    final singleQ = Question.singleAnswer(
      id: 'q1',
      questionText: 'What color is the sky?',
      options: ['Red', 'Blue', 'Green', 'Yellow'],
      correctAnswerIndex: 1,
      explanation: 'The Sky is blue',
    );
    final multipleQ = Question.multipleAnswer(
      id: 'q3',
      text:
          "At your school, there is a security guard named Quinn. You have never met or talked to Quinn, but some of your school mates have.",
      questionText: 'What social tag(s) apply to Quinn?',
      options: ['Acquaintance', 'Community Helper', 'Stranger', 'Work Peer'],
      correctAnswerIndices: [1, 2],
      explanation: 'Quinn serves the community, but don\'t know him',
    );
    final questionSet = QuestionSet(
      id: "qset0",
      title: "Social Media Norms Pre-Quiz",
      description: "Test your knowledge before the lesson",
      activityType: ActivityType.preQuiz,
      subject: "Social Media Norms",
      questions: [singleQ, multipleQ],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreQuizScreen(questionSet: questionSet),
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
    final singleQ2 = Question.singleAnswer(
      id: 'q2',
      questionText: 'What season are oranges ripe?',
      options: ['Spring', 'Summer', 'Fall', 'Winter'],
      correctAnswerIndex: 3,
      explanation: 'Oranges taste best during the winter',
    );
    final questionSet2 = QuestionSet(
      id: "qset1",
      title: "Social Media Norms Post-Quiz",
      description: "Test your knowledge after the lesson",
      activityType: ActivityType.postQuiz,
      subject: "Social Media Norms",
      questions: [singleQ2],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostQuizScreen(questionSet: questionSet2),
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
              'You have completed the Social Media Norms activity!',
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
