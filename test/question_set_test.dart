import 'package:flutter_test/flutter_test.dart';
import 'package:safe_scales/models/question.dart';

void main() {
  const questionId = 'question-1';

  final question = Question.singleAnswer(
    id: questionId,
    questionText: 'Question?',
    options: const ['Yes', 'No'],
    correctAnswerIndex: 0,
    explanation: '',
  );

  test('quiz factories retain their provided questions', () {
    final preQuiz = QuestionSet.preQuiz(
      id: 'pre',
      title: 'Pre-quiz',
      description: '',
      subject: '',
      questions: [question],
    );
    final postQuiz = QuestionSet.postQuiz(
      id: 'post',
      title: 'Post-quiz',
      description: '',
      subject: '',
      questions: [question],
    );
    final review = QuestionSet.review(
      id: 'review',
      title: 'Review',
      description: '',
      subject: '',
      questions: [question],
    );

    expect(preQuiz.questions.single.id, questionId);
    expect(postQuiz.questions.single.id, questionId);
    expect(review.questions.single.id, questionId);
  });
}
