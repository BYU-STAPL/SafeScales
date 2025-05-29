import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/home.dart';
import 'package:safe_scales/question/question.dart';

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

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {

    final QuestionSet questionSet = widget.questionSet;
    final int passingScore = widget.passingScore;
    final int score = widget.score;
    final int correctAnswers = widget.correctAnswers;
    final int totalQuestions = widget.totalQuestions;
    final List<List<int>> userAnswers = widget.userAnswers;

    String readinessLevel = score >= passingScore ? 'Passed' : score >= 50 ? 'Needs Retake' : 'Needs to Re-read';
    Color readinessColor = score >= passingScore ? Colors.green : score < passingScore ? Colors.orange : Colors.red;

    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Results'),
        // backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Column(
              children: [

                SizedBox(height: 20),

                Text(
                  'Good job completing the ${questionSet.title}!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),

                SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Quiz Score'),
                        Text(
                          '$score%',
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: readinessColor),
                        ),
                        Text(
                          readinessLevel,
                          style: TextStyle(fontSize: 24, color: readinessColor),
                        ),
                        SizedBox(height: 16),
                        Text('$correctAnswers out of $totalQuestions questions correct'),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                ExpansionTile(
                  title: Text("Correct Questions"),
                  trailing: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  onExpansionChanged: (bool expanded) {
                    setState(() {
                      _isExpanded = expanded;
                    });
                  },
                  children: [
                    Text("Filler"),
                    Text("Filler"),

                  ],
                ),

                // Text(
                //   'Your dragon is fully grown!',
                //   textAlign: TextAlign.center,
                //   style: theme.textTheme.bodyLarge,
                // ),
                // SizedBox(height: 25),
                //
                // // TODO: Replace later with dragon hatching
                // Image.asset("assets/images/other/QuestionMark.png"),
                //
                // SizedBox(height: 25),
                // Text(
                //   'Now you can play with your dragon by going to the dragon screen',
                //   textAlign: TextAlign.center,
                //   style: theme.textTheme.bodyMedium,
                // ),
                //
                // TextButton.icon(
                //   onPressed: (){
                //     // Go to Dragon Page
                //     Navigator.pushAndRemoveUntil(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => HomePage(initialIndex: 1), // Index of desired tab
                //       ),
                //           (route) => false, // Remove all previous routes
                //     );
                //   },
                //   icon: FaIcon(FontAwesomeIcons.dragon),
                //   label: Text(
                //     'Dragon',
                //     style: theme.textTheme.bodyMedium?.copyWith(
                //       color: theme.colorScheme.primary,
                //     ),
                //   ),
                // ),

                SizedBox(height: 25),

                //TODO: How can I dock this at the bottom of screen so it's not affected by scrolling?
                // Or maybe this works bc then the user is required to scroll and review answers
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
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
        )
    );
  }
}