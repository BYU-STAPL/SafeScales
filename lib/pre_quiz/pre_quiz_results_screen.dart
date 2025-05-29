import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/home.dart';
import 'package:safe_scales/question/question.dart';

class PreQuizResultScreen extends StatelessWidget {
  final QuestionSet questionSet;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final List<List<int>> userAnswers;

  const PreQuizResultScreen({
    Key? key,
    required this.questionSet,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.userAnswers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // String readinessLevel = score >= 80 ? 'Ready' : score >= 60 ? 'Partially Ready' : 'Needs Practice';
    // Color readinessColor = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;

    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Results'),
        // backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: Column(
          children: [
            // Card(
            //   child: Padding(
            //     padding: EdgeInsets.all(16),
            //     child: Column(
            //       children: [
            //         Text(
            //           '$score%',
            //           style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: readinessColor),
            //         ),
            //         Text(
            //           readinessLevel,
            //           style: TextStyle(fontSize: 24, color: readinessColor),
            //         ),
            //         SizedBox(height: 16),
            //         Text('$correctAnswers out of $totalQuestions questions correct'),
            //       ],
            //     ),
            //   ),
            // ),
            SizedBox(height: 20),
            Text(
              'Good job completing the ${questionSet.title}!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 50),
            Text(
              'Your dragon has hatched!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 25),

            // TODO: Replace later with dragon hatching
            Image.asset("assets/images/other/QuestionMark.png"),

            SizedBox(height: 25),
            Text(
              'You can give your new dragon a name on the Dragon screen.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),

            TextButton.icon(
              onPressed: () {
                // Go to Dragon Page
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => HomePage(
                          initialIndex: 1,
                          isDarkMode:
                              Theme.of(context).brightness == Brightness.dark,
                          onDarkModeChanged:
                              (value) {}, // This will be handled by the parent
                          fontSize: 1.0, // Default font size
                          onFontSizeChanged:
                              (value) {}, // This will be handled by the parent
                        ),
                  ),
                  (route) => false,
                );
              },
              icon: FaIcon(FontAwesomeIcons.dragon),
              label: Text(
                'Dragon',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Pop to PreQuizScreen
                  Navigator.pop(
                    context,
                    true,
                  ); // Pop back to SocialMediaNormsPage with completion status
                },
                child: Text(
                  'return to lesson'.toUpperCase(),
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
    );
  }
}
