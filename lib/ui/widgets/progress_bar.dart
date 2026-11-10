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

    if (slideName.lastChars(1).toLowerCase() != "s") {
      slideLabel = "${slideName}s";
    } else {
      slideLabel = slideName;
    }

    // Build Progress Bar

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
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

class ReadingProgressBar extends StatelessWidget {
  const ReadingProgressBar({
    super.key,
    required this.progress,
    required this.currentSlideIndex,
    required this.slideLength,
    required this.checkpointIndices,
    required this.completedCheckpoints,
  });

  final double progress;
  final int currentSlideIndex;
  final int slideLength;
  final List<int> checkpointIndices;
  final Set<int> completedCheckpoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 24,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                final completedWidth = trackWidth * safeProgress;
                double markerLeftFor(int index) {
                  final maxLeft = trackWidth > 20 ? trackWidth - 20 : 0.0;
                  final center =
                      slideLength <= 0
                          ? 10.0
                          : ((index + 0.5) / slideLength) * trackWidth;
                  return (center - 10).clamp(0.0, maxLeft).toDouble();
                }

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      width: completedWidth,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    for (final checkpointIndex in checkpointIndices)
                      Positioned(
                        left: markerLeftFor(checkpointIndex),
                        child: _CheckpointProgressMarker(
                          isComplete: completedCheckpoints.contains(
                            checkpointIndex,
                          ),
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surface,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${currentSlideIndex + 1} of $slideLength pages',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _CheckpointProgressMarker extends StatelessWidget {
  const _CheckpointProgressMarker({
    required this.isComplete,
    required this.color,
    required this.backgroundColor,
  });

  final bool isComplete;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isComplete ? 'Checkpoint complete' : 'Checkpoint',
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isComplete ? color : backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child:
            isComplete
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
      ),
    );
  }
}
