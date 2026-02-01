import 'package:safe_scales/models/question.dart';

/// Represents a review set entry for the Review List screen.
/// Can be a lesson-specific review set or the "Random" mixed review set.
class ReviewSetEntry {
  /// Lesson ID, or null for the "Random" entry
  final String? lessonId;

  /// Display title (e.g. lesson title or "Random")
  final String title;

  /// The question set, or null if no review set exists for this lesson
  final QuestionSet? questionSet;

  /// True if the user has completed the post-quiz (for lesson) or has at least one unlocked review (for Random)
  final bool isUnlocked;

  /// True if this is the "Random" mixed-topics entry
  final bool isRandom;

  const ReviewSetEntry({
    this.lessonId,
    required this.title,
    this.questionSet,
    required this.isUnlocked,
    this.isRandom = false,
  });
}
