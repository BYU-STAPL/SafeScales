import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/quiz/post_quiz_screen.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/reading/reading_activity_screen.dart';

class LessonPage extends StatefulWidget {
  final String topic;

  const LessonPage({super.key, required this.topic});

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
  QuestionSet? _preQuiz;
  QuestionSet? _postQuiz;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      // Get pre-quiz for the specified topic
      final preQuiz = await _quizService.getQuizByTopicAndActivityType(
        topic: widget.topic,
        activityType: 'preQuiz',
      );

      // Get post-quiz for the specified topic
      final postQuiz = await _quizService.getQuizByTopicAndActivityType(
        topic: widget.topic,
        activityType: 'postQuiz',
      );

      // Get user's quiz progress
      final user = _userState.currentUser;
      if (user != null) {
        final response =
            await _quizService.supabase
                .from('Users')
                .select('quizzes')
                .eq('id', user.id)
                .single();

        if (response['quizzes'] != null) {
          final quizzesData = Map<String, dynamic>.from(response['quizzes']);
          if (preQuiz != null && quizzesData.containsKey(preQuiz.id)) {
            final preQuizData = quizzesData[preQuiz.id];
            setState(() {
              preQuizCompleted = true;
              preQuizScore = preQuizData['score'];
            });
          }
          if (postQuiz != null && quizzesData.containsKey(postQuiz.id)) {
            final postQuizData = quizzesData[postQuiz.id];
            setState(() {
              postQuizCompleted = true;
              postQuizScore = postQuizData['score'];
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
      print('Error loading quizzes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.topic), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_preQuiz != null) ...[
                      _buildQuizCard(
                        title: 'Pre-Quiz',
                        description: 'Test your knowledge before starting',
                        onTap: () => _startQuiz(_preQuiz!),
                        icon: Icons.quiz,
                        color: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(context).colorScheme.secondary,
                        isCompleted: postQuizCompleted,
                        score: postQuizScore,
                      ),
                    ],
                  ],
                ),
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
    return Container(
      decoration: BoxDecoration(
        color:
            isCompleted
                ? Colors.green.withOpacity(0.1)
                : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green : color.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  backgroundColor: color.withOpacity(0.1),
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
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (isCompleted) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            if (score != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${score.toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadingCard() {
    final Color cardBg = Theme.of(context).colorScheme.surface;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: readingCompleted ? Colors.green.withOpacity(0.1) : cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: readingCompleted ? Colors.green : primary.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                                ReadingActivityScreen(topic: widget.topic),
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
                          'Learn about ${widget.topic}',
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
                    Icon(
                      Icons.lock,
                      size: 16,
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
    print('Starting quiz: ${quiz.id}');
    print('Quiz type: ${quiz.activityType}');

    // Check if post-quiz is being attempted before reading is completed
    if (quiz.activityType == ActivityType.postQuiz && !readingCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the reading activity first'),
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
      print('Quiz completed with status: $completed');
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
}
