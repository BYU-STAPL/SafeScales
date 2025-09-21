import 'package:safe_scales/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DragonDecorationRepository {
  final SupabaseClient _supabase;

  DragonDecorationRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  // ---------------- CREATE ----------------


  // ---------------- READ ----------------

  /// Load current user selected environment
  Future<String> loadCurrentDragonEnvironment(String userId, String dragonId) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('dragon_environments')
          .eq('id', userId)
          .single();

      return response['dragon_environments']?[dragonId] ?? "";
    }
    catch (e) {
      print('❌ Error loading current dragon environment for dragon ${dragonId}: $e');
      return "";
    }
  }

  /// Load dragon dress-up data for a specific user and dragon
  Future<Map<String, dynamic>?> loadDragonDressUp({required String userId, required String dragonId,}) async {
    try {
      final userResponse = await _supabase
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
      print('❌ Error loading dragon dress-up: $e');
      return null;
    }
  }


  // ---------------- UPDATE ----------------

  /// Save the new chosen environment
  Future<void> updateUserEnvironment(String userId, String environmentId, String dragonId) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('dragon_environments')
          .eq('id', userId)
          .single();

      if (response['dragon_environments'] == null) {
        response['dragon_environments'] = {};
      }

      if (environmentId == "") {
        response['dragon_environments'][dragonId] = null;
      }
      else {
        response['dragon_environments'][dragonId] = environmentId;
      }

      await _supabase
          .from('Users')
          .update({'dragon_environments': response['dragon_environments']})
          .eq('id', userId);

    } catch (e) {
      throw DragonDecorationRepositoryException('Failed to update environment for $userId: $e');
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
      final userResponse = await _supabase
          .from('Users')
          .select('dragon_dressup')
          .eq('id', userId)
          .single();

      final Map<String, dynamic> dressUpData =
      userResponse['dragon_dressup'] != null
          ? Map<String, dynamic>.from(userResponse['dragon_dressup'])
          : <String, dynamic>{};

      // Update data for this dragon
      dressUpData[dragonId] = accessoriesData;

      // Save back to database
      await _supabase
          .from('Users')
          .update({'dragon_dressup': dressUpData})
          .eq('id', userId);

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
      final userResponse = await _supabase
          .from('Users')
          .select('dragon_dressup')
          .eq('id', userId)
          .single();

      final Map<String, dynamic> dressUpData =
      userResponse['dragon_dressup'] != null
          ? Map<String, dynamic>.from(userResponse['dragon_dressup'])
          : <String, dynamic>{};

      // Remove data for this dragon
      dressUpData.remove(dragonId);

      // Save back to database
      await _supabase
          .from('Users')
          .update({'dragon_dressup': dressUpData})
          .eq('id', userId);

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