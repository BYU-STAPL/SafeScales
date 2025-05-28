import 'package:flutter/material.dart';
import 'package:safe_scales/question/question.dart';

class QuestionWidget extends StatelessWidget {
  final Question question;
  final List<int> selectedAnswers;
  final Function(List<int>) onAnswerChanged;
  final bool showCorrectAnswer;
  final bool showExplanation;
  final bool isDisabled;

  const QuestionWidget({
    Key? key,
    required this.question,
    required this.selectedAnswers,
    required this.onAnswerChanged,
    required this.showCorrectAnswer,
    this.showExplanation = false,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        if (question.isMultipleChoice) ...[
          SizedBox(height: 8),
          Text(
            'Select all that apply:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],

        SizedBox(height: 16),

        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = selectedAnswers.contains(index);

          return GestureDetector(
            onTap: isDisabled ? null : () {
              List<int> newAnswers = List.from(selectedAnswers);

              if (question.isMultipleChoice) {
                if (isSelected) {
                  newAnswers.remove(index);
                } else {
                  newAnswers.add(index);
                }
              } else {
                newAnswers = [index];
              }

              onAnswerChanged(newAnswers);
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? Colors.blue.withOpacity(0.1)
                    : isDisabled
                    ? Colors.grey.withOpacity(0.1)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    question.isMultipleChoice
                        ? (isSelected ? Icons.check_box : Icons.check_box_outline_blank)
                        : (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text(option)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}