import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/models/reading_slide.dart';

class LessonProgress {
  final String lessonId;

  bool isReadingComplete = false;

  QuizAttempt? preQuizAttempt;
  List<QuizAttempt> postQuizAttempts = [];

  bool get isPreQuizComplete => preQuizAttempt != null;
  bool get isPostQuizComplete => postQuizAttempts.isNotEmpty;

  // TODO: Consider implementing later
  // List<QuizResult> reviewAttempts;

  LessonProgress({
    required this.lessonId,
    required this.isReadingComplete,
    required this.postQuizAttempts,
    this.preQuizAttempt,
  });

}


class QuizAttempt {
  final String id;
  final String quizId;
  final String lessonId;
  final ActivityType type; // preQuiz, postQuiz, practice, assessment

  // Results
  final int score; // percentage (0-100)
  final int correctAnswers; // Number of correct answers
  final int totalQuestions;
  final List<List<int>> responses;

  // Timing
  // final DateTime startedAt;
  final DateTime completedAt;
  // final int timeSpentSeconds;

  // Status
  // final int attemptNumber;
  // final bool passed; // based on passing threshold

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.lessonId,
    required this.type,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.responses,
    // required this.startedAt,
    required this.completedAt,
    // required this.timeSpentSeconds,
    // required this.attemptNumber,
    // required this.passed,
  });
}