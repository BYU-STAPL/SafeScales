import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/models/reading_slide.dart';

class Lesson {
  final String lessonId;
  final String title;
  final QuestionSet preQuiz;
  final List<ReadingSlide> reading;
  final QuestionSet postQuiz;
  QuestionSet? review;


  Lesson({
    required this.lessonId,
    required this.title,
    required this.preQuiz,
    required this.reading,
    required this.postQuiz,
    this.review,
  });

}