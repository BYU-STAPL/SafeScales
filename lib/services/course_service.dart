import 'dart:convert';

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


  Future<String?> getUserCourseId(String userId) async {
    try {
      // Get user's class
      final classData = await _repository.getUserClass(userId);
      if (classData == null) {
        return null;
      }

      return classData['id'];

    } catch (e) {
      throw CourseServiceException('Failed to load course id: $e');
    }
  }

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

  /// Get single lesson from a class
  Future<Lesson> getLessonFromClass(String classId, String lessonId) async {
    try {

      final moduleData = await _repository.getModuleById(lessonId);

      if (moduleData == null) {
        throw CourseServiceException('No module found');
      }

      final lesson = _createLessonFromRawData(moduleData);

      return lesson;
    } catch (e) {
      throw CourseServiceException('Failed to load lesson ${lessonId} from class ${classId}: $e');
    }
  }



  // === Progress Business Logic ===

  /// Get complete progress data for a user with business logic applied
  // Future<Map<String, dynamic>?> getUserProgressData(String userId) async {
  //   try {
  //     // First verify user has a class
  //     final classData = await _repository.getUserClass(userId);
  //     if (classData == null) {
  //       return null;
  //     }
  //
  //     // Get raw progress data
  //     final progressData = await _repository.getUserProgressData(userId);
  //     return progressData;
  //   } catch (e) {
  //     print('Error getting user progress data: $e');
  //     return null;
  //   }
  // }

  Future<Map<String, LessonProgress>> getUserProgress(String userId) async {
    try {
      // First verify user has a class
      final classData = await _repository.getUserClass(userId);
      if (classData == null) {
        return {};
      }

      // Get lessons in class to filter progress
      final lessonsInClass = await _repository.getLessonOrder(classData['id']);
      final progressData = await _repository.getUserReadingProgress(userId);

      if (progressData == null) {
        return {};
      }

      Map<String, LessonProgress> progress = {};

      // Process progress for each lesson in the class
      for (var lessonId in lessonsInClass) {


        LessonProgress? lessonProgress = await getLessonProgress(userId, lessonId);

        if (lessonProgress != null) {
          progress[lessonId] = lessonProgress;
        }
      }

      return progress;
    } catch (e) {
      throw CourseServiceException('Failed to load user progress: $e');
    }
  }

  Future<LessonProgress?> getLessonProgress(String userId, String lessonId,) async {
    try {
      // Data needed
      QuizAttempt? preQuizAttempt;
      bool isReadingComplete = false;
      Set<int> bookmarks = {};
      Map<String, List<QuizAttempt>> quizAttempts;

      // Verify lesson is in user's class
      final classData = await _repository.getUserClass(userId);
      if (classData == null) {
        throw CourseServiceException('Class data for user ${userId} is null');
      }
      final String classId = classData['id'];


      final lessonsInClass = await _repository.getLessonOrder(classId);
      if (!lessonsInClass.contains(lessonId)) {
        throw CourseServiceException('Lesson data for lesson $lessonId in class ${classId} is null');
      }


      // Get the User's reading data
      //TODO: Replace with better reading data table access
      final progressData = await _repository.getUserReadingProgress(userId);
      if (progressData == null || !progressData.containsKey(lessonId)) {
        throw CourseServiceException('Lesson data for lesson $lessonId in class ${classId} is null or no matching lesson id');
      }
      Map<String, dynamic> lessonProgressData = progressData[lessonId];


      if (lessonProgressData.containsKey('reading')) {
        final readingData = lessonProgressData['reading'] as Map<String, dynamic>;

        if (readingData.containsKey('bookmarks')) {
          bookmarks = Set<int>.from(readingData['bookmarks'],);
        }

        isReadingComplete = readingData['completed'] ?? false;
      }

      // Get the User's quiz data for lesson
      quizAttempts = await getUserQuizAttemptsForLesson(userId, lessonId);

      // Get required passing score from lesson definition
      final lessons = await getLessonsForClass(classId);
      final passingScore = lessons[lessonId]?.postQuiz.passingScore ?? 80;

      if (quizAttempts['preQuiz'] != null && quizAttempts['preQuiz']!.isNotEmpty) {
        preQuizAttempt = quizAttempts['preQuiz']![0];
      }

      // Build Lesson Progress
      LessonProgress lessonProgress = LessonProgress(
          lessonId: lessonId,
          isReadingComplete: isReadingComplete,
          bookmarks: bookmarks,
          requiredPassingScore: passingScore,
          postQuizAttempts: quizAttempts['postQuizAttempts'] ?? [],
          preQuizAttempt: preQuizAttempt,
      );

      // Return
      return lessonProgress;
    }
    catch (e) {
      throw CourseServiceException('getLessonProgress: Failed to load lesson progress for user $userId for lesson $lessonId: $e');
    }
  }

  /// Get User QuizAttempts
  Future<Map<String, List<QuizAttempt>>> getUserQuizAttemptsForLesson(String userId, String lessonId) async {
    try {
      // Get Raw Data
      final rawData = await _repository.getUserQuizAttempts(userId, lessonId);

      if (rawData.isEmpty) {
        // No Quiz Attempts found for user or lesson
        return {};
      }

      List<QuizAttempt> preQuizAttempt = [];
      List<QuizAttempt> postQuizAttempts = [];

      // Map to Model class
      for (final rawQuizAttempt in rawData) {

        if (rawQuizAttempt['quiz_type'] == 'post_quiz') {

          QuizAttempt quizAttempt = QuizAttempt(
            id: rawQuizAttempt['id'],
            quizId: rawQuizAttempt['quiz_id'],
            lessonId: rawQuizAttempt['quiz_id'].split('_')[0],
            type: ActivityType.postQuiz,
            correctAnswers: rawQuizAttempt['num_correct_answers'],
            totalQuestions: rawQuizAttempt['total_questions'],
            responses: _parseResponses(rawQuizAttempt['question_responses']),
            startedAt: DateTime.parse(rawQuizAttempt['started_at']),
            completedAt: DateTime.parse(rawQuizAttempt['completed_at']),
          );

          postQuizAttempts.add(quizAttempt);

        }
        else if (rawQuizAttempt['quiz_type'] == 'pre_quiz' && preQuizAttempt.isEmpty) {

          // Should only add 1 preQuizAttempt
          QuizAttempt quizAttempt = QuizAttempt(
            id: rawQuizAttempt['id'],
            quizId: rawQuizAttempt['quiz_id'],
            lessonId: rawQuizAttempt['quiz_id'].split('_')[0],
            type: ActivityType.preQuiz,
            correctAnswers: rawQuizAttempt['num_correct_answers'],
            totalQuestions: rawQuizAttempt['total_questions'],
            responses: _parseResponses(rawQuizAttempt['question_responses']),
            startedAt: DateTime.parse(rawQuizAttempt['started_at']),
            completedAt: DateTime.parse(rawQuizAttempt['completed_at']),
          );

          preQuizAttempt.add(quizAttempt);
        }
      }

      Map<String, List<QuizAttempt>> quizAttempts = {};

      quizAttempts['preQuiz'] = preQuizAttempt;
      quizAttempts['postQuizAttempts'] = postQuizAttempts;

      // Return Attempts
      return quizAttempts;
    }
    catch (e) {
      throw CourseServiceException('getUserQuizAttempts: Failed to get user quiz attempts: $e');
    }
  }

  /// Save quiz progress with business logic validation
  Future<void> saveQuizProgress({required String userId, required String quizId, required ActivityType quizType, required List<List<int>> userAnswers, required int correctAnswers, required int totalQuestions, required DateTime startTime, required DateTime endTime,}) async {
    try {
      // Business rule: Validate score calculation
      if (correctAnswers > totalQuestions) {
        throw CourseServiceException(
          'Correct answers cannot exceed total questions',
        );
      }

      // Business rule: Validate answers format
      if (userAnswers.length != totalQuestions) {
        throw CourseServiceException(
          'Number of answers must match total questions',
        );
      }

      // TODO: start using new function save Quiz Attempt
      await _repository.saveQuizAttempt(
        userId: userId,
        quizId: quizId,
        quizType: quizType,
        answers: userAnswers,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        startTime: startTime,
        endTime: endTime,
      );


    } catch (e) {
      throw CourseServiceException('Failed to save quiz progress: $e');
    }
  }

  /// Save reading progress with business logic
  Future<void> saveReadingProgress({required String userId, required String lessonId, required Set<int> bookmarks,}) async {
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
  Future<LessonProgress?> _buildLessonProgress(String lessonId, Map<String, dynamic> moduleData, String classId,) async {
    try {
      QuizAttempt? preQuizAttempt;
      List<QuizAttempt> postQuizAttempts = [];
      bool isReadingComplete = false;
      Set<int> bookmarks = {};

      // Get required passing score from lesson definition
      final lessons = await getLessonsForClass(classId);
      final passingScore = lessons[lessonId]?.postQuiz.passingScore ?? 80;

      // Process reading progress
      if (moduleData.containsKey('reading')) {
        final readingData = moduleData['reading'] as Map<String, dynamic>;

        if (readingData.containsKey('bookmarks')) {
          bookmarks = Set<int>.from(readingData['bookmarks'],);
        }

        isReadingComplete = readingData['completed'] ?? false;
      }

      // Process pre-quiz progress
      // if (moduleData.containsKey('preQuiz') && moduleData['preQuiz'] != null) {
      //   final preQuizData = moduleData['preQuiz'] as Map<String, dynamic>;
      //   if (preQuizData['spent'] == true) {
      //     preQuizAttempt = _createQuizAttempt(
      //       lessonId,
      //       'preQuiz',
      //       ActivityType.preQuiz,
      //       preQuizData,
      //     );
      //   }
      // }

      // Process post-quiz progress
      if (moduleData.containsKey('postQuiz') &&
          moduleData['postQuiz'] != null) {
        final postQuizData = Map<String, dynamic>.from(
          moduleData['postQuiz'] as Map,
        );
        if (postQuizData['spent'] == true) {
          // final attempt = _createQuizAttempt(
          //   lessonId,
          //   'postQuiz',
          //   ActivityType.postQuiz,
          //   postQuizData,
          // );
          // postQuizAttempts.add(attempt);
        }
      }

      final progress = LessonProgress(
        lessonId: lessonId,
        isReadingComplete: isReadingComplete,
        bookmarks: bookmarks,
        requiredPassingScore: passingScore,
        preQuizAttempt: preQuizAttempt,
        postQuizAttempts: postQuizAttempts,
      );

      return progress;

    } catch (e) {
      return null;
    }
  }

  /// Create a QuizAttempt from raw data
  // QuizAttempt _createQuizAttempt(
  //   String lessonId,
  //   String type,
  //   ActivityType activityType,
  //   Map<String, dynamic> activityData,
  // ) {
  //
  //   final score = (activityData['score'] ?? 0).toDouble();
  //   final correctAnswers = activityData['correct_answers'] ?? 0;
  //   final totalQuestions = activityData['total_questions'] ?? 0;
  //   final responses = _parseResponses(activityData['answers'] ?? []);
  //   final completedAt =
  //       activityData['completed_at'] != null
  //           ? DateTime.parse(activityData['completed_at'])
  //           : DateTime.now();
  //
  //   return QuizAttempt(
  //     id: '',
  //     quizId: '${lessonId}_$type',
  //     lessonId: lessonId,
  //     type: activityType,
  //     correctAnswers: correctAnswers,
  //     totalQuestions: totalQuestions,
  //     responses: responses,
  //     completedAt: completedAt,
  //   );
  // }

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
      review: _createReviewSet(lessonMap),
    );
  }

  QuestionSet _createPreQuiz(Map<String, dynamic> lessonMap) {
    final preQuizMap = Map<String, dynamic>.from(lessonMap['pre_quiz'] as Map);
    final questions = _createQuestionsFromList(
      List<dynamic>.from(preQuizMap['questions'] as List),
    );
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
    final postQuizMap = Map<String, dynamic>.from(
      lessonMap['post_quiz'] as Map,
    );
    final questions = _createQuestionsFromList(
      List<dynamic>.from(postQuizMap['questions'] as List),
    );
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
      questions.add(_createSingleQuestion(Map<String, dynamic>.from(q as Map)));
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
    final revision = Map<String, dynamic>.from(lessonMap['revision'] as Map);
    final slides = List<dynamic>.from(revision['slides'] as List);
    List<ReadingSlide> reading = [];

    for (var slideData in slides) {
      final slide = _createSingleReadingSlide(
        Map<String, dynamic>.from(slideData as Map),
      );
      reading.add(slide);
    }
    return reading;
  }

  ReadingSlide _createSingleReadingSlide(Map<String, dynamic> slideData) {
    final content = slideData['content'];

    return ReadingSlide(title: slideData['headline'], content: content);
  }

  QuestionSet _createReviewSet(Map<String, dynamic> lessonMap,) {
    final String moduleId = lessonMap['id'].toString();
    final String title = (lessonMap['title'] ?? 'Module Review').toString();
    final String subject = 'General';

    dynamic reviewSetData = lessonMap['revision_questions'];
    if (reviewSetData is String) {
      try {
        reviewSetData = reviewSetData.isNotEmpty ? (reviewSetData == 'null' ? {} : jsonDecode(reviewSetData)) : {};
      } catch (_) {
        reviewSetData = {};
      }
    }

    final List<dynamic> rawQuestions =
    (reviewSetData is Map<String, dynamic>)
        ? List<dynamic>.from(reviewSetData['questions'] ?? [])
        : (reviewSetData is List)
        ? reviewSetData
        : <dynamic>[];

    final List<Question> questions = [];
    for (int i = 0; i < rawQuestions.length; i++) {
      final q = rawQuestions[i] as Map<String, dynamic>;
      final String questionText = (q['question'] ?? '').toString();
      final List<String> options = List<String>.from(
        q['choices']?.map((c) => c.toString()) ?? [],
      );
      // answer could be a string index like "0" or an int
      final dynamic answerRaw = q['answer'];
      int correctIndex = 0;
      if (answerRaw is int) {
        correctIndex = answerRaw;
      } else if (answerRaw is String) {
        correctIndex = int.tryParse(answerRaw) ?? 0;
      }

      questions.add(
        Question.singleAnswer(
          id: 'q_$i',
          questionText: questionText,
          options: options,
          correctAnswerIndex: correctIndex,
          explanation: '',
        ),
      );
    }

    return QuestionSet(
      id: 'rev_$moduleId',
      title: '$title Review',
      description: 'Answer the review questions to unlock your item.',
      activityType: ActivityType.review,
      subject: subject,
      passingScore: 0,
      showResults: false,
      showCorrectAnswers: true,
      showExplanations: false,
      allowRetakes: true,
      questions: questions,
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
