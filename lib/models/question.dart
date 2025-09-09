
/*
This file contains code for quiz and review questions and question sets
 */

enum ActivityType { preQuiz, postQuiz, review, reading }

class Question {
  final String id;
  final String? text; // Text is for extra information or background of a question
  final String questionText; // This is the actual question the user answers
  final List<String> options;
  final List<int> correctAnswerIndices;
  final bool isMultipleAnswer;
  final String explanation;
  // final List<String>? photos; // TODO: Do we need photos in questions?

  Question({
    required this.id,
    this.text,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndices,
    required this.isMultipleAnswer,
    required this.explanation,
  });

  // Factory constructors for convenience
  factory Question.singleAnswer({
    required String id,
    String? text,
    required String questionText,
    required List<String> options,
    required int correctAnswerIndex,
    required String explanation,
  }) {
    return Question(
      id: id,
      text: text,
      questionText: questionText,
      options: options,
      correctAnswerIndices: [correctAnswerIndex],
      isMultipleAnswer: false,
      explanation: explanation,
    );
  }

  factory Question.multipleAnswer({
    required String id,
    String? text,
    required String questionText,
    required List<String> options,
    required List<int> correctAnswerIndices,
    required String explanation,
  }) {
    return Question(
      id: id,
      text: text,
      questionText: questionText,
      options: options,
      correctAnswerIndices: correctAnswerIndices,
      isMultipleAnswer: true,
      explanation: explanation,
    );
  }

  bool isCorrect(List<int> selectedIndices) {
    if (selectedIndices.length != correctAnswerIndices.length) return false;

    final sortedSelected = List<int>.from(selectedIndices)..sort();
    final sortedCorrect = List<int>.from(correctAnswerIndices)..sort();

    for (int i = 0; i < sortedSelected.length; i++) {
      if (sortedSelected[i] != sortedCorrect[i]) return false;
    }
    return true;
  }
}


class QuestionSet {
  final String id;
  final String title;
  final String description;
  final ActivityType activityType;
  final String subject;
  final int passingScore;
  final bool showResults; // Show question set summary after completion
  final bool showCorrectAnswers; // Show answer immediately after answering a question
  final bool showExplanations; // Show explanation immediately after answering a question
  final bool allowRetakes;
  final List<Question> questions;

  QuestionSet({
    required this.id,
    required this.title,
    required this.description,
    required this.activityType,
    required this.subject,
    this.passingScore = 80,
    this.showResults = true,
    this.showExplanations = true,
    this.showCorrectAnswers = true,
    this.allowRetakes = true,
    required this.questions,
  });

  factory QuestionSet.preQuiz({
    required id,
    required title,
    required description,
    required subject,
    required questions,
  }) {
    return QuestionSet(
      id: id,
      title: title,
      description: description,
      activityType: ActivityType.preQuiz,
      subject: subject,
      questions: [],
      passingScore: 0,
      showResults: false,
      showCorrectAnswers: false,
      showExplanations: false,
      allowRetakes: false,
    );
  }

  factory QuestionSet.postQuiz({
    required id,
    required title,
    required description,
    required subject,
    required questions,
  }) {
    return QuestionSet(
      id: id,
      title: title,
      description: description,
      activityType: ActivityType.postQuiz,
      subject: subject,
      questions: [],
      passingScore: 80,
      showResults: true,
      showCorrectAnswers: false,
      showExplanations: false,
      allowRetakes: true,
    );
  }

  factory QuestionSet.review({
    required id,
    required title,
    required description,
    required subject,
    required questions,
  }) {
    return QuestionSet(
      id: id,
      title: title,
      description: description,
      activityType: ActivityType.review,
      subject: subject,
      questions: [],
      passingScore: 0,
      showResults: true,
      showCorrectAnswers: true,
      showExplanations: true,
      allowRetakes: true,
    );
  }
}