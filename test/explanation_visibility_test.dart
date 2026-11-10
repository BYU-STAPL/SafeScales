import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/ui/screens/review_set/review_screen.dart';
import 'package:safe_scales/ui/widgets/post_quiz_summary.dart';
import 'package:safe_scales/ui/widgets/question_widget.dart';

void main() {
  const explanation = 'This is why the answer is correct.';

  Question question(String id) => Question.singleAnswer(
    id: id,
    questionText: 'Question $id?',
    options: const ['Correct', 'Incorrect'],
    correctAnswerIndex: 0,
    explanation: explanation,
  );

  testWidgets('question widget hides explanations when disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestionWidget(
            question: question('pre'),
            selectedAnswers: const [0],
            onAnswerChanged: (_) {},
            showCorrectAnswer: false,
            showExplanation: false,
            isResponseLocked: true,
          ),
        ),
      ),
    );

    expect(find.text(explanation), findsNothing);
    expect(find.text('Explanation:'), findsNothing);
  });

  testWidgets('post-quiz summary shows explanations after submission', (
    tester,
  ) async {
    final questionSet = QuestionSet.postQuiz(
      id: 'post',
      title: 'Post-quiz',
      description: '',
      subject: '',
      questions: [question('one'), question('two')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PostQuizSummary(
              questionSet: questionSet,
              userAnswers: const [
                [0],
                [1],
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Explanation:'), findsNWidgets(2));
    expect(find.text(explanation), findsNWidgets(2));
  });

  testWidgets('review feedback includes the explanation for either result', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const ReviewAnswerFeedback(
                isCorrect: true,
                explanation: explanation,
              ),
              const ReviewAnswerFeedback(
                isCorrect: false,
                explanation: explanation,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Correct!'), findsOneWidget);
    expect(find.text('Incorrect, try again.'), findsOneWidget);
    expect(find.text(explanation), findsNWidgets(2));
  });
}
