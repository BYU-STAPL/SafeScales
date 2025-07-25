
import 'package:flutter/cupertino.dart';

import '../models/lesson.dart';
import '../services/class_service.dart';
import '../services/quiz_service.dart';
import '../services/user_state_service.dart';

class CourseProvider extends ChangeNotifier {

  // === Data ===
  bool _isLoading = false;

  List<String> _unlockedLessons = []; // lessonIds
  Map<String, double> _lessonProgress = {}; // lessonIds -> progress percentage (0-100)
  Map<String, Map<String, dynamic>> _quizScores = {}; // lessonId -> quizId: int or double

  Map<String, Lesson> _lessons = {}; // Map for quick access to a lesson
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


  // === Helper Methods ===
  void _clearData() {
    _lessonProgress = {};
    _quizScores = {};
    _unlockedLessons = [];
    _lessons = {};
    _lessonOrder = [];
  }

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

      // Get class lessons
      _lessons = await _classService.getLessons(classData['id']);

      _lessonOrder = await _classService.getLessonOrder(classData['id']);

      // Get User's Progress for each lesson
      _lessonProgress = await _quizService.getModuleProgress(
        userId: user.id,
        moduleIds: _lessonOrder,
      );


      Map<String, List<List<int>>> tempQuizProgress = await _quizService.loadQuizScores(user.id);

      // print(tempQuizProgress);
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

}
