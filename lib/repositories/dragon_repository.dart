import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Repository responsible for all dragon-related database operations
/// This layer only handles data access - no business logic
class DragonRepository {
  final SupabaseClient _supabase;

  // DragonRepository(this._supabase);

  DragonRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseConfig.client;


  // ---------------- CREATE ----------------


  // ---------------- READ ----------------


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
      throw DragonRepositoryException(
        'Failed to fetch user dragons for $userId: $e',
      );
    }
  }

  /// Get class assets (including dragon metadata)
  Future<List<Map<String, dynamic>>> fetchClassAssets(String classId) async {
    try {
      final response =
      await _supabase
          .from('classes')
          .select('assets')
          .eq('id', classId)
          .single();

      return List<Map<String, dynamic>>.from(response['assets'] ?? []);
    } catch (e) {
      throw DragonRepositoryException(
        'Failed to fetch class assets for $classId: $e',
      );
    }
  }

  /// Get user's current dragon environment
  Future<String?> fetchCurrentEnvironment(String userId) async {
    try {
      final response =
      await _supabase
          .from('Users')
          .select('dragons')
          .eq('id', userId)
          .single();

      return response['dragons']?['current_dragon_env'];
    } catch (e) {
      throw DragonRepositoryException(
        'Failed to fetch current environment for $userId: $e',
      );
    }
  }

  /// Get preferred phases for dragons
  Future<Map<String, String>> fetchUserPreferredPhases(String userId) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('dragon_preferred_phases')
          .eq('id', userId)
          .single();

      final phases = Map<String, String>.from(
        response['dragon_preferred_phases'] ?? {},
      );

      return phases;
    }
    catch (e) {
      throw DragonRepositoryException('Failed to get preferred phases for user $userId: $e');
    }
  }


  // ---------------- UPDATE ----------------

  /// Update user's dragon phases
  Future<void> updateUserDragonPhases(String userId, String dragonId, List<String> phases) async {
    try {
      // Get current dragon data
      final currentData = await fetchUserDragons(userId);

      // Update specific dragon phases

      // Create a default dragon set up
      if (currentData[dragonId] == null) {
        currentData[dragonId] = {
          'name': 'no name',
          'phases': ['egg'],
        };
      }

      currentData[dragonId]["phases"] = phases;

      // Save back to database
      await _supabase
          .from('Users')
          .update({'dragons': currentData})
          .eq('id', userId);

    } catch (e) {
      throw DragonRepositoryException('Failed to update dragon phases for $userId: $e');
    }
  }

  // Update preferred dragon phase
  Future<void> updateUserPreferredPhase(String userId, String dragonId, String phase) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('dragon_preferred_phases')
          .eq('id', userId)
          .single();

      if (response['dragon_preferred_phases'] == null) {
        response['dragon_preferred_phases'] = {};
      }

      if (phase == "") {
        response['dragon_preferred_phases'][dragonId] = "final";
      }
      else {
        response['dragon_preferred_phases'][dragonId] = phase;
      }

      await _supabase
          .from('Users')
          .update({'dragon_preferred_phases': response['dragon_preferred_phases']})
          .eq('id', userId);

    }
    catch (e) {
      throw DragonRepositoryException('Failed to update preferred phase for user $userId & dragon ${dragonId}: $e');
    }
  }

  /// Update dragon name in the user's dragons data
  Future<void> updateDragonName(String userId, String dragonId, String newName,) async {
    try {
      // Get current dragon data
      final currentData = await fetchUserDragons(userId);

      // Update dragon name
      if (currentData[dragonId] is List) {
        // Convert the list to a map to store additional data
        currentData[dragonId] = {
          'phases': currentData[dragonId],
          'name': newName,
        };
      } else if (currentData[dragonId] is Map) {
        // Update existing map
        currentData[dragonId]['name'] = newName;
      }

      // Save back to database
      await _supabase
          .from('Users')
          .update({'dragons': currentData})
          .eq('id', userId);

    } catch (e) {
      throw DragonRepositoryException(
        'Failed to update dragon name for $userId: $e',
      );
    }
  }


  // ---------------- DELETE ----------------


}

/// Custom exception for repository operations
class DragonRepositoryException implements Exception {
  final String message;
  DragonRepositoryException(this.message);

  @override
  String toString() => 'DragonRepositoryException: $message';
}
