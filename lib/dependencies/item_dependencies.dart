import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/item_repository.dart';
import '../services/item_service.dart';
import '../services/user_state_service.dart';
import '../providers/item_provider.dart';

/// Dependency injection container for item-related classes
/// This ensures proper dependency injection and makes testing easier
class ItemDependencies {
  late final ItemRepository _repository;
  late final ItemService _service;
  late final ItemProvider _provider;

  // External services (injected)
  final SupabaseClient supabase;
  final UserStateService userStateService;

  ItemDependencies({
    required this.supabase,
    required this.userStateService,
  }) {
    _initializeDependencies();
  }

  void _initializeDependencies() {
    // Repository layer - handles database access
    _repository = ItemRepository(supabase: supabase);

    // Service layer - handles business logic
    _service = ItemService(repository: _repository);

    // Provider layer - handles UI state management
    _provider = ItemProvider(itemService: _service);
  }

  // Getters for accessing the instances
  ItemRepository get repository => _repository;
  ItemService get service => _service;
  ItemProvider get provider => _provider;

  /// Dispose method to clean up resources
  void dispose() {
    _provider.dispose();
  }
}

/// Factory method for creating ItemDependencies
/// Usage example in your app initialization:
///
/// ```dart
/// final itemDeps = createItemDependencies(
///   supabase: Supabase.instance.client,
///   userStateService: userStateService,
/// );
///
/// // Use in your widget tree with ChangeNotifierProvider
/// ChangeNotifierProvider<ItemProvider>(
///   create: (_) => itemDeps.provider,
///   child: MyApp(),
/// )
/// ```
ItemDependencies createItemDependencies({
  required SupabaseClient supabase,
  required UserStateService userStateService,
}) {
  return ItemDependencies(
    supabase: supabase,
    userStateService: userStateService,
  );
}