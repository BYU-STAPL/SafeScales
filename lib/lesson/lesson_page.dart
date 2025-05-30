import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/quiz/post_quiz_screen.dart';
import 'package:safe_scales/services/quiz_service.dart';

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

  final QuizService _quizService = QuizService();
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
  }) {
    final Color cardBg = Theme.of(context).colorScheme.surface;
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.arrow_forward_ios,
              color: textColor.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _startQuiz(QuestionSet quiz) {
    print('Starting quiz: ${quiz.id}');
    print('Quiz type: ${quiz.activityType}');

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
            print('Marking pre-quiz as completed');
            preQuizCompleted = true;
          } else if (quiz.activityType == ActivityType.postQuiz) {
            print('Marking post-quiz as completed');
            postQuizCompleted = true;
          }
        });
      }
    });
  }

  Widget _buildReadingCard() {
    final Color cardBg = Theme.of(context).colorScheme.surface;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    Text(
                      'Reading Activity',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
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
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: textColor.withOpacity(0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Coming soon!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textColor.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
