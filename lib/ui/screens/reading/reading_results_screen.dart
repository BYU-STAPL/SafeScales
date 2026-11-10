import 'package:flutter/material.dart';

class ReadingResultScreen extends StatefulWidget {
  const ReadingResultScreen({super.key, required this.modeuleId});

  final String modeuleId;

  @override
  State<ReadingResultScreen> createState() => _ReadingResultScreenState();
}

class _ReadingResultScreenState extends State<ReadingResultScreen> {
  bool _isNavigating = false;

  void _handleReturnToLesson() {
    // Prevent multiple taps - use sync flag only (no setState before pop)
    // setState before Navigator.pop can cause race conditions where the widget
    // is disposed during a scheduled rebuild, leading to inconsistent behavior
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reading Complete'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
          child: Column(
            children: [
              Text(
                'Great job completing the reading!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 30),

              Text(
                'Reading complete. You are ready for the post-quiz.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),

              SizedBox(height: 30),

              Icon(
                Icons.menu_book_outlined,
                size: 180,
                color: theme.colorScheme.secondary,
              ),

              SizedBox(height: 30),

              Text(
                'Complete the post-quiz to finish this module.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),

              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isNavigating ? null : _handleReturnToLesson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                  child: Text(
                    'Return to lesson'.toUpperCase(),
                    style: TextStyle(
                      fontSize: theme.textTheme.bodyMedium?.fontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
