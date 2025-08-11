import 'package:flutter/material.dart';
import 'package:safe_scales/extensions/string_extensions.dart';

import 'dragon_image_widget.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.moduleId,
    required this.title,
    required this.description,
    required this.actualProgress,
    required this.shouldBeUnlocked,
    required this.newUnlockRequirement,
    required this.onTapCard,
    this.unlockRequirement,
  });

  final String moduleId;

  final String title;
  final String description;
  final double actualProgress;

  final bool shouldBeUnlocked;
  final String? newUnlockRequirement;
  final String? unlockRequirement;

  final VoidCallback onTapCard;


  @override
  Widget build(BuildContext context) {

    final ThemeData theme = Theme.of(context);

    return GestureDetector(
      onTap: shouldBeUnlocked ? onTapCard : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceDim,
          borderRadius: BorderRadius.circular(24.0),
          border:
          shouldBeUnlocked
              ? null
              : Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow:
          shouldBeUnlocked
              ? [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            Text(title.toTitleCase(), style: theme.textTheme.headlineSmall),
            if (!shouldBeUnlocked &&
                (newUnlockRequirement != null ||
                    unlockRequirement != null)) ...[
              const SizedBox(height: 4),
              Text(
                newUnlockRequirement ?? unlockRequirement ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
            if (shouldBeUnlocked && moduleId != 'settings') ...[
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
            ],
            const SizedBox(height: 16),
            // Semi-circular progress bar with icon
            SizedBox(
              height: 100,
              width: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Semi-circular progress
                  if (shouldBeUnlocked && moduleId != 'settings')
                    CustomPaint(
                      size: const Size(160, 80),
                      painter: _SemiCircleProgressPainter(
                        color: theme.colorScheme.secondary,
                        progress: actualProgress / 100,
                      ),
                    ),
                  // Icon in circle
                  shouldBeUnlocked && moduleId != 'settings'
                      ? Positioned(top: 35, child: DragonImageWidget(moduleId: moduleId, size: 65),
                  )
                      : Positioned(
                          top: 10,
                          child: Image.asset(
                            'assets/images/other/lock.png',
                            width: 96,
                            height: 96,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                ],
              ),
            ),
            if (shouldBeUnlocked && moduleId != 'settings') ...[
              Text(
                '${actualProgress.toStringAsFixed(0)}% Complete',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


// Custom painter for semi-circular progress bar with progress
class _SemiCircleProgressPainter extends CustomPainter {
  final Color color;
  final double progress;

  _SemiCircleProgressPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Background arc
    final Paint backgroundPaint =
    Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Progress arc
    final Paint progressPaint =
    Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    // Draw background arc (full semi-circle)
    canvas.drawArc(rect, 3.14159, 3.14159, false, backgroundPaint);

    // Draw progress arc (partial semi-circle based on progress)
    if (progress > 0) {
      canvas.drawArc(rect, 3.14159, 3.14159 * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SemiCircleProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
