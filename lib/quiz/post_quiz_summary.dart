import 'package:flutter/material.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/themes/app_theme.dart';

class PostQuizSummary extends StatefulWidget {
  const PostQuizSummary({
    super.key,
    required this.questionSet,
    required this.userAnswers,
  });

  final QuestionSet questionSet;
  final List<List<int>> userAnswers;

  @override
  State<PostQuizSummary> createState() => _PostQuizSummaryState();
}

class _PostQuizSummaryState extends State<PostQuizSummary> {
  bool _isExpanded = false;

  List<int> getMissedQuestions() {
    final List<List<int>> userAnswers = widget.userAnswers;
    QuestionSet questionSet = widget.questionSet;

    List<int> missedQuestions = [];
    for (int i = 0; i < userAnswers.length; i++) {
      final question = questionSet.questions[i];
      if (userAnswers[i].isEmpty || !question.isCorrect(userAnswers[i])) {
        missedQuestions.add(i);
      }
    }
    return missedQuestions;
  }

  List<int> getCorrectQuestions() {
    final List<List<int>> userAnswers = widget.userAnswers;
    QuestionSet questionSet = widget.questionSet;

    List<int> correctQuestions = [];
    for (int i = 0; i < userAnswers.length; i++) {
      final question = questionSet.questions[i];
      if (userAnswers[i].isNotEmpty && question.isCorrect(userAnswers[i])) {
        correctQuestions.add(i);
      }
    }
    return correctQuestions;
  }

  Widget buildQuestionCard(int questionIndex, bool isMissed) {
    final question = widget.questionSet.questions[questionIndex];
    final userAnswer = widget.userAnswers[questionIndex];

    //TODO: Should I be using theme.notifier?
    ThemeData theme = Theme.of(context);

    // Format user answers for display
    String getUserAnswerText() {
      if (userAnswer.isEmpty) return 'Not answered';
      if (userAnswer.length == 1) {
        return question.options[userAnswer.first];
      } else {
        return userAnswer.map((index) => question.options[index]).join(', ');
      }
    }

    // Format correct answers for display
    String getCorrectAnswerText() {
      if (question.correctAnswerIndices.length == 1) {
        return question.options[question.correctAnswerIndices.first];
      } else {
        return question.correctAnswerIndices
            .map((index) => question.options[index])
            .join(', ');
      }
    }

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 20, horizontal: 0),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Question ${questionIndex + 1}",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isMissed ? theme.colorScheme.red : theme.colorScheme.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(question.questionText, style: theme.textTheme.bodyMedium),
              SizedBox(height: 12),
              if (isMissed) ...[
                Text(
                  "Your Answer: ${getUserAnswerText()}",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.red),
                ),
                SizedBox(height: 5),
              ],
              Text(
                "Correct Answer: ${getCorrectAnswerText()}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 5),
              if (question.explanation.isNotEmpty) ...[
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Explanation:",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        question.explanation,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
          ), // 16 to match the expansion tile of correct questions
          child: Text(
            "Missed Questions", // (${getMissedQuestions().length})",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.red,
            ),
          ),
        ),
        SizedBox(height: 12),

        // Always visible missed questions
        if (getMissedQuestions().isEmpty)
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.green, size: 24),
                  SizedBox(width: 12),
                  Text(
                    "Nice work! No missed questions.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          )
        else
          ...getMissedQuestions().map(
            (index) => buildQuestionCard(index, true),
          ),

        SizedBox(height: 24),

        // Expandable correct questions
        ExpansionTile(
          title: Text(
            "Correct Questions", // (${getCorrectQuestions().length})",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
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
          shape: Border(),
          collapsedShape: Border(),

          children:
              getCorrectQuestions().isEmpty
                  ? [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Text(
                        "No correct answers yet. Keep practicing!",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ]
                  : getCorrectQuestions()
                      .map((index) => buildQuestionCard(index, false))
                      .toList(),
        ),
      ],
    );
  }
}
