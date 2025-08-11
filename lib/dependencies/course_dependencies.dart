import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/course_repository.dart';
import '../services/course_service.dart';
import '../services/user_state_service.dart';
import '../providers/course_provider.dart';

/// Dependency injection container for course-related classes
/// This ensures proper dependency injection and makes testing easier
class CourseDependencies {
  late final CourseRepository _repository;
  late final CourseService _service;
  late final CourseProvider _provider;

  // External services (injected)
  final SupabaseClient supabase;
  final UserStateService userStateService;

  CourseDependencies({
    required this.supabase,
    required this.userStateService,
  }) {
    _initializeDependencies();
  }

  void _initializeDependencies() {
    // Repository layer - handles database access
    _repository = CourseRepository(supabase: supabase);

    // Service layer - handles business logic
    _service = CourseService(repository: _repository);

    // Provider layer - handles UI state management
    _provider = CourseProvider(
      courseService: _service,
      userStateService: userStateService,
    );
  }

  // Getters for accessing the instances
  CourseRepository get repository => _repository;
  CourseService get service => _service;
  CourseProvider get provider => _provider;

  /// Dispose method to clean up resources
  void dispose() {
    _provider.dispose();
  }
}

/// Factory method for creating CourseDependencies
/// Usage example in your app initialization:
///
/// ```dart
/// final courseDeps = createCourseDependencies(
///   supabase: Supabase.instance.client,
///   userStateService: userStateService,
/// );
///
/// // Use in your widget tree with ChangeNotifierProvider
/// ChangeNotifierProvider<CourseProvider>(
///   create: (_) => courseDeps.provider,
///   child: MyApp(),
/// )
/// ```
///
/// Or for a specific screen:
/// ```dart
/// class CourseScreen extends StatefulWidget {
///   @override
///   _CourseScreenState createState() => _CourseScreenState();
/// }
///
/// class _CourseScreenState extends State<CourseScreen> {
///   late CourseDependencies _courseDeps;
///
///   @override
///   void initState() {
///     super.initState();
///     _courseDeps = createCourseDependencies(
///       supabase: Supabase.instance.client,
///       userStateService: UserStateService(),
///     );
///     _courseDeps.provider.initialize();
///   }
///
///   @override
///   void dispose() {
///     _courseDeps.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ChangeNotifierProvider<CourseProvider>.value(
///       value: _courseDeps.provider,
///       child: Consumer<CourseProvider>(
///         builder: (context, provider, child) {
///           // Your UI code here
///           return Scaffold(/* ... */);
///         },
///       ),
///     );
///   }
/// }
/// ```
CourseDependencies createCourseDependencies({
  required SupabaseClient supabase,
  required UserStateService userStateService,
}) {
  return CourseDependencies(
    supabase: supabase,
    userStateService: userStateService,
  );
}

// /// Alternative: Global app-level dependencies manager
// /// Use this if you want to manage multiple feature dependencies centrally
// class AppDependencies {
//   final SupabaseClient supabase;
//   final UserStateService userStateService;
//
//   late final CourseDependencies course;
//   // Add other feature dependencies here
//   // late final DragonDependencies dragon;
//   // late final UserDependencies user;
//
//   AppDependencies({
//     required this.supabase,
//     required this.userStateService,
//   }) {
//     _initializeAllDependencies();
//   }
//
//   void _initializeAllDependencies() {
//     course = CourseDependencies(
//       supabase: supabase,
//       userStateService: userStateService,
//     );
//
//     // Initialize other feature dependencies
//     // dragon = DragonDependencies(...);
//     // user = UserDependencies(...);
//   }
//
//   void dispose() {
//     course.dispose();
//     // Dispose other dependencies
//   }
// }
//
// /// Factory for creating app-wide dependencies
// AppDependencies createAppDependencies({
//   required SupabaseClient supabase,
//   required UserStateService userStateService,
// }) {
//   return AppDependencies(
//     supabase: supabase,
//     userStateService: userStateService,
//   );
// }