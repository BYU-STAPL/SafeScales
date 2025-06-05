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
      ),
      body: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: Column(
                children: [
                  SizedBox(height: 15),

                  Text(
                    'Good job completing this quiz!', // ${questionSet.title}!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),

                  SizedBox(height: 15),

                  Container(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Quiz Score'),
                          Text(
                            '$score%',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: readinessColor,
                            ),
                          ),
                          Text(
                            readinessLevel,
                            style: TextStyle(fontSize: 24, color: readinessColor),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '$correctAnswers out of $totalQuestions questions correct',
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  PostQuizSummary(questionSet: widget.questionSet, userAnswers: widget.userAnswers),

                  SizedBox(height: 50),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {

                        // Navigate to actions screen and wait for result
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostQuizActionsScreen(
                              score: score,
                              passingScore: widget.questionSet.passingScore,
                            ),
                          ),
                        );

                        // If user chose to return to lesson, handle the navigation here
                        if (result == true) {
                          // Pop PostQuizScreen and return to lesson with completion status
                          Navigator.pop(context, true);
                        }
                        // TODO: when you later pop from actions you go to home instead of the lesson
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => PostQuizActionsScreen(
                        //       score: score,
                        //       passingScore: widget.questionSet.passingScore,
                        //     ),
                        //   ),
                        // ).then((shouldReturnToLesson) {
                        //   if (shouldReturnToLesson == true) {
                        //     // Pop back through the entire quiz flow
                        //     Navigator.pop(context); // Pop to PostQuizScreen
                        //     Navigator.pop(context, true); // Pop back to lesson with completion status
                        //   }
                        // });


                        // Navigator.pop(context); // Pop to PostQuizScreen
                        // Navigator.pop(
                        //   context,
                        //   true,
                        // ); // Pop back to SocialMediaNormsPage with completion status
                      },
                      child: Text(
                        'next'.toUpperCase(),
                        style: TextStyle(
                          fontSize: theme.textTheme.bodyMedium?.fontSize,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                ],
              ),
            ),
          ),
      );
  }
}
