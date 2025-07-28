
import 'package:flutter/cupertino.dart';

import '../models/lesson.dart';
import '../models/lesson_progress.dart';
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
  final QuizService _quizService = QuizService();
  late final ClassService _classService;


  CourseProvider() {
    _classService = ClassService(_quizService.supabase);
  }

  Future<void> initialize() async {
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

  // === Load Class Content


  // === Load Progress ===
  Future<void> loadUserProgress() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _userState.currentUser;
      if (user == null) {
        _clearData();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get user's class
      final classData = await _classService.getUserClass(user.id);
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

      _lessonProgress = await _quizService.loadLessonProgress(user.id);


      // // Load quiz scores
      // await _loadQuizScores(user.id);
      //
      // // Calculate unlocked content based on progress
      // _calculateUnlockedContent();

      _isLoading = false;
      notifyListeners();

    } catch (e) {
      print('❌ CourseProgressProvider: Error loading user progress: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // === Load individual lesson Progress

  // === Save individual lesson Progress


}
