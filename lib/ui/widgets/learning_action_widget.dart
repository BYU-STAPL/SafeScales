import 'package:flutter/material.dart';
import 'package:safe_scales/extensions/string_extensions.dart';

enum ActionType { continueLearning, review }


class LearningActionWidget extends StatelessWidget {
  const LearningActionWidget({
    super.key,
    required this.actionType,
    required this.title,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final double progress;

  final ActionType actionType;

  final Function() onTap;

  @override
  Widget build(BuildContext context) {

    final ThemeData theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary.withValues(alpha: 0.9), theme.colorScheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionType == ActionType.continueLearning ? 'Continue Learning'.toTitleCase() : 'Time to Review'.toTitleCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  (title).toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                actionType == ActionType.continueLearning ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${progress.toStringAsFixed(0)}% Complete'.toTitleCase(),
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                  ),
                )
                    : SizedBox.shrink(),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}