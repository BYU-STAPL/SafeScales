import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_scales/repositories/course_repository.dart';
import 'package:safe_scales/services/course_service.dart';
import 'package:safe_scales/ui/widgets/progress_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('reading progress marks correctly answered checkpoints', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadingProgressBar(
            progress: 0.75,
            currentSlideIndex: 2,
            slideLength: 4,
            checkpointIndices: [1, 3],
            completedCheckpoints: {1},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('3 of 4 pages'), findsOneWidget);
    expect(find.byTooltip('Checkpoint'), findsOneWidget);
  });
  test(
    'parses prose and checkpoint entries in their persisted order',
    () async {
      final service = CourseService(
        repository: _InMemoryCourseRepository([
          _module([
            {
              'headline': 'Facebook Norms',
              'content': 'Create your own content.',
            },
            {
              'type': 'checkpoint',
              'question': 'Can you create your own posts on Facebook?',
              'choices': ['Yes', 'No'],
              'answer': 0,
              'explanation': 'Yes, users can create posts.',
            },
          ]),
        ]),
      );

      final lesson = (await service.getLessonsForClass('class-1'))['module-1']!;

      expect(lesson.reading, hasLength(2));
      expect(lesson.reading[0].isCheckpoint, isFalse);
      expect(lesson.reading[0].title, 'Facebook Norms');
      expect(lesson.reading[0].content, 'Create your own content.');
      expect(lesson.reading[1].isCheckpoint, isTrue);
      expect(lesson.reading[1].title, 'Checkpoint Question');
      expect(
        lesson.reading[1].checkpointQuestion!.questionText,
        'Can you create your own posts on Facebook?',
      );
      expect(lesson.reading[1].checkpointQuestion!.options, ['Yes', 'No']);
      expect(lesson.reading[1].checkpointQuestion!.isCorrect([0]), isTrue);
      expect(lesson.reading[1].checkpointQuestion!.isCorrect([1]), isFalse);
    },
  );

  test('rejects malformed checkpoint entries', () {
    final service = CourseService(
      repository: _InMemoryCourseRepository([
        _module([
          {'type': 'checkpoint', 'question': 'A question without choices'},
        ]),
      ]),
    );

    expect(
      () => service.getLessonsForClass('class-1'),
      throwsA(isA<CourseServiceException>()),
    );
  });
}

Map<String, dynamic> _module(List<dynamic> slides) => {
  'id': 'module-1',
  'title': 'Module 1',
  'pre_quiz': {'questions': <dynamic>[]},
  'post_quiz': {'questions': <dynamic>[]},
  'minimum_passing_grade': 80,
  'revision': {'slides': slides},
  'review_set_questions': null,
};

class _InMemoryCourseRepository extends CourseRepository {
  _InMemoryCourseRepository(this.modules)
    : super(supabase: SupabaseClient('http://localhost:54321', 'test-key'));

  final List<Map<String, dynamic>> modules;

  @override
  Future<List<Map<String, dynamic>>> getClassModules(String classId) async =>
      modules;
}
