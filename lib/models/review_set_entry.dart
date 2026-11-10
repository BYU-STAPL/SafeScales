import 'package:safe_scales/models/question.dart';

/// Represents the current review question batch for a lesson.
class ReviewSetEntry {
  /// Lesson ID for this review set.
  final String lessonId;

  /// Display title, usually the lesson title.
  final String title;

  /// The question set, or null if no review set exists for this lesson.
  final QuestionSet? questionSet;

  /// True if the user has completed the post-quiz for this lesson.
  final bool isUnlocked;

  const ReviewSetEntry({
    required this.lessonId,
    required this.title,
    this.questionSet,
    required this.isUnlocked,
  });
}
