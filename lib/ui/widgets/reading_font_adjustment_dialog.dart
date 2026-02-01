import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class ReadingFontAdjustmentDialog extends StatelessWidget {
  const ReadingFontAdjustmentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return AlertDialog(
          title: Text(
            'Reading Font Size',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'A',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: themeNotifier.readingFontSize,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      onChanged: (value) {
                        themeNotifier.updateReadingFontSize(value);
                      },
                      activeColor: colorScheme.primary,
                    ),
                  ),
                  Text(
                    'A',
                    style: TextStyle(
                      fontSize: 28,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Preview: ${(themeNotifier.readingFontSize * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}



