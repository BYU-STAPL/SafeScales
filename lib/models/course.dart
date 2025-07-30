import 'lesson.dart';

// class Course {
//   final String courseId;
//   final List<String> lessons; // List of lesson ids
//
//   Course({
//     required this.courseId,
//     required this.lessons,
//
//   });
// }

class CourseData {
  final String courseId;
  final String className;
  final String description;
  final Map<String, Lesson> lessons;
  final List<String> lessonOrder;

  CourseData({
    required this.courseId,
    required this.className,
    required this.description,
    required this.lessons,
    required this.lessonOrder,
  });
}