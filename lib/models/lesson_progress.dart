import 'package:safe_scales/models/question.dart';

class LessonProgress {
  final String lessonId;

  bool isReadingComplete = false;
  Set<int> bookmarks = {};

  QuizAttempt? preQuizAttempt;
  List<QuizAttempt> postQuizAttempts = [];

  final int requiredPassingScore;

  bool get isPreQuizComplete => preQuizAttempt != null;
  // bool get isPostQuizComplete =>
  //     postQuizAttempts.isNotEmpty &&
  //     postQuizAttempts.first.score >= requiredPassingScore;

  // TODO: Consider implementing later
  // List<QuizAttempt> reviewAttempts;

  LessonProgress({
    required this.lessonId,
    required this.isReadingComplete,
    required this.bookmarks,
    required this.requiredPassingScore,
    required this.postQuizAttempts,
    this.preQuizAttempt,
  });

  bool isPostQuizComplete() {
    // Find at least one attempt where the user passed
    for (final attempt in postQuizAttempts) {
      if (attempt.score >= requiredPassingScore) {
        return true;
      }
    }

    return false;
  }

  double getMostRecentPostQuizScore() {
    return postQuizAttempts.isNotEmpty ? postQuizAttempts.last.score : 0;
  }

  double getHighestPostQuizScore() {
    double highScore = 0;
    for (final attempt in postQuizAttempts) {
      if (attempt.score > highScore) {
        highScore = attempt.score;
      }
    }

    return highScore;
  }

  double getProgressPercent() {
    double progress = 0;

    if (isPreQuizComplete) {
      progress = progress + (1 / 3);
    }

    if (isReadingComplete) {
      progress = progress + (1 / 3);
    }

    if (isPostQuizComplete()) {
      progress = progress + (1 / 3);
    }

    progress = progress * 100;

    return progress;
  }

  String toDebugString() {
    return '''
    LessonProgress {
      lessonId: $lessonId,
      isReadingComplete: $isReadingComplete,
      preQuizAttempt: ${preQuizAttempt != null ? 'Score: ${preQuizAttempt!.score}' : 'null'},
      postQuizAttempts: ${postQuizAttempts.length} attempts,
      requiredPassingScore: $requiredPassingScore
    }
    ''';
  }
}

class QuizAttempt {
  final String id;
  final String quizId;
  final String lessonId;
  final ActivityType type; // preQuiz, postQuiz, practice, assessment

  // Results
  // double score; // percentage (0-100)
  final int correctAnswers; // Number of correct answers
  final int totalQuestions;
  final List<List<int>> responses;

  // Timing
  final DateTime startedAt;
  final DateTime completedAt;

  // Status
  // final int attemptNumber;
  // final bool passed; // based on passing threshold

  double get score =>
      ((correctAnswers / totalQuestions) * 100).round().toDouble();

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.lessonId,
    required this.type,
    // required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.responses,
    required this.startedAt,
    required this.completedAt,
    // required this.timeSpentSeconds,
    // required this.attemptNumber,
    // required this.passed,
  });
}
