import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/main_navigation.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/quiz/post_quiz_actions_screen.dart';
import 'package:safe_scales/quiz/post_quiz_summary.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/themes/theme_notifier.dart';
import 'package:safe_scales/themes/theme_provider.dart';

class PostQuizResultScreen extends StatefulWidget {
  const PostQuizResultScreen({
    Key? key,
    required this.questionSet,
    required this.passingScore,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.userAnswers,
  }) : super(key: key);

  final QuestionSet questionSet;
  final int passingScore;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final List<List<int>> userAnswers;

  @override
  State<PostQuizResultScreen> createState() => _PostQuizResultScreenState();
}

class _PostQuizResultScreenState extends State<PostQuizResultScreen> {
  @override
  Widget build(BuildContext context) {
    final QuestionSet questionSet = widget.questionSet;
    final int passingScore = widget.passingScore;
    final int score = widget.score;
    final int correctAnswers = widget.correctAnswers;
    final int totalQuestions = widget.totalQuestions;
    final List<List<int>> userAnswers = widget.userAnswers;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score Card
                Container(
                  margin: EdgeInsets.only(top: 20),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        readinessColor.withOpacity(0.1),
                        readinessColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: readinessColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Quiz Score',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '$score%',
                        style: TextStyle(
                          fontSize: 48,
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
                          color: readinessColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          readinessLevel,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: readinessColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '$correctAnswers out of $totalQuestions questions correct',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => PostQuizActionsScreen(
                                score: score,
                                passingScore: widget.questionSet.passingScore,
                              ),
                        ),
                      );

                      if (result == true) {
                        Navigator.pop(context, true);
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

                SizedBox(height: 32),

                // Questions Summary
                Text(
                  'Question Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
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
