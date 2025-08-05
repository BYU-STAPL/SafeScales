import '../models/course.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import '../models/question.dart';
import '../models/reading_slide.dart';
import '../repositories/course_repository.dart';

/// Service that handles all course-related business logic
/// This layer processes data from the repository and applies business rules
class CourseService {
  final CourseRepository _repository;

  CourseService({CourseRepository? repository})
      : _repository = repository ?? CourseRepository();

  // === Course Content Business Logic ===

  /// Get complete course data for a user including class info and lessons
  Future<CourseData?> getUserCourseData(String userId) async {
    try {
      // Get user's class
      final classData = await _repository.getUserClass(userId);
      if (classData == null) {
        return null;
      }

      // Get lessons for the class
      final lessons = await getLessonsForClass(classData['id']);
      final lessonOrder = await _repository.getLessonOrder(classData['id']);

      return CourseData(
        courseId: classData['id'],
        className: classData['name'] ?? '',
        description: classData['description'] ?? '',
        lessons: lessons,
        lessonOrder: lessonOrder,
      );
    } catch (e) {
      throw CourseServiceException('Failed to load course data: $e');
    }
  }

  /// Get all lessons for a specific class with proper domain models
  Future<Map<String, Lesson>> getLessonsForClass(String classId) async {
    try {
      final moduleData = await _repository.getClassModules(classId);
      Map<String, Lesson> lessons = {};

      for (var lessonMap in moduleData) {
        final lesson = _createLessonFromRawData(lessonMap);
        lessons[lessonMap['id']] = lesson;
      }

      return lessons;
    } catch (e) {
      throw CourseServiceException('Failed to load lessons: $e');
    }
  }

  // === Progress Business Logic ===

  /// Get complete progress data for a user with business logic applied
  Future<Map<String, LessonProgress>> getUserProgress(String userId) async {
    try {
      // First verify user has a class
      final classData = await _repository.getUserClass(userId);
      if (classData == null) {
        return {};
      }

      // Get lessons in class to filter progress
      final lessonsInClass = await _repository.getLessonOrder(classData['id']);
      final progressData = await _repository.getUserProgressData(userId);

      if (progressData == null) {
        return {};
      }

      Map<String, LessonProgress> progress = {};

      // Process progress for each lesson in the class
      for (var lessonId in lessonsInClass) {
        if (progressData.containsKey(lessonId) && lessonId != 'legacy') {
          final lessonProgress = await _buildLessonProgress(
              lessonId,
              progressData[lessonId],
              classData['id']
          );

          if (lessonProgress != null) {
            progress[lessonId] = lessonProgress;
          }
        }
      }

      return progress;
    } catch (e) {
      throw CourseServiceException('Failed to load user progress: $e');
    }
  }

  /// Get progress for a single lesson
  Future<LessonProgress?> getSingleLessonProgress(String userId, String lessonId) async {
    try {
      // Verify lesson is in user's class
      final classData = await _repository.getUserClass(userId);
      if (classData == null) {
        return null;
      }

      final lessonsInClass = await _repository.getLessonOrder(classData['id']);
      if (!lessonsInClass.contains(lessonId)) {
        return null;
      }

      final progressData = await _repository.getUserProgressData(userId);
      if (progressData == null || !progressData.containsKey(lessonId)) {
        return null;
      }

      return await _buildLessonProgress(
          lessonId,
          progressData[lessonId],
          classData['id']
      );
    } catch (e) {
      throw CourseServiceException('Failed to load lesson progress: $e');
    }
  }

  /// Save quiz progress with business logic validation
  Future<void> saveQuizProgress({
    required String userId,
    required String quizId,
    required List<List<int>> userAnswers,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    try {
      // Business rule: Validate score calculation
      if (correctAnswers > totalQuestions) {
        throw CourseServiceException('Correct answers cannot exceed total questions');
      }

      // Business rule: Validate answers format
      if (userAnswers.length != totalQuestions) {
        throw CourseServiceException('Number of answers must match total questions');
      }

      await _repository.saveQuizProgress(
        userId: userId,
        quizId: quizId,
        answers: userAnswers,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
      );
    } catch (e) {
      throw CourseServiceException('Failed to save quiz progress: $e');
    }
  }

  /// Save reading progress with business logic
  Future<void> saveReadingProgress({
    required String userId,
    required String lessonId,
    required Set<int> bookmarks,
  }) async {
    try {
      // Business rule: Validate lesson exists in user's class
      final classData = await _repository.getUserClass(userId);
      if (classData == null) {
        throw CourseServiceException('User is not enrolled in any class');
      }

      final lessonsInClass = await _repository.getLessonOrder(classData['id']);
      if (!lessonsInClass.contains(lessonId)) {
        throw CourseServiceException('Lesson not found in user\'s class');
      }

      await _repository.saveReadingProgress(
        userId: userId,
        lessonId: lessonId,
        bookmarks: bookmarks,
      );
    } catch (e) {
      throw CourseServiceException('Failed to save reading progress: $e');
    }
  }

  // === Private Helper Methods ===

  /// Build a LessonProgress object from raw progress data
  Future<LessonProgress?> _buildLessonProgress(
      String lessonId,
      Map<String, dynamic> quizMap,
      String classId
      ) async {
    try {
      QuizAttempt? preQuizAttempt;
      List<QuizAttempt> postQuizAttempts = [];
      bool isReadingComplete = false;

      // Process each activity type
      for (var type in quizMap.keys) {
        final activityType = _parseActivityType(type);
        final activityData = quizMap[type] as Map<String, dynamic>;

        if (activityType == ActivityType.reading) {
          isReadingComplete = activityData['completed'] ?? false;
        } else {
          final attempt = _createQuizAttempt(
              lessonId,
              type,
              activityType,
              activityData
          );

          if (activityType == ActivityType.postQuiz) {
            postQuizAttempts.add(attempt);
          } else if (activityType == ActivityType.preQuiz) {
            preQuizAttempt = attempt;
          }
        }
      }

      // Get required passing score from lesson definition
      final lessons = await getLessonsForClass(classId);
      final passingScore = lessons[lessonId]?.postQuiz.passingScore ?? 80;

      return LessonProgress(
        lessonId: lessonId,
        isReadingComplete: isReadingComplete,
        requiredPassingScore: passingScore,
        preQuizAttempt: preQuizAttempt,
        postQuizAttempts: postQuizAttempts,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create a QuizAttempt from raw data
  QuizAttempt _createQuizAttempt(
      String lessonId,
      String type,
      ActivityType activityType,
      Map<String, dynamic> activityData,
      ) {
    return QuizAttempt(
      id: '',
      quizId: '${lessonId}_$type',
      lessonId: lessonId,
      type: activityType,
      score: (activityData['score'] ?? 0).toDouble(),
      correctAnswers: activityData['correct_answers'] ?? 0,
      totalQuestions: activityData['total_questions'] ?? 0,
      responses: _parseResponses(activityData['answers'] ?? []),
      completedAt: DateTime.parse(activityData['completed_at']),
    );
  }

  /// Parse activity type from string
  ActivityType _parseActivityType(String type) {
    switch (type) {
      case 'preQuiz':
        return ActivityType.preQuiz;
      case 'postQuiz':
        return ActivityType.postQuiz;
      case 'review':
        return ActivityType.review;
      case 'reading':
        return ActivityType.reading;
      default:
        return ActivityType.reading;
    }
  }

  /// Parse responses from dynamic data
  List<List<int>> _parseResponses(List<dynamic> answers) {
    List<List<int>> responses = [];
    for (final answer in answers) {
      if (answer is List) {
        responses.add(List<int>.from(answer));
      } else {
        responses.add([]);
      }
    }
    return responses;
  }

  /// Transform raw lesson data into domain model
  Lesson _createLessonFromRawData(Map<String, dynamic> lessonMap) {
    return Lesson(
      lessonId: lessonMap['id'].toString(),
      title: lessonMap['title'].toString(),
      preQuiz: _createPreQuiz(lessonMap),
      reading: _createReadingSlides(lessonMap),
      postQuiz: _createPostQuiz(lessonMap),
    );
  }

  QuestionSet _createPreQuiz(Map<String, dynamic> lessonMap) {
    final preQuizMap = lessonMap['pre_quiz'];
    final questions = _createQuestionsFromList(preQuizMap['questions']);
    final String quizId = '${lessonMap['id']}_preQuiz';

    return QuestionSet(
      id: quizId,
      title: '${lessonMap['title']} Pre-Quiz',
      description: '',
      activityType: ActivityType.preQuiz,
      subject: '',
      questions: questions,
    );
  }

  QuestionSet _createPostQuiz(Map<String, dynamic> lessonMap) {
    final postQuizMap = lessonMap['post_quiz'];
    final questions = _createQuestionsFromList(postQuizMap['questions']);
    final String quizId = '${lessonMap['id']}_postQuiz';

    return QuestionSet(
      id: quizId,
      title: '${lessonMap['title']} Post-Quiz',
      description: '',
      activityType: ActivityType.postQuiz,
      subject: '',
      questions: questions,
      passingScore: lessonMap['minimum_passing_grade'],
    );
  }

  List<Question> _createQuestionsFromList(List<dynamic> questionsData) {
    List<Question> questions = [];
    for (var q in questionsData) {
      questions.add(_createSingleQuestion(q));
    }
    return questions;
  }

  Question _createSingleQuestion(Map<String, dynamic> questionData) {

    final List<String> choices = List<String>.from(questionData['choices']);

    List<String> filteredList = choices.where((s) => s.isNotEmpty).toList();

    if (filteredList.isEmpty) {
      filteredList.add("Option");
    }

    return Question.singleAnswer(
      id: '',
      questionText: questionData['question'],
      options: filteredList,
      correctAnswerIndex: int.parse(questionData['answer']),
      explanation: '',
    );
  }

  List<ReadingSlide> _createReadingSlides(Map<String, dynamic> lessonMap) {
    final revision = lessonMap['revision'];
    final slides = revision['slides'];
    List<ReadingSlide> reading = [];

    for (var slideData in slides) {
      final slide = _createSingleReadingSlide(slideData);
      reading.add(slide);
    }
    return reading;
  }

  ReadingSlide _createSingleReadingSlide(Map<String, dynamic> slideData) {
    final content = slideData['content'];
    return ReadingSlide(
      content: [TextContent(content)],
    );
  }
}

// === Domain Models ===

/// Custom exception for course service errors
class CourseServiceException implements Exception {
  final String message;
  CourseServiceException(this.message);

  @override
  String toString() => 'CourseServiceException: $message';
}