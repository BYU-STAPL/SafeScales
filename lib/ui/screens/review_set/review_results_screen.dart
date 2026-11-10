import 'package:flutter/material.dart';

class ReviewResultsScreen extends StatefulWidget {
  String? image;
  final bool needToShowShop;

  ReviewResultsScreen({super.key, this.image, required this.needToShowShop});

  @override
  _ReviewResultsScreen createState() => _ReviewResultsScreen();
}

class _ReviewResultsScreen extends State<ReviewResultsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review Complete'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _buildCompletionScreen(context),
    );
  }

  Widget _buildCompletionScreen(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 25),
        child: Column(
          children: [
            Text(
              'Great job completing the review!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 30),

            Text(
              'Your answers have been submitted successfully.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),

            SizedBox(height: 30),

            Icon(
              Icons.verified_outlined,
              size: 180,
              color: theme.colorScheme.secondary,
            ),

            SizedBox(height: 30),

            Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
                child: Text(
                  'Return'.toUpperCase(),
                  style: TextStyle(
                    fontSize: theme.textTheme.bodyMedium?.fontSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
