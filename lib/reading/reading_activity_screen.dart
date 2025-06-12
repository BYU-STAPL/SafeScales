import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReadingActivityScreen extends StatefulWidget {
  final String topic;

  const ReadingActivityScreen({Key? key, required this.topic})
    : super(key: key);

  @override
  State<ReadingActivityScreen> createState() => _ReadingActivityScreenState();
}

class _ReadingActivityScreenState extends State<ReadingActivityScreen> {
  bool _hasReadContent = false;
  bool _hasAnsweredQuestions = false;

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Reading Activity'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reading content
            Text(
              'Understanding ${widget.topic}',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reading Content',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This is where the reading content for ${widget.topic} will be displayed. '
                    'The content should be comprehensive and educational.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  // Mark as read button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _hasReadContent
                              ? null
                              : () {
                                setState(() {
                                  _hasReadContent = true;
                                });
                              },
                      child: Text(
                        _hasReadContent ? 'Content Read' : 'Mark as Read',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Comprehension questions
            if (_hasReadContent) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comprehension Questions',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    // Add your comprehension questions here
                    Text(
                      'Sample question: What are the key points about ${widget.topic}?',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    // Complete questions button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _hasAnsweredQuestions
                                ? null
                                : () {
                                  setState(() {
                                    _hasAnsweredQuestions = true;
                                  });
                                },
                        child: Text(
                          _hasAnsweredQuestions
                              ? 'Questions Completed'
                              : 'Complete Questions',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Complete activity button
              if (_hasAnsweredQuestions)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        true,
                      ); // Return true to indicate completion
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Complete Activity'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
