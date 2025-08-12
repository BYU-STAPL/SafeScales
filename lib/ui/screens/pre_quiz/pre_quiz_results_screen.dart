import 'package:flutter/material.dart';
import 'package:safe_scales/models/question.dart';

import '../../widgets/dragon_image_widget.dart';

class PreQuizResultScreen extends StatelessWidget {
  final String moduleId;
  final QuestionSet questionSet;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final List<List<int>> userAnswers;

  const PreQuizResultScreen({
    super.key,
    required this.moduleId,
    required this.questionSet,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Complete'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 25),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Great job completing the quiz!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 30),

              Text(
                'Your new dragon egg hatched!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),

              SizedBox(height: 30),

              DragonImageWidget(moduleId: moduleId, size: 300, phase: 'stage1'),

              SizedBox(height: 30),

              Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                  child: Text(
                    'Return to lesson'.toUpperCase(),
                    style: TextStyle(
                      fontSize: theme.textTheme.bodyMedium?.fontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
