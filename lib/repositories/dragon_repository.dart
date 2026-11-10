import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../services/activity_event_service.dart';

/// Repository responsible for all dragon-related database operations
/// This layer only handles data access - no business logic
class DragonRepository {
  final SupabaseClient _supabase;
  late final ActivityEventService _activityEvents;

  // DragonRepository(this._supabase);

  DragonRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseConfig.client {
    _activityEvents = ActivityEventService(supabase: _supabase);
  }

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
      final response =
          await _supabase
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
      final response =
          await _supabase
              .from('Users')
              .select('dragon_preferred_phases')
              .eq('id', userId)
              .single();

      final phases = Map<String, String>.from(
        response['dragon_preferred_phases'] ?? {},
      );

      return phases;
    } catch (e) {
      throw DragonRepositoryException(
        'Failed to get preferred phases for user $userId: $e',
      );
    }
  }

  // ---------------- UPDATE ----------------

  /// Update user's dragon phases
  Future<void> updateUserDragonPhases(
    String userId,
    String dragonId,
    List<String> phases,
  ) async {
    try {
      // Get current dragon data
      final currentData = await fetchUserDragons(userId);
      final existingDragon = currentData[dragonId];
      final existingPhases =
          existingDragon is Map && existingDragon['phases'] is List
              ? List<String>.from(existingDragon['phases'])
              : existingDragon is List
              ? List<String>.from(existingDragon)
              : <String>[];
      final newlyUnlockedPhases =
          phases.where((phase) => !existingPhases.contains(phase)).toList();

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

      for (final phase in newlyUnlockedPhases) {
        await _activityEvents.recordBestEffort(
          userId: userId,
          eventType: 'dragon_phase_unlocked',
          contextType: 'dragon',
          contextId: dragonId,
          details: {'phase': phase},
        );
      }
    } catch (e) {
      throw DragonRepositoryException(
        'Failed to update dragon phases for $userId: $e',
      );
    }
  }

  // Update preferred dragon phase
  Future<void> updateUserPreferredPhase(
    String userId,
    String dragonId,
    String phase,
  ) async {
    try {
      final response =
          await _supabase
              .from('Users')
              .select('dragon_preferred_phases')
              .eq('id', userId)
              .single();

      if (response['dragon_preferred_phases'] == null) {
        response['dragon_preferred_phases'] = {};
      }

      final preferredPhase = phase.isEmpty ? 'final' : phase;
      final previousPhase =
          response['dragon_preferred_phases'][dragonId]?.toString();
      response['dragon_preferred_phases'][dragonId] = preferredPhase;

      await _supabase
          .from('Users')
          .update({
            'dragon_preferred_phases': response['dragon_preferred_phases'],
          })
          .eq('id', userId);

      await _activityEvents.recordBestEffort(
        userId: userId,
        eventType: 'dragon_phase_changed',
        contextType: 'dragon',
        contextId: dragonId,
        details: {'previous_phase': previousPhase, 'phase': preferredPhase},
      );
    } catch (e) {
      throw DragonRepositoryException(
        'Failed to update preferred phase for user $userId & dragon ${dragonId}: $e',
      );
    }
  }

  /// Update dragon name in the user's dragons data
  Future<void> updateDragonName(
    String userId,
    String dragonId,
    String newName,
  ) async {
    try {
      // Get current dragon data
      final currentData = await fetchUserDragons(userId);
      final dragonData = currentData[dragonId];
      final previousName =
          dragonData is Map ? dragonData['name']?.toString() : null;

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

      await _activityEvents.recordBestEffort(
        userId: userId,
        eventType: 'dragon_name_changed',
        contextType: 'dragon',
        contextId: dragonId,
        details: {'previous_name': previousName, 'name': newName},
      );
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
