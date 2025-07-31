import 'package:safe_scales/models/question.dart';

class LessonProgress {
  final String lessonId;

  bool isReadingComplete = false;

  QuizAttempt? preQuizAttempt;
  List<QuizAttempt> postQuizAttempts = [];

  final int requiredPassingScore;

  bool get isPreQuizComplete => preQuizAttempt != null;
  bool get isPostQuizComplete => postQuizAttempts.first.score >= requiredPassingScore;


  // TODO: Consider implementing later
  // List<QuizResult> reviewAttempts;

  LessonProgress({
    required this.lessonId,
    required this.isReadingComplete,
    required this.requiredPassingScore,
    required this.postQuizAttempts,
    this.preQuizAttempt,
  });


  double getProgressPercent() {

    double progress = 0;

    if (isPreQuizComplete) {
      progress = progress + (1/3);
    }

    if (isReadingComplete) {
      progress = progress + (1/3);
    }

    if (isPostQuizComplete) {
      progress = progress + (1/3);
    }

    progress = progress * 100;

    return progress;
  }
}


class QuizAttempt {
  final String id;
  final String quizId;
  final String lessonId;
  final ActivityType type; // preQuiz, postQuiz, practice, assessment

  // Results
  double score; // percentage (0-100)
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