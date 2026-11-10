import 'package:flutter_test/flutter_test.dart';
import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/repositories/course_repository.dart';
import 'package:safe_scales/services/course_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final questions = List.generate(
    15,
    (index) => {
      'question': 'Question $index?',
      'choices': ['Yes', 'No'],
      'answer': 0,
      'explanation': 'Explanation $index',
    },
  );

  test('loads the full review question bank in its persisted order', () async {
    final service = CourseService(
      repository: _InMemoryCourseRepository([
        _module(reviewSetQuestions: questions),
      ]),
    );

    final lessons = await service.getLessonsForClass('class-1');
    final review = lessons['module-1']!.review!;

    expect(review.questions, hasLength(15));
    expect(
      review.questions.map((question) => question.questionText),
      List.generate(15, (index) => 'Question $index?'),
    );
    expect(review.showResults, isFalse);
    expect(review.showCorrectAnswers, isTrue);
    expect(review.showExplanations, isFalse);
  });

  test(
    'selects consecutive five-question batches and cycles to the start',
    () async {
      final service = CourseService(
        repository: _InMemoryCourseRepository([
          _module(reviewSetQuestions: questions),
        ]),
      );
      final lessons = await service.getLessonsForClass('class-1');
      final bank = lessons['module-1']!.review!;

      for (var completedSets = 0; completedSets < 4; completedSets++) {
        final batch = bank.reviewBatchForCompletionCount(completedSets);
        final batchStart = (completedSets % 3) * 5;
        expect(
          batch.questions.map((question) => question.questionText),
          List.generate(5, (index) => 'Question ${batchStart + index}?'),
        );
      }
    },
  );

  test('allows a shorter final batch before cycling', () {
    final bank = QuestionSet.review(
      id: 'rev_module-1',
      title: 'Module 1 Review',
      description: 'Review',
      subject: 'General',
      questions: List.generate(
        12,
        (index) => Question.singleAnswer(
          id: 'question-$index',
          questionText: 'Question $index?',
          options: const ['Yes', 'No'],
          correctAnswerIndex: 0,
          explanation: '',
        ),
      ),
    );

    expect(
      bank
          .reviewBatchForCompletionCount(2)
          .questions
          .map((question) => question.id),
      ['question-10', 'question-11'],
    );
    expect(
      bank
          .reviewBatchForCompletionCount(3)
          .questions
          .map((question) => question.id),
      ['question-0', 'question-1', 'question-2', 'question-3', 'question-4'],
    );
  });

  test(
    'does not fall back to the source pool when no saved set exists',
    () async {
      final service = CourseService(
        repository: _InMemoryCourseRepository([
          _module(
            reviewSetQuestions: null,
            revisionQuestions: {'questions': questions},
          ),
        ]),
      );

      final lessons = await service.getLessonsForClass('class-1');

      expect(lessons['module-1']!.review!.questions, isEmpty);
    },
  );

  test('rejects a question bank that contains fewer than five items', () {
    final service = CourseService(
      repository: _InMemoryCourseRepository([
        _module(reviewSetQuestions: questions.take(4).toList()),
      ]),
    );

    expect(
      () => service.getLessonsForClass('class-1'),
      throwsA(isA<CourseServiceException>()),
    );
  });
}

Map<String, dynamic> _module({
  required dynamic reviewSetQuestions,
  dynamic revisionQuestions,
}) => {
  'id': 'module-1',
  'title': 'Module 1',
  'pre_quiz': {'questions': <dynamic>[]},
  'post_quiz': {'questions': <dynamic>[]},
  'minimum_passing_grade': 80,
  'revision': {'slides': <dynamic>[]},
  'revision_questions': revisionQuestions,
  'review_set_questions': reviewSetQuestions,
};

class _InMemoryCourseRepository extends CourseRepository {
  _InMemoryCourseRepository(this.modules)
    : super(supabase: SupabaseClient('http://localhost:54321', 'test-key'));

  final List<Map<String, dynamic>> modules;

  @override
  Future<List<Map<String, dynamic>>> getClassModules(String classId) async =>
      modules;
}
