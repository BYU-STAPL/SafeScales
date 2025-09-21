import 'package:safe_scales/models/sticker_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Repository responsible for all item-related database operations
/// This layer only handles data access - no business logic
class ItemRepository {
  final SupabaseClient _supabase;

  ItemRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;


  // ---------------- CREATE ----------------


  // ---------------- READ ----------------

  /// Get user's items and environments
  Future<List<dynamic>> fetchUserItemIDList(String userId) async {
    try {

      List<dynamic> acquiredItems = [];
      List<dynamic> acquiredEnvs = [];

      final response = await _supabase
          .from('Users')
          .select('acquired_accessories')
          .eq('id', userId)
          .single();

      if (response['acquired_accessories'] != null) {
        acquiredItems = response['acquired_accessories'];
      }

      final response2 = await _supabase
          .from('Users')
          .select('acquired_environments')
          .eq('id', userId)
          .single();

      if (response2['acquired_environments'] != null) {
        acquiredEnvs = response2['acquired_environments'];
      }

      List<dynamic> userItemAndEnvIds = acquiredItems + acquiredEnvs;

      // Returns a list with a string of ids ['long-id', 'long-id']
      return userItemAndEnvIds;
    }
    catch (e) {
      throw ItemRepositoryException('Error fetching user items: $e');
    }
  }

  /// Get class item assets
  Future<List<Map<String, dynamic>>> fetchClassAssets(String classId) async {
    try {
      final response = await _supabase
          .from('classes')
          .select('assets')
          .eq('id', classId)
          .single();

      return List<Map<String, dynamic>>.from(response['assets'] ?? []);
    } catch (e) {
      throw ItemRepositoryException('Failed to fetch class assets for $classId: $e');
    }
  }

  // ---------------- UPDATE ----------------

  // ---------------- DELETE ----------------

}

/// Custom exception for repository operations
class ItemRepositoryException implements Exception {
  final String message;

  ItemRepositoryException(this.message);

  @override
  String toString() => 'ItemRepositoryException: $message';
}