import 'package:flutter/material.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/themes/app_theme.dart';

class PostQuizSummary extends StatefulWidget {
  final QuestionSet questionSet;
  final List<List<int>> userAnswers;

  const PostQuizSummary({
    Key? key,
    required this.questionSet,
    required this.userAnswers,
  }) : super(key: key);

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

  List<int> getMissedQuestions() {
    List<int> missedQuestions = [];
    for (int i = 0; i < widget.questionSet.questions.length; i++) {
      if (!_isAnswerCorrect(i)) {
        missedQuestions.add(i);
      }
    }
    return missedQuestions;
  }

  Widget buildQuestionCard(int questionIndex, bool isMissed) {
    final List<List<int>> userAnswers = widget.userAnswers;
    QuestionSet questionSet = widget.questionSet;

    final question = widget.questionSet.questions[questionIndex];
    final userAnswer = widget.userAnswers[questionIndex];

    ThemeData theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${questionIndex + 1}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(question.questionText, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Answer:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userAnswer.isEmpty
                        ? 'No answer provided'
                        : userAnswer
                            .map((index) => question.options[index])
                            .join(', '),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correct Answer:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      question.correctAnswerIndices
                          .map((index) => question.options[index])
                          .join(', '),
                    ),
                  ],
                ),
              ),
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
            'Quiz Summary',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
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
            'View Question Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
          children: [
            ...List.generate(
              widget.questionSet.questions.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  'Question ${index + 1}: ${_isAnswerCorrect(index) ? 'Correct' : 'Incorrect'}',
                  style: TextStyle(
                    color: _isAnswerCorrect(index) ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
