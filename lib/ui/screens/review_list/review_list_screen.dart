import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/models/review_set_entry.dart';
import 'package:safe_scales/providers/course_provider.dart';
import 'package:safe_scales/ui/screens/review_set/review_screen.dart';

class ReviewListScreen extends StatelessWidget {
  const ReviewListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<CourseProvider>(
      builder: (context, courseProvider, _) {
        if (courseProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final entries = courseProvider.getReviewSetEntries();

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete review sets from finished lessons and earn an item or habitat for your dragon.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (entries.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No review sets available yet.\nComplete lessons to unlock them.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ReviewSetCard(
                          entry: entry,
                          onTap: () => _handleTap(context, entry),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTap(BuildContext context, ReviewSetEntry entry) async {
    if (!entry.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Complete this lesson to unlock'),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        ),
      );
      return;
    }

    final questionSet = entry.questionSet;
    if (questionSet == null || questionSet.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'The Teacher has not created a review set for this lesson',
          ),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ReviewScreen(questionSet: questionSet, needToShowShop: true),
      ),
    );

    if (context.mounted && entry.lessonId != null) {
      final courseProvider = Provider.of<CourseProvider>(
        context,
        listen: false,
      );
      await courseProvider.loadSingleLessonProgress(entry.lessonId!);
    }
  }
}

class _ReviewSetCard extends StatelessWidget {
  final ReviewSetEntry entry;
  final VoidCallback onTap;

  const _ReviewSetCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    String subtitle;
    if (entry.isUnlocked && entry.questionSet != null) {
      final count = entry.questionSet!.questions.length;
      subtitle =
          entry.isRandom
              ? '$count questions (Mixed Topics)'
              : '$count questions';
    } else {
      subtitle = 'Complete this lesson to unlock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primary.withValues(alpha: 0.1),
                child: Icon(
                  entry.isRandom
                      ? FontAwesomeIcons.dice
                      : FontAwesomeIcons.repeat,
                  size: 20,
                  color: primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (!entry.isUnlocked)
                Image.asset(
                  'assets/images/other/lock.png',
                  width: 40,
                  height: 40,
                  color: textColor.withValues(alpha: 0.5),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                  color: textColor.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
