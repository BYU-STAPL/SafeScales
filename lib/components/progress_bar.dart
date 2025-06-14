import 'package:flutter/material.dart';
import 'package:safe_scales/extensions/string_extensions.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.progress,
    required int currentSlideIndex,
    required this.slideLength,
    required this.slideName,
  }) : _currentSlideIndex = currentSlideIndex;

  final double progress;
  final int _currentSlideIndex;
  final int slideLength;
  final String slideName;
  // final List<Map<String, dynamic>> _slides;

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    // Ensure an s on the end of the slide label
    final String slideLabel;

    if (slideName.lastChars(1).toLowerCase() != "s" ) {
      slideLabel = "${slideName}s";
    }
    else {
      slideLabel = slideName;
    }

    // Build Progress Bar

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.primaryContainer,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),

          const SizedBox(height: 10),
          Text(
            '${(_currentSlideIndex + 1)} of $slideLength ${slideLabel.toLowerCase()}',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
