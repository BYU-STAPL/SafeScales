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

    ThemeData theme = Theme.of(context);


    Text instructionText = Text(
      'Choose one option:',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontStyle: FontStyle.italic,
        color: theme.colorScheme.outline,
      ),
    );

    if (question.isMultipleChoice) {
      instructionText = Text(
        'Select all that apply:',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.outline,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.text != null) ... [

          SizedBox(height: 15,),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              border: Border.all(
                color: Colors.black,
                width: 3,
                style: BorderStyle.solid,
              )
            ),
            child: Padding (
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Text(
                question.text!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),

          SizedBox(height: 10,),

        ],

        Spacer(),

        Text(
          question.questionText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold
          ),
        ),

        SizedBox(height: 10,),

        instructionText,

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
              margin: EdgeInsets.symmetric(vertical: 10),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : isDisabled
                    ? theme.colorScheme.surfaceDim
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    question.isMultipleChoice
                        ? (isSelected ? Icons.check_box : Icons.check_box_outline_blank_rounded)
                        : (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                    color: theme.colorScheme.primary, //isSelected ? theme.colorScheme.primary : theme.colorScheme.shadow,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text(
                        option,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                      ),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}