
import 'package:flutter/cupertino.dart';
import 'package:safe_scales/services/user_progress_service.dart';

import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import '../models/user.dart';
import '../services/class_service.dart';
import '../services/quiz_service.dart';
import '../services/user_state_service.dart';

class CourseProvider extends ChangeNotifier {

  // === Data ===
  bool _isLoading = false;


  String _className = '';
  String _description = '';
  List<String> _unlockedLessons = []; // lessonIds
  Map<String, LessonProgress> _lessonProgress = {}; //Map for access to lesson progress
  Map<String, Lesson> _lessons = {}; // Map for quick access to lesson content
  List<String> _lessonOrder = []; // All lessonId's in order

  // === Services ===
  final UserStateService _userState = UserStateService();
  final UserProgressService _userProgressService = UserProgressService();
  // final QuizService _quizService = QuizService();
  late final ClassService _classService;

  // === User ===
  late User _user;

  CourseProvider() {
    _classService = ClassService(_userProgressService.supabase);
    if (_userState.currentUser != null) {
      _user = _userState.currentUser!;
    }
  }

  Future<void> initialize() async {
    await loadUser();
    await loadClassContent();
    await loadUserProgress();
  }


  // === GETTERS ===
  bool get isLoading => _isLoading;

  String get className => _className;
  String get description => _description;

  List<String> get unlockedLessons => _unlockedLessons;
  Map<String, LessonProgress> get lessonProgress => _lessonProgress;
  Map<String, Lesson> get lessons => _lessons;
  List<String> get lessonOrder => _lessonOrder;


  // === Helper Methods ===
  void _clearData() {
    _className = '';
    _lessonProgress = {};
    _unlockedLessons = [];
    _lessons = {};
    _lessonOrder = [];
  }

  // === Load User ===
  Future<void> loadUser() async {
    if (_userState.currentUser == null) {
      _clearData();
      _isLoading = false;
      notifyListeners();
      return;
    }

    _user = _userState.currentUser!;
  }


  // === Load Class Content
  Future<void> loadClassContent() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get user's class
      final classData = await _classService.getUserClass(_user.id);
      if (classData.isEmpty) {
        _clearData();
        _isLoading = false;
        notifyListeners();
        return;
      }

      _className = classData['name'];
      _description = classData['description'];

      // Get class lessons
      _lessons = await _classService.getLessons(classData['id']);

      _lessonOrder = await _classService.getLessonOrder(classData['id']);

      _isLoading = false;
      notifyListeners();

    } catch (e) {
      print('❌ CourseProgressProvider: Error loading lesson content: $e');
      _isLoading = false;
      notifyListeners();
    }
  }


  // === Load Progress ===
  Future<void> loadUserProgress() async {
    try {
      _isLoading = true;
      notifyListeners();

      _lessonProgress = await _userProgressService.loadLessonProgress(_user.id);

      // // Calculate unlocked content based on progress
      // _calculateUnlockedContent();

      _isLoading = false;
      notifyListeners();

    }
    catch (e) {
      print('❌ CourseProgressProvider: Error loading user progress: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // === Load individual lesson Progress
  Future<void> loadSingleLessonProgress(String lessonId) async {
    try {
      _isLoading = true;
      notifyListeners();

      LessonProgress? updatedLesson = await _userProgressService.loadSingleLessonProgress(_user.id, lessonId);

      if (updatedLesson != null) {
        _lessonProgress[lessonId] = updatedLesson;
        print(updatedLesson.lessonId);
        print(updatedLesson.preQuizAttempt);
        print(updatedLesson.isReadingComplete);
        print(updatedLesson.postQuizAttempts[0].correctAnswers);
      }

      _isLoading = false;
      notifyListeners();

    }
    catch (e) {
      print('❌ CourseProgressProvider: Error loading progress for $lessonId: $e');
      _isLoading = false;
      notifyListeners();
    }

  }


  // === Save individual lesson Progress


}
