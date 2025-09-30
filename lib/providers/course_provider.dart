import 'package:flutter/foundation.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import '../models/question.dart';
import '../models/user.dart';
import '../services/course_service.dart';
import '../services/user_state_service.dart';

/// Provider that manages course-related UI state
/// This is the only layer that should be used by UI components
class CourseProvider extends ChangeNotifier {
  final CourseService _courseService;
  final UserStateService _userStateService;

  // === UI State ===
  bool _isLoading = false;
  String? _error;

  // === Course Data ===
  String _courseId = '';
  String _className = '';
  String _description = '';
  Map<String, Lesson> _lessons = {};
  List<String> _lessonOrder = [];

  // === Progress Data ===
  Map<String, LessonProgress> _lessonProgress = {};

  // === Constructor ===
  CourseProvider({
    CourseService? courseService,
    UserStateService? userStateService,
  }) : _courseService = courseService ?? CourseService(),
       _userStateService = userStateService ?? UserStateService();

  // === Getters ===
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get courseId => _courseId;
  String get className => _className;
  String get description => _description;
  Map<String, Lesson> get lessons => Map.unmodifiable(_lessons);
  List<String> get lessonOrder => List.unmodifiable(_lessonOrder);
  Map<String, LessonProgress> get lessonProgress =>
      Map.unmodifiable(_lessonProgress);

  /// Get the current user
  User? get currentUser => _userStateService.currentUser;

  /// Check if user is logged in
  bool get isUserLoggedIn => _userStateService.currentUser != null;

  /// Initialized check
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // === Public Methods ===

  /// Initialize the provider - call this when the provider is first created
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!isUserLoggedIn) {
      _clearData();

      // print('Course Provider initialized');
      _isInitialized = true;
      return;
    }

    await _executeWithErrorHandling(() async {
      await _loadCourseData();
      await loadUserProgress();

      _isInitialized = true;
    });
  }

  /// Refresh all course data
  Future<void> refresh() async {
    await initialize();
  }

  /// Load course content for the current user
  Future<void> loadCourseContent() async {
    if (!isUserLoggedIn) {
      _clearData();
      return;
    }

    await _executeWithErrorHandling(() async {
      await _loadCourseData();
    });
  }

  /// Load Single ReviewSet
  Future<QuestionSet?> getReviewQuestionSetForLesson(String lessonId) async {
    try {
      final currentUser = _userStateService.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get user's course ID
      final courseId = await _courseService.getUserCourseId(currentUser.id);
      if (courseId == null) {
        throw Exception('User not enrolled in any course');
      }

      // Get the lesson from the course service
      final lesson = await _courseService.getLessonFromClass(courseId, lessonId);

      // Extract review questions from the lesson's revision_questions field
      return _extractReviewQuestionSet(lesson);

    } catch (e) {
      debugPrint('Error getting review question set: $e');
      return null;
    }
  }

  /// Load user progress for all lessons
  Future<void> loadUserProgress() async {
    if (!isUserLoggedIn) {
      _lessonProgress.clear();
      notifyListeners();
      return;
    }

    await _executeWithErrorHandling(() async {
      final progress = await _courseService.getUserProgress(currentUser!.id);
      _lessonProgress = progress;
    });
  }


  /// Load progress for a specific lesson
  Future<void> loadSingleLessonProgress(String lessonId) async {
    if (!isUserLoggedIn) return;

    await _executeWithErrorHandling(() async {
      final progress = await _courseService.getLessonProgress(
        currentUser!.id,
        lessonId,
      );

      if (progress != null) {
        _lessonProgress[lessonId] = progress;
      }
    });
  }

  /// Save quiz progress
  Future<bool> saveQuizProgress({
    required String quizId,
    required ActivityType quizType,
    required List<List<int>> userAnswers,
    required int correctAnswers,
    required int totalQuestions,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (!isUserLoggedIn) return false;

    return await _executeWithErrorHandling(() async {
      await _courseService.saveQuizProgress(
        userId: currentUser!.id,
        quizId: quizId,
        quizType: quizType,
        userAnswers: userAnswers,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        startTime: startTime,
        endTime: endTime,
      );

      // Reload progress for the affected lesson
      final lessonId = quizId.split('_')[0];
      await loadSingleLessonProgress(lessonId);

      return true;
    }, defaultValue: false);
  }

  /// Save reading progress
  Future<bool> saveReadingProgress({
    required String lessonId,
    required Set<int> bookmarks,
  }) async {
    if (!isUserLoggedIn) return false;

    return await _executeWithErrorHandling(() async {
      await _courseService.saveReadingProgress(
        userId: currentUser!.id,
        lessonId: lessonId,
        bookmarks: bookmarks,
      );

      // Reload progress for the lesson
      await loadSingleLessonProgress(lessonId);

      return true;
    }, defaultValue: false);
  }

  /// Clear all error states
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // === Helper Methods ===

  QuestionSet? _extractReviewQuestionSet(Lesson lesson,) {
    try {

      if (lesson.review == null) {
        return null;
      }

      return lesson.review;

    } catch (e) {
      debugPrint('Error extracting review question set: $e');
      return null;
    }
  }

  /// Execute an operation with proper error handling and loading states
  Future<T> _executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    T? defaultValue,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await operation();

      return result;
    } catch (e) {
      _setError(e.toString());
      debugPrint('❌ CourseProvider Error: $e');

      if (defaultValue != null) {
        return defaultValue;
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Load complete course data
  Future<void> _loadCourseData() async {
    final courseData = await _courseService.getUserCourseData(currentUser!.id);

    if (courseData != null) {
      _courseId = courseData.courseId;
      _className = courseData.className;
      _description = courseData.description;
      _lessons = courseData.lessons;
      _lessonOrder = courseData.lessonOrder;
    } else {
      _clearData();
    }
  }

  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error state and notify listeners
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error state
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Clear all data when user logs out or has no class
  void _clearData() {
    _className = '';
    _description = '';
    _lessons.clear();
    _lessonOrder.clear();
    _lessonProgress.clear();
    _clearError();
    _isInitialized = false;
    notifyListeners();
  }

  // === Convenience Getters for UI ===

  /// Get a specific lesson by ID
  Lesson? getLesson(String lessonId) {
    return _lessons[lessonId];
  }

  /// Get progress for a specific lesson
  LessonProgress? getLessonProgress(String lessonId) {
    return _lessonProgress[lessonId];
  }

  /// Check if a lesson is completed
  bool isLessonCompleted(String lessonId) {
    final progress = _lessonProgress[lessonId];
    if (progress == null) return false;

    return progress.isReadingComplete && progress.isPostQuizComplete();
  }

  /// Get completion percentage for the entire course
  double getCourseCompletionPercentage() {
    if (_lessonOrder.isEmpty) return 0.0;

    int completedLessons = 0;
    for (final lessonId in _lessonOrder) {
      if (isLessonCompleted(lessonId)) {
        completedLessons++;
      }
    }

    return (completedLessons / _lessonOrder.length) * 100;
  }


  /// Get list of completed lessons (to unlock for review)
  List<Lesson> getAllCompletedLessons() {

    // Get Id's of completed lessons
    List<String> completedLessonIds = [];

    for (String id in _lessonOrder) {
      if (isLessonCompleted(id)) {
        completedLessonIds.add(id);
      }
    }

    // Get lesson data
    List<Lesson> completedLessons = [];
    for (String id in completedLessonIds) {
      Lesson? lesson = _lessons[id];
      if (lesson != null) {
        completedLessons.add(lesson);
      }
    }

    return completedLessons;
  }



  /// Get the next available lesson (for navigation)
  String? getNextAvailableLesson() {
    for (final lessonId in _lessonOrder) {
      if (!isLessonCompleted(lessonId)) {
        return lessonId;
      }
    }
    return null; // All lessons completed
  }

  /// Check if a lesson is unlocked (can be accessed)
  bool isLessonUnlocked(String lessonId) {
    final index = _lessonOrder.indexOf(lessonId);
    if (index == -1) return false;
    if (index == 0) return true; // First lesson is always unlocked

    // Check if previous lesson is completed
    final previousLessonId = _lessonOrder[index - 1];
    return isLessonCompleted(previousLessonId);
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}
