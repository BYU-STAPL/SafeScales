import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/dragon_repository.dart';
import '../services/dragon_service.dart';
import '../state_management/dragon_provider.dart';
import '../services/class_service.dart';
import '../services/user_progress_service.dart';
import '../services/user_state_service.dart';
import '../services/quiz_service.dart';

/// Dependency injection container for dragon-related classes
/// This ensures proper dependency injection and makes testing easier
class DragonDependencies {
  late final DragonRepository _repository;
  late final DragonService _service;
  late final DragonProvider _provider;

  // External services (injected)
  final SupabaseClient supabase;
  final UserStateService userStateService;
  final UserProgressService userProgressService;
  final ClassService classService;
  final QuizService quizService;

  DragonDependencies({
    required this.supabase,
    required this.userStateService,
    required this.userProgressService,
    required this.classService,
    required this.quizService,
  }) {
    _initializeDependencies();
  }

  void _initializeDependencies() {
    // Repository layer - handles database access
    _repository = DragonRepository(supabase);

    // Service layer - handles business logic
    _service = DragonService(_repository);

    // Provider layer - handles UI state management
    _provider = DragonProvider(
      dragonService: _service,
      userState: userStateService,
      userProgressService: userProgressService,
      classService: classService,
      quizService: quizService,
    );
  }

  // Getters for accessing the instances
  DragonRepository get repository => _repository;
  DragonService get service => _service;
  DragonProvider get provider => _provider;
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
  required UserProgressService userProgressService,
  required ClassService classService,
  required QuizService quizService,
}) {
  return DragonDependencies(
    supabase: supabase,
    userStateService: userStateService,
    userProgressService: userProgressService,
    classService: classService,
    quizService: quizService,
  );
}