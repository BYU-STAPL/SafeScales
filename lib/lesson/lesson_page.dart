import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/quiz/post_quiz_screen.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/dragon_service.dart';
import 'package:safe_scales/reading/reading_activity_screen.dart';

import '../themes/app_theme.dart';

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
  final DragonService _dragonService = DragonService(QuizService().supabase);
  QuestionSet? _preQuiz;
  QuestionSet? _postQuiz;
  bool _isLoading = true;
  Map<String, dynamic>? _dragonData;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
    _loadDragonImages();
  }

  Future<void> _loadDragonImages() async {
    try {
      print('Loading dragon for topic: ${widget.topic}');
      await _dragonService.initialize();

      // Get the index of the current topic
      final allQuizzes = await _quizService.getAllQuizzes();
      final topics =
          allQuizzes.map((q) => q['topic'] as String).toSet().toList();
      final topicIndex = topics.indexOf(widget.topic);

      if (topicIndex != -1) {
        final dragonData = await _dragonService.getDragonImagesForModule(
          topicIndex,
        );
        if (mounted) {
          setState(() {
            _dragonData = dragonData;
            print(
              'Loaded dragon data for ${widget.topic}: ${dragonData['id']}',
            );
          });
        }
      }
    } catch (e) {
      print('Error loading dragon images: $e');
    }
  }

  Future<void> _loadQuizzes() async {
    try {
      print('Loading quizzes for topic: ${widget.topic}');

      // Get pre-quiz for the specified topic
      final preQuiz = await _quizService.getQuizByTopicAndActivityType(
        topic: widget.topic,
        activityType: 'preQuiz',
      );
      print('Pre-quiz loaded: ${preQuiz?.id}');

      // Get post-quiz for the specified topic
      final postQuiz = await _quizService.getQuizByTopicAndActivityType(
        topic: widget.topic,
        activityType: 'postQuiz',
      );
      print('Post-quiz loaded: ${postQuiz?.id}');

      // Get user's quiz progress
      final user = _userState.currentUser;
      if (user != null) {
        print('Loading quiz progress for user: ${user.id}');
        final response =
            await _quizService.supabase
                .from('Users')
                .select('quizzes')
                .eq('id', user.id)
                .single();

        print('Raw quiz data from database: ${response['quizzes']}');

        if (response['quizzes'] != null) {
          final quizzesData = Map<String, dynamic>.from(response['quizzes']);
          print('Parsed quizzes data: $quizzesData');

          if (preQuiz != null && quizzesData.containsKey(preQuiz.id)) {
            final preQuizData = quizzesData[preQuiz.id];
            print('Pre-quiz data found: $preQuizData');
            setState(() {
              preQuizCompleted = true;
              preQuizScore = preQuizData['score'].toDouble();
            });
          } else {
            print('No pre-quiz data found for quiz ID: ${preQuiz?.id}');
          }

          if (postQuiz != null && quizzesData.containsKey(postQuiz.id)) {
            final postQuizData = quizzesData[postQuiz.id];
            print('Post-quiz data found: $postQuizData');
            setState(() {
              postQuizCompleted = true;
              postQuizScore = postQuizData['score'].toDouble();
            });
          } else {
            print('No post-quiz data found for quiz ID: ${postQuiz?.id}');
          }
        } else {
          print('No quiz data found in user record');
        }
      } else {
        print('No user logged in');
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
      appBar: AppBar(title: Text(widget.topic), centerTitle: true),
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
                ? green.withValues(alpha: 0.1)//secondary.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? green : color.withValues(alpha: 0.5),
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
                              color: green,
                              size: 16,
                            ),
                            if (score != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${score.toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: green,
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
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
        color: readingCompleted ? green.withValues(alpha: 0.1) : cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: readingCompleted ? green : primary.withValues(alpha: 0.5),
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

  Widget _getDragonPhaseIcon(double progress) {
    String imageUrl = _dragonData?['egg'] ?? 'assets/images/other/egg.png';

    if (progress >= 80) {
      imageUrl = _dragonData?['final'] ?? 'assets/images/other/adult.png';
    } else if (progress >= 50) {
      imageUrl = _dragonData?['stage2'] ?? 'assets/images/other/teen.png';
    } else if (progress >= 30) {
      imageUrl = _dragonData?['stage1'] ?? 'assets/images/other/young.png';
    }

    print('Using dragon image for topic ${widget.topic}: $imageUrl');

    // Check if the image URL is a network URL or a local asset
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 240,
        height: 240,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading dragon image for topic ${widget.topic}: $error');
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
