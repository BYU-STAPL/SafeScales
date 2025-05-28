import 'package:flutter/material.dart';
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
    String readinessLevel = score >= 80 ? 'Ready' : score >= 60 ? 'Partially Ready' : 'Needs Practice';
    Color readinessColor = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text('Assessment Results'),
        // backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '$score%',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: readinessColor),
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
            SizedBox(height: 16),
            Text(
              score >= 80
                  ? 'Great! You\'re ready to start the course.'
                  : score >= 60
                  ? 'You have some knowledge. Consider reviewing key concepts.'
                  : 'We recommend starting with practice exercises.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}