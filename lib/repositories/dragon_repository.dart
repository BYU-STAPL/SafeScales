import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Repository responsible for all dragon-related database operations
/// This layer only handles data access - no business logic
class DragonRepository {
  final SupabaseClient _supabase;

  // DragonRepository(this._supabase);

  DragonRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  // === Raw Dragon Data ===

  /// Fetch all dragons from the dragons table
  Future<List<Map<String, dynamic>>> fetchAllDragons() async {
    try {
      final response = await _supabase
          .from('dragons')
          .select()
          .order('id', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw DragonRepositoryException('Failed to fetch dragons: $e');
    }
  }

  // === User Dragon Data ===

  /// Get user's dragon progress and unlocked phases
  Future<Map<String, dynamic>> fetchUserDragons(String userId) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('dragons')
          .eq('id', userId)
          .single();

      return response['dragons'] ?? {};
    } catch (e) {
      throw DragonRepositoryException('Failed to fetch user dragons for $userId: $e');
    }
  }

  /// Get class assets (including dragon metadata)
  Future<List<Map<String, dynamic>>> fetchClassAssets(String classId) async {
    try {
      final response = await _supabase
          .from('classes')
          .select('assets')
          .eq('id', classId)
          .single();

      return List<Map<String, dynamic>>.from(response['assets'] ?? []);
    } catch (e) {
      throw DragonRepositoryException('Failed to fetch class assets for $classId: $e');
    }
  }

  /// Get user's current dragon environment
  Future<String?> fetchCurrentEnvironment(String userId) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('dragons')
          .eq('id', userId)
          .single();

      return response['dragons']?['current_dragon_env'];
    } catch (e) {
      throw DragonRepositoryException('Failed to fetch current environment for $userId: $e');
    }
  }

  // === Update Operations ===

  /// Update user's dragon phases
  Future<void> updateUserDragonPhases(String userId, String dragonId, List<String> phases) async {
    try {
      // Get current dragon data
      final currentData = await fetchUserDragons(userId);

      // Update specific dragon phases
      currentData[dragonId] = phases;

      // Save back to database
      await _supabase
          .from('Users')
          .update({'dragons': currentData})
          .eq('id', userId);
    } catch (e) {
      throw DragonRepositoryException('Failed to update dragon phases for $userId: $e');
    }
  }

  /// Update user's dragon environment
  Future<void> updateUserEnvironment(String userId, String environmentId, String dragonId) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('dragon_environments')
          .eq('id', userId)
          .single();

      print("DEBUG");
      print(response);

      response['dragon_environments'][dragonId] = environmentId;

      print(response);


      await _supabase
          .from('Users')
          .update({'dragon_environments': response['dragon_environments']})
          .eq('id', userId);

      /*
      final updatedData = <String, dynamic>{
        'current_dragon_env': environmentId,
        ...existingDragonPhases,
      };

      await _supabase
          .from('Users')
          .update({'dragons': updatedData})
          .eq('id', userId);
       */
    } catch (e) {
      throw DragonRepositoryException('Failed to update environment for $userId: $e');
    }
  }

  /// Save multiple dragon phases at once
  Future<void> saveAllUserDragonPhases(String userId, Map<String, List<String>> dragonPhases, {String? environment}) async {
    try {
      final data = <String, dynamic>{...dragonPhases};

      if (environment != null) {
        data['current_dragon_env'] = environment;
      }

      await _supabase
          .from('Users')
          .update({'dragons': data})
          .eq('id', userId);
    } catch (e) {
      throw DragonRepositoryException('Failed to save dragon phases for $userId: $e');
    }
  }
}

/// Custom exception for repository operations
class DragonRepositoryException implements Exception {
  final String message;
  DragonRepositoryException(this.message);

  @override
  String toString() => 'DragonRepositoryException: $message';
}