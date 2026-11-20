import 'package:flutter_test/flutter_test.dart';
import 'package:safe_scales/models/lesson_progress.dart';
import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/services/dragon_service.dart';

void main() {
  LessonProgress progress({
    bool preQuiz = false,
    bool reading = false,
    bool postQuiz = false,
  }) {
    return LessonProgress(
      lessonId: 'lesson-1',
      isReadingComplete: reading,
      bookmarks: {},
      requiredPassingScore: 70,
      postQuizAttempts:
          postQuiz
              ? [
                QuizAttempt(
                  id: 'attempt-1',
                  quizId: 'quiz-1',
                  lessonId: 'lesson-1',
                  type: ActivityType.postQuiz,
                  correctAnswers: 8,
                  totalQuestions: 10,
                  responses: const [],
                  startedAt: DateTime(2026, 1, 1),
                  completedAt: DateTime(2026, 1, 1),
                ),
              ]
              : [],
      preQuizAttempt:
          preQuiz
              ? QuizAttempt(
                id: 'pre-1',
                quizId: 'pre-quiz-1',
                lessonId: 'lesson-1',
                type: ActivityType.preQuiz,
                correctAnswers: 5,
                totalQuestions: 10,
                responses: const [],
                startedAt: DateTime(2026, 1, 1),
                completedAt: DateTime(2026, 1, 1),
              )
              : null,
    );
  }

  test('reading completion unlocks teen stage even when percent rounds to 67', () {
    final lessonProgress = progress(preQuiz: true, reading: true);

    // UI rounds this to "67%", but float value is slightly under 66.67.
    expect(lessonProgress.getProgressPercent(), closeTo(66.66666666666666, 1e-9));
    expect(lessonProgress.getProgressPercent() >= 66.67, isFalse);

    expect(
      DragonService.calculateUnlockedPhases(lessonProgress),
      ['egg', 'stage1', 'stage2'],
    );
  });

  test('milestones unlock egg, baby, teen, then adult in order', () {
    expect(DragonService.calculateUnlockedPhases(progress()), ['egg']);
    expect(
      DragonService.calculateUnlockedPhases(progress(preQuiz: true)),
      ['egg', 'stage1'],
    );
    expect(
      DragonService.calculateUnlockedPhases(
        progress(preQuiz: true, reading: true),
      ),
      ['egg', 'stage1', 'stage2'],
    );
    expect(
      DragonService.calculateUnlockedPhases(
        progress(preQuiz: true, reading: true, postQuiz: true),
      ),
      ['egg', 'stage1', 'stage2', 'final'],
    );
  });
}
