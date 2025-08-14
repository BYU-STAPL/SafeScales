import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/dragon_repository.dart';
import '../services/dragon_service.dart';
import '../providers/dragon_provider.dart';
import '../services/course_service.dart';
import '../services/user_state_service.dart';

/// Dependency injection container for dragon-related classes
/// This ensures proper dependency injection and makes testing easier
class DragonDependencies {
  late final DragonRepository _repository;
  late final DragonService _service;
  late final DragonProvider _provider;

  // External services (injected)
  final SupabaseClient supabase;
  final UserStateService userStateService;
  final CourseService courseService;

  DragonDependencies({
    required this.supabase,
    required this.userStateService,
    required this.courseService,
  }) {
    _initializeDependencies();
  }

  void _initializeDependencies() {
    // Repository layer - handles database access
    _repository = DragonRepository(supabase: supabase);

    // Service layer - handles business logic
    _service = DragonService(
      courseService: courseService,
      repository: _repository,
    );

    // Provider layer - handles UI state management
    _provider = DragonProvider(
      dragonService: _service,
      userState: userStateService,
      courseService: courseService,
    );
  }

  // Getters for accessing the instances
  DragonRepository get repository => _repository;
  DragonService get service => _service;
  DragonProvider get provider => _provider;

  /// Dispose method to clean up resources
  void dispose() {
    _provider.dispose();
  }
}

/// Factory method for creating DragonDependencies
/// Usage example in your app initialization:
///
/// ```dart
/// final dragonDeps = createDragonDependencies(
///   supabase: Supabase.instance.client,
///   userStateService: userStateService,
///   userProgressService: userProgressService,
///   classService: classService,
///   quizService: quizService,
/// );
///
/// // Use in your widget tree with ChangeNotifierProvider
/// ChangeNotifierProvider<DragonProvider>(
///   create: (_) => dragonDeps.provider,
///   child: MyApp(),
/// )
/// ```
DragonDependencies createDragonDependencies({
  required SupabaseClient supabase,
  required UserStateService userStateService,
  required CourseService courseService,
}) {
  return DragonDependencies(
    supabase: supabase,
    userStateService: userStateService,
    courseService: courseService,
  );
}
