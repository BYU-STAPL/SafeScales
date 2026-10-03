import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/providers/dragon_decoration_provider.dart';
import 'package:safe_scales/providers/dragon_provider.dart';
import 'package:safe_scales/ui/screens/dragon_decoration/dragon_decoration_screen.dart';
import 'package:safe_scales/ui/screens/post_quiz/post_quiz_actions_screen.dart';
import 'package:safe_scales/ui/widgets/post_quiz_summary.dart';
import 'package:safe_scales/ui/screens/post_quiz/post_quiz_screen.dart';
import 'package:safe_scales/ui/screens/reading/reading_activity_screen.dart';
import 'package:safe_scales/themes/app_theme.dart';

class PostQuizResultScreen extends StatefulWidget {
  const PostQuizResultScreen({
    super.key,
    required this.moduleId,
    required this.questionSet,
    required this.passingScore,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.userAnswers,
    // required this.topic,
  });

  final String moduleId;
  final QuestionSet questionSet;
  final int passingScore;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final List<List<int>> userAnswers;
  // final String topic;

  @override
  State<PostQuizResultScreen> createState() => _PostQuizResultScreenState();
}

class _PostQuizResultScreenState extends State<PostQuizResultScreen> {
  Future<void> _handleQuizAction(QuizAction action) async {
    switch (action) {
      case QuizAction.retake:
        await _retakeQuiz();
        break;
      case QuizAction.reread:
        await _reReadLesson();
        break;
      case QuizAction.returnToLesson:
        Navigator.pop(context, true);
        break;
      case QuizAction.playWithDragon:
        await _playWithDragon();
        break;
    }
  }

  Future<void> _playWithDragon() async {
    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
    await dragonProvider.updateDragonPhases(widget.moduleId);

    if (!mounted) return;

    final dragon = dragonProvider.getDragonByModuleId(widget.moduleId);
    if (dragon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find this lesson dragon.')),
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder:
            (context) => MultiProvider(
              providers: [
                ChangeNotifierProvider<DragonDecorationProvider>(
                  create: (_) => DragonDecorationProvider(),
                ),
              ],
              child: DragonDressUpPage(
                dragonId: dragon.id,
                currentPhase: 'final',
              ),
            ),
      ),
    );
  }

  Future<void> _retakeQuiz() async {
    // Navigate back to quiz screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PostQuizScreen(
              moduleId: widget.moduleId,
              questionSet: widget.questionSet,
            ),
      ),
    );

    // If quiz was completed, pop back to lesson
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _reReadLesson() async {
    // Navigate back to lesson page for re-reading
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingActivityScreen(moduleId: widget.moduleId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final QuestionSet questionSet = widget.questionSet;
    final int passingScore = widget.passingScore;
    final int score = widget.score;
    final int correctAnswers = widget.correctAnswers;
    final int totalQuestions = widget.totalQuestions;
    // final List<List<int>> userAnswers = widget.userAnswers;

    ThemeData theme = Theme.of(context);

    String readinessLevel =
        score >= passingScore
            ? 'Passed'
            : score >= 50
            ? 'Needs Retake'
            : 'Needs to Re-read';
    Color readinessColor =
        score >= passingScore
            ? theme.colorScheme.green
            : score < passingScore
            ? theme.colorScheme.orange
            : theme.colorScheme.red;

    return Scaffold(
      appBar: AppBar(
        title: Text('Results'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Score Card
                Container(
                  margin: EdgeInsets.only(top: 20),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        readinessColor.withValues(alpha: 0.1),
                        readinessColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: readinessColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Quiz Score',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '$correctAnswers out of $totalQuestions',
                        style: TextStyle(
                          fontSize: 48 * AppTheme.fontSizeScale,
                          fontWeight: FontWeight.bold,
                          color: readinessColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: readinessColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          readinessLevel,
                          style: TextStyle(
                            fontSize: 18 * AppTheme.fontSizeScale,
                            fontWeight: FontWeight.w600,
                            color: readinessColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Next Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final result = await navigator.push(
                        MaterialPageRoute(
                          builder:
                              (context) => PostQuizActionsScreen(
                                moduleId: widget.moduleId,
                                score: score,
                                correctAnswers: correctAnswers,
                                totalQuestions: totalQuestions,
                                passingScore: widget.questionSet.passingScore,
                                handleAction: _handleQuizAction,
                              ),
                        ),
                      );

                      if (!mounted) return;

                      // Handle the returned action
                      if (result is QuizAction) {
                        await _handleQuizAction(result);
                        if (!mounted) return;
                      } else if (result == true) {
                        navigator.pop(true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30),

                PostQuizSummary(
                  questionSet: widget.questionSet,
                  userAnswers: widget.userAnswers,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
