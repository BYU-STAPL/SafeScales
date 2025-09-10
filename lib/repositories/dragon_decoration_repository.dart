import 'package:safe_scales/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DragonDecorationRepository {
  final SupabaseClient _supabase;

  DragonDecorationRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

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

  /// Load dragon dress-up data for a specific user and dragon
  Future<Map<String, dynamic>?> loadDragonDressUp({
    required String userId,
    required String dragonId,
  }) async {
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