import 'package:provider/provider.dart';
import 'package:safe_scales/services/course_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/class_service.dart';
import '../services/quiz_service.dart';
import '../services/user_state_service.dart';
import '../state_management/course_provider.dart';
import '../state_management/dragon_provider.dart';
import 'course_dependencies.dart';
import 'dragon_dependencies.dart';

/// Global app-level dependencies manager
/// Centralizes all feature dependencies and shared services
class AppDependencies {
  // === Shared Services ===
  final SupabaseClient supabase;
  final UserStateService userStateService;
  final CourseService courseService;
  final ClassService classService;

  // === Feature Dependencies ===
  late final CourseDependencies course;
  late final DragonDependencies dragon;

  // === Future Feature Dependencies ===
  // Add more feature dependencies here as your app grows
  // late final UserProfileDependencies userProfile;
  // late final AnalyticsDependencies analytics;
  // late final NotificationDependencies notifications;

  AppDependencies({
    required this.supabase,
    required this.userStateService,
    required this.courseService,
    required this.classService,
  }) {
    _initializeAllDependencies();
  }

  void _initializeAllDependencies() {
    // Initialize course dependencies
    course = CourseDependencies(
      supabase: supabase,
      userStateService: userStateService,
    );


    // Initialize dragon dependencies
    dragon = DragonDependencies(
      supabase: supabase,
      userStateService: userStateService,
      courseService: courseService,
      classService: classService,
    );

    // Initialize future feature dependencies here
    // userProfile = UserProfileDependencies(...);
    // analytics = AnalyticsDependencies(...);
    // notifications = NotificationDependencies(...);
  }

  /// Initialize all providers that need async initialization
  Future<void> initializeProviders() async {
    final List<Future<void>> initializationTasks = [];

    try {
      // Initialize course provider
      initializationTasks.add(course.provider.initialize());
      course.provider.loadCourseContent();
      course.provider.loadUserProgress();

      // Initialize dragon provider
      initializationTasks.add(dragon.provider.initialize());
      dragon.provider.loadUserDragons();

      // You can add other provider initializations here
      // initializationTasks.add(userProfile.provider.initialize());

      // Wait for all initializations to complete
      await Future.wait(initializationTasks);

      print("✅ All providers initialized successfully");
      print("📚 Course Provider - Lessons: ${course.provider.lessons.length}");
      print("📚 Course Provider - Class: ${course.provider.className}");
      print("🐉 Dragon Provider initialized");
    } catch (e) {
      print("❌ Provider initialization failed: $e");
      rethrow; // Re-throw to handle in main.dart if needed
    }
  }

  /// Get all providers for MultiProvider setup
  List<ChangeNotifierProvider> getProviders() {
    return [
      ChangeNotifierProvider<CourseProvider>.value(
        value: course.provider,
      ),
      ChangeNotifierProvider<DragonProvider>.value(
        value: dragon.provider,
      ),
      // Add future providers here
      // ChangeNotifierProvider<UserProfileProvider>.value(
      //   value: userProfile.provider,
      // ),
      // ChangeNotifierProvider<AnalyticsProvider>.value(
      //   value: analytics.provider,
      // ),
    ];
  }

  /// Dispose all dependencies
  void dispose() {
    course.dispose();
    dragon.dispose();
    // Dispose future dependencies
    // userProfile.dispose();
    // analytics.dispose();
    // notifications.dispose();
  }

  /// Health check - verify all dependencies are properly initialized
  bool get isHealthy {
    try {
      // Check if all core dependencies are available
      final checks = [
        supabase.auth.currentUser != null || supabase.auth.currentSession == null, // Auth is in valid state
        course.provider != null,
        dragon.provider != null,
        // Add more health checks as needed
      ];

      return checks.every((check) => check == true);
    } catch (e) {
      print("❌ Health check failed: $e");
      return false;
    }
  }
}

/// Factory for creating app-wide dependencies
/// This replaces your manual dependency creation in main.dart
AppDependencies createAppDependencies({
  required SupabaseClient supabase,
  UserStateService? userStateService,
  CourseService? courseService,
  ClassService? classService,
  QuizService? quizService,
}) {
  return AppDependencies(
    supabase: supabase,
    userStateService: userStateService ?? UserStateService(),
    courseService: courseService ?? CourseService(),
    classService: classService ?? ClassService(supabase),
  );
}

/// Simplified factory that creates all services automatically
/// Use this for the cleanest main.dart setup
AppDependencies createAppDependenciesFromSupabase(SupabaseClient supabase) {
  // Create all shared services
  final userStateService = UserStateService();
  final courseService = CourseService();
  final classService = ClassService(supabase);

  return AppDependencies(
    supabase: supabase,
    userStateService: userStateService,
    courseService: courseService,
    classService: classService,
  );
}