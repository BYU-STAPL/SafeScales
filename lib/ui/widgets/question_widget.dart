import 'package:flutter/material.dart';
import 'package:safe_scales/models/question.dart';

class QuestionWidget extends StatefulWidget {
  final Question question;
  final List<int> selectedAnswers;
  final Function(List<int>) onAnswerChanged;
  final bool showCorrectAnswer;
  final bool showExplanation;
  final bool isResponseLocked;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.selectedAnswers,
    required this.onAnswerChanged,
    required this.showCorrectAnswer,
    required this.isResponseLocked,
    this.showExplanation = false,
  });

  @override
  _QuestionWidgetState createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    Question question = widget.question;
    // List<int> selectedAnswers = widget.selectedAnswers;

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
            // if (question.text != null) ...[
            //   SizedBox(height: 15),
            //   Container(
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.all(Radius.circular(15)),
            //       border: Border.all(
            //         color: Colors.black,
            //         width: 3,
            //         style: BorderStyle.solid,
            //       ),
            //     ),
            //     child: Padding(
            //       padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            //       child: Text(
            //         question.text!,
            //         style: theme.textTheme.bodyMedium,
            //       ),
            //     ),
            //   ),
            //
            //   SizedBox(height: 20),
            // ],

            buildSmartScrollableQuestionText(),

            Spacer(),

            Text(
              question.questionText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 5,),

            instructionText,

            buildConstrainedScrollableOptions(),

          ],
        );
    //   ),
    // );
  }

  List<Widget> buildQuestionOptions(
      List<int> selectedAnswers,
      Question question,
      ) {
    return question.options.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;
      final isSelected = selectedAnswers.contains(index);

      return buildOption(selectedAnswers, question, isSelected, index, option);
    }).toList();
  }

  GestureDetector buildOption(List<int> selectedAnswers, Question question, bool isSelected, int index, String option) {

    ThemeData theme = Theme.of(context);

    return GestureDetector(
      onTap:
          widget.isResponseLocked
              ? null
              : () {
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

                widget.onAnswerChanged(newAnswers);
              },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color:
              isSelected
                  ? theme.colorScheme.primaryContainer
                  : widget.isResponseLocked
                  ? theme.colorScheme.surfaceDim
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              question.isMultipleChoice
                  ? (isSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank_rounded)
                  : (isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked),
              color:
                  isSelected || !widget.isResponseLocked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(
                        alpha: 0.4,
                      ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isSelected || !widget.isResponseLocked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Option 2: Fixed height with scroll indicators
  Widget buildConstrainedScrollableOptions() {
    double maxHeight = MediaQuery.of(context).size.height * 0.35; // 40% of screen
    double minHeight = 200; // Minimum height to show at least 4 options

    return Container(
      height: widget.question.options.length > 4 ? maxHeight : null,
      constraints: BoxConstraints(
        minHeight: minHeight,
        maxHeight: maxHeight,
      ),
      child: Stack(
        children: [
          ListView.builder(
            shrinkWrap: widget.question.options.length <= 3,
            padding: const EdgeInsets.only(bottom: 10,),
            itemCount: widget.question.options.length,
            itemBuilder: (context, index) {
              final option = widget.question.options[index];
              final isSelected = widget.selectedAnswers.contains(index);
              return buildOption(widget.selectedAnswers, widget.question, isSelected, index, option);
            },
          ),

          // "More options" indicator at bottom
          if (widget.question.options.length > 4)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 25,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Theme.of(context).colorScheme.outline,
                      ),

                      SizedBox(width: 5,),

                      Text(
                        "Scroll for more",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Alternative: Auto-detect if scrolling is needed
  Widget buildSmartScrollableQuestionText() {
    if (widget.question.text == null) return SizedBox.shrink();

    // Use LayoutBuilder to detect if content overflows
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxHeight = MediaQuery.of(context).size.height * 0.27;

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            children: [
              SizedBox(height: 10),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          border: Border.all(
                            color: Colors.black,
                            width: 3,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          child: Text(
                            widget.question.text!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),

                    // Scroll indicator (you could make this conditional)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Theme.of(context).colorScheme.surface,
                              Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
