import 'package:safe_scales/repositories/shop_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/shop_provider.dart';
import '../services/shop_service.dart';
import '../services/user_state_service.dart';

class ShopDependencies {
  late final ShopRepository _repository;
  late final ShopService _service;
  late final ShopProvider _provider;

  // External services (injected)
  final SupabaseClient supabase;
  final UserStateService userStateService;

  ShopDependencies({
    required this.supabase,
    required this.userStateService,
  }) {
    _initializeDependencies();
  }


  void _initializeDependencies() {
    // Repository layer - handles database access
    _repository = ShopRepository(supabase: supabase);

    // Service layer - handles business logic
    _service = ShopService(repository: _repository);

    // Provider layer - handles UI state management
    _provider = ShopProvider(shopService: _service);
  }

  // Getters for accessing the instances
  ShopRepository get repository => _repository;
  ShopService get service => _service;
  ShopProvider get provider => _provider;

  /// Dispose method to clean up resources
  void dispose() {
    _provider.dispose();
  }

}