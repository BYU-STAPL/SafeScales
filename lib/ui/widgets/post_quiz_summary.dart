import 'package:flutter/material.dart';
import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/themes/app_theme.dart';

class PostQuizSummary extends StatefulWidget {
  final QuestionSet questionSet;
  final List<List<int>> userAnswers;

  const PostQuizSummary({
    super.key,
    required this.questionSet,
    required this.userAnswers,
  });

  @override
  State<PostQuizSummary> createState() => _PostQuizSummaryState();
}

class _PostQuizSummaryState extends State<PostQuizSummary> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
  }

  bool _isAnswerCorrect(int questionIndex) {
    final List<List<int>> userAnswers = widget.userAnswers;
    QuestionSet questionSet = widget.questionSet;

    final question = questionSet.questions[questionIndex];
    final userAnswer = userAnswers[questionIndex];

    if (userAnswer.length != question.correctAnswerIndices.length) return false;

    final sortedUser = List<int>.from(userAnswer)..sort();
    final sortedCorrect = List<int>.from(question.correctAnswerIndices)..sort();

    for (int i = 0; i < sortedUser.length; i++) {
      if (sortedUser[i] != sortedCorrect[i]) return false;
    }
    return true;
  }

  List<int> getCorrectQuestions() {
    final int userAnswersLength = widget.userAnswers.length;

    List<int> correctQuestions = [];

    for (int i = 0; i < userAnswersLength; i++) {
      if (_isAnswerCorrect(i)) {
        correctQuestions.add(i);
      }
    }
    return correctQuestions;
  }

  List<int> getMissedQuestions() {
    List<int> missedQuestions = [];
    for (int i = 0; i < widget.questionSet.questions.length; i++) {
      if (!_isAnswerCorrect(i)) {
        missedQuestions.add(i);
      }
    }
    return missedQuestions;
  }

  String getUserAnswerText(Question question, List<int> userAnswer) {
    if (userAnswer.isEmpty) {
      return 'Not answered';
    }
    else {
      return userAnswer
          .map((index) => question.options[index])
          .join(', ');
    }
  }

  Widget buildQuestionCard(int questionIndex, bool isMissed) {
    // final List<List<int>> userAnswers = widget.userAnswers;
    // QuestionSet questionSet = widget.questionSet;

    final question = widget.questionSet.questions[questionIndex];
    final userAnswer = widget.userAnswers[questionIndex];

    ThemeData theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${questionIndex + 1}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 15 * AppTheme.fontSizeScale,
                )
              ),
              const SizedBox(height: 10),
              Text(
                  question.questionText,
                  style: theme.textTheme.bodyMedium
              ),
              const SizedBox(height: 10),

              if (isMissed) ... [
                Text(
                  'Your Answer: ${getUserAnswerText(question, userAnswer)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.red
                  ),
                ),
                const SizedBox(height: 5),
              ],
              Text(
                'Correct Answer: ${question.correctAnswerIndices.map((index) => question.options[index]).join(', ')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.green
                ),
              ),

              const SizedBox(height: 5),

              if (question.explanation.isNotEmpty) ... [
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Explanation:",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 15 * AppTheme.fontSizeScale,
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
              ]
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Missed Questions',
            style: theme.textTheme.headlineSmall,
          ),
        ),
        SizedBox(height: 12),

        // Always visible missed questions
        if (getMissedQuestions().isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.green,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  "Nice work! No missed questions.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.green,
                  ),
                ),
              ],
            ),
          )
        else
          ...getMissedQuestions().map(
            (index) => buildQuestionCard(index, true),
          ),

        SizedBox(height: 20),

        // Expandable correct questions
        ExpansionTile(
          title: Text(
            'Correct Questions',
            style: theme.textTheme.headlineSmall,
          ),
          trailing: Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: theme.colorScheme.primary,
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          shape: Border(),
          collapsedShape: Border(),

          children: getCorrectQuestions().isEmpty ? [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                "No correct answers yet. Keep practicing!",
                style: theme.textTheme.labelMedium
              ),
            ),
          ]
              : getCorrectQuestions().map((index) => buildQuestionCard(index, false)).toList(),



          // children: [
          //   ...List.generate(
          //     widget.questionSet.questions.length,
          //     (index) => Padding(
          //       padding: const EdgeInsets.symmetric(
          //         horizontal: 20,
          //         vertical: 10,
          //       ),
          //       child: Text(
          //         'Question ${index + 1}: ${_isAnswerCorrect(index) ? 'Correct' : 'Incorrect'}',
          //         style: TextStyle(
          //           color: _isAnswerCorrect(index) ? Colors.green : Colors.red,
          //         ),
          //       ),
          //     ),
          //   ),
          // ],
        ),

        SizedBox(height: 30,)
      ],
    );
  }
}
