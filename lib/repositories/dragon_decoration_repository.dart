import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/services/activity_event_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DragonDecorationRepository {
  final SupabaseClient _supabase;
  late final ActivityEventService _activityEvents;

  DragonDecorationRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseConfig.client {
    _activityEvents = ActivityEventService(supabase: _supabase);
  }

  // ---------------- CREATE ----------------

  // ---------------- READ ----------------

  /// Load current user selected environment
  Future<({String? environmentId, bool hasSavedSelection})>
  loadCurrentDragonEnvironment(String userId, String dragonId) async {
    try {
      final response =
          await _supabase
              .from('Users')
              .select('dragon_environments')
              .eq('id', userId)
              .single();

      final rawSelections = response['dragon_environments'];
      final selections =
          rawSelections is Map
              ? Map<String, dynamic>.from(rawSelections)
              : <String, dynamic>{};
      if (!selections.containsKey(dragonId)) {
        return (environmentId: null, hasSavedSelection: false);
      }

      final rawEnvironmentId = selections[dragonId];
      return (
        environmentId:
            rawEnvironmentId is String && rawEnvironmentId.isNotEmpty
                ? rawEnvironmentId
                : null,
        hasSavedSelection: true,
      );
    } catch (e) {
      throw DragonDecorationRepositoryException(
        'Failed to load current dragon environment for $dragonId: $e',
      );
    }
  }

  /// Load dragon dress-up data for a specific user and dragon
  Future<Map<String, dynamic>?> loadDragonDressUp({
    required String userId,
    required String dragonId,
  }) async {
    try {
      final userResponse =
          await _supabase
              .from('Users')
              .select('dragon_dressup')
              .eq('id', userId)
              .single();

      final Map<String, dynamic>? dressUpData =
          userResponse['dragon_dressup'] != null
              ? Map<String, dynamic>.from(userResponse['dragon_dressup'])
              : null;

      if (dressUpData != null && dressUpData.containsKey(dragonId)) {
        return Map<String, dynamic>.from(dressUpData[dragonId]);
      }

      return null;
    } catch (e) {
      throw DragonDecorationRepositoryException(
        'Failed to load dragon dress-up for $dragonId: $e',
      );
    }
  }

  // ---------------- UPDATE ----------------

  /// Save the new chosen environment
  Future<void> updateUserEnvironment(
    String userId,
    String environmentId,
    String dragonId,
  ) async {
    try {
      final response =
          await _supabase
              .from('Users')
              .select('dragon_environments')
              .eq('id', userId)
              .single();

      final rawSelections = response['dragon_environments'];
      final selections =
          rawSelections is Map
              ? Map<String, dynamic>.from(rawSelections)
              : <String, dynamic>{};
      final previousEnvironment = selections[dragonId]?.toString();

      if (environmentId == "") {
        selections[dragonId] = null;
      } else {
        selections[dragonId] = environmentId;
      }

      await _supabase
          .from('Users')
          .update({'dragon_environments': selections})
          .eq('id', userId);

      await _activityEvents.recordBestEffort(
        userId: userId,
        eventType: environmentId.isEmpty ? 'habitat_reset' : 'habitat_changed',
        contextType: 'dragon',
        contextId: dragonId,
        details: {
          'previous_habitat_id': previousEnvironment,
          'habitat_id': environmentId.isEmpty ? null : environmentId,
        },
      );
    } catch (e) {
      throw DragonDecorationRepositoryException(
        'Failed to update environment for $userId: $e',
      );
    }
  }

  /// Save dragon dress-up data for a specific user and dragon
  Future<bool> saveDragonDressUp({
    required String userId,
    required String dragonId,
    required Map<String, dynamic> accessoriesData,
  }) async {
    try {
      // Get current dragon_dressup data
      final userResponse =
          await _supabase
              .from('Users')
              .select('dragon_dressup')
              .eq('id', userId)
              .single();

      final Map<String, dynamic> dressUpData =
          userResponse['dragon_dressup'] != null
              ? Map<String, dynamic>.from(userResponse['dragon_dressup'])
              : <String, dynamic>{};
      final previousAccessoryIds =
          dressUpData[dragonId] is Map
              ? Map<String, dynamic>.from(dressUpData[dragonId]).keys.toList()
              : <String>[];
      final currentAccessoryIds = accessoriesData.keys.toList();
      final accessorySetChanged =
          previousAccessoryIds.length != currentAccessoryIds.length ||
          !previousAccessoryIds.every(accessoriesData.containsKey);

      // Update data for this dragon
      dressUpData[dragonId] = accessoriesData;

      // Save back to database
      await _supabase
          .from('Users')
          .update({'dragon_dressup': dressUpData})
          .eq('id', userId);

      if (accessorySetChanged) {
        await _activityEvents.recordBestEffort(
          userId: userId,
          eventType:
              accessoriesData.isEmpty
                  ? 'habitat_decorations_reset'
                  : 'dragon_decorations_changed',
          contextType: 'dragon',
          contextId: dragonId,
          details: {
            'previous_accessory_ids': previousAccessoryIds,
            'accessory_ids': currentAccessoryIds,
            'decoration_count': accessoriesData.length,
          },
        );
      }

      return true;
    } catch (e) {
      print('❌ Error saving dragon dress-up: $e');
      return false;
    }
  }

  // ---------------- DELETE ----------------

  /// Clear all dress-up data for a specific dragon
  Future<bool> clearDragonDressUp({
    required String userId,
    required String dragonId,
  }) async {
    try {
      // Get current dragon_dressup data
      final userResponse =
          await _supabase
              .from('Users')
              .select('dragon_dressup')
              .eq('id', userId)
              .single();

      final Map<String, dynamic> dressUpData =
          userResponse['dragon_dressup'] != null
              ? Map<String, dynamic>.from(userResponse['dragon_dressup'])
              : <String, dynamic>{};
      final previousAccessoryIds =
          dressUpData[dragonId] is Map
              ? Map<String, dynamic>.from(dressUpData[dragonId]).keys.toList()
              : <String>[];

      // Keep an empty record so a user's explicit clear is not mistaken for
      // a dragon that has never had a decoration selection.
      dressUpData[dragonId] = <String, dynamic>{};

      // Save back to database
      await _supabase
          .from('Users')
          .update({'dragon_dressup': dressUpData})
          .eq('id', userId);

      await _activityEvents.recordBestEffort(
        userId: userId,
        eventType: 'habitat_decorations_reset',
        contextType: 'dragon',
        contextId: dragonId,
        details: {
          'previous_accessory_ids': previousAccessoryIds,
          'decoration_count': 0,
        },
      );

      return true;
    } catch (e) {
      print('❌ Error clearing dragon dress-up: $e');
      return false;
    }
  }
}

class DragonDecorationRepositoryException implements Exception {
  final String message;
  DragonDecorationRepositoryException(this.message);

  @override
  String toString() => 'DragonDecorationRepositoryException: $message';
}
