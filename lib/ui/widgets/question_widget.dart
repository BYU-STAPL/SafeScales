import 'package:flutter/material.dart';
import 'package:safe_scales/models/question.dart';

import '../../themes/app_theme.dart';

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
  final double optionPadding = 15;
  final double optionMargin = 10;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset scroll position when question changes
    if (oldWidget.question != widget.question) {
      _scrollController.jumpTo(0);
    }
  }

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

    if (question.isMultipleAnswer) {
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
        // If no extra text place spacer before question - for centering or to push question to the bottom
        if (question.text == null) const Spacer(),

        if (question.text != null) ...[
          // Extra Text exists, show it first, then do spacer, then question
          Text(question.text!, style: theme.textTheme.bodyMedium),

          const Spacer(),
        ],

        Text(
          question.questionText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        // If no extra text place spacer after question too - for centering
        if (question.text == null) const Spacer(),

        SizedBox(height: 20),

        instructionText,

        buildScrollableOptions(),
        // buildConstrainedScrollableOptions(),

        // Show explanation after user answers (when response is locked or we have answers)
        if (widget.showExplanation &&
            question.explanation.isNotEmpty &&
            (widget.isResponseLocked || widget.selectedAnswers.isNotEmpty))
          _buildExplanationSection(),
      ],
    );
    //   ),
    // );
  }

  GestureDetector buildOption(
    List<int> selectedAnswers,
    Question question,
    bool isSelected,
    int index,
    String option,
  ) {
    ThemeData theme = Theme.of(context);

    return GestureDetector(
      onTap:
          widget.isResponseLocked
              ? null
              : () {
                List<int> newAnswers = List.from(selectedAnswers);

                if (question.isMultipleAnswer) {
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
        margin: EdgeInsets.symmetric(vertical: optionMargin),
        padding: EdgeInsets.all(optionPadding),
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
              question.isMultipleAnswer
                  ? (isSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank_rounded)
                  : (isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked),
              color:
                  isSelected || !widget.isResponseLocked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isSelected || !widget.isResponseLocked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildScrollableOptions() {
    double optionFontSize =
        Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18;

    double fontScale = AppTheme.fontSizeScale;
    double maxHeight = 250;

    // Estimate average option height (you'll need to tune this based on your buildOption implementation)
    // 30 from the 15 all around padding around the text
    // 20 for the vertical margin between options
    double estimatedOptionHeight =
        (optionFontSize + optionPadding * 2 + optionMargin * 2) *
        fontScale; // Adjust this value
    double estimatedTotalHeight =
        widget.question.options.length * estimatedOptionHeight;

    bool hasOverflow = estimatedTotalHeight > maxHeight;

    return Container(
      height: hasOverflow ? maxHeight : null,
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            shrinkWrap: !hasOverflow,
            padding: EdgeInsets.only(
              bottom: hasOverflow ? (25 * fontScale) : (10 * fontScale),
            ),
            itemCount: widget.question.options.length,
            itemBuilder: (context, index) {
              final option = widget.question.options[index];
              final isSelected = widget.selectedAnswers.contains(index);
              return buildOption(
                widget.selectedAnswers,
                widget.question,
                isSelected,
                index,
                option,
              );
            },
          ),

          if (hasOverflow)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 25 * fontScale,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18 * fontScale,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      SizedBox(width: 5 * fontScale),
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

  Widget _buildExplanationSection() {
    ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Explanation:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.question.explanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
