import 'package:safe_scales/models/sticker_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Repository responsible for all item-related database operations
/// This layer only handles data access - no business logic
class ItemRepository {
  final SupabaseClient _supabase;

  ItemRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  // === Raw Item Data ===

  /// Fetch all items from the accessories table
  // Future<List<Map<String, dynamic>>> fetchAllItems() async {
  //   try {
  //     final response = await _supabase
  //         .from('dragons')
  //         .select()
  //         .order('id', ascending: true);
  //
  //     return List<Map<String, dynamic>>.from(response);
  //   } catch (e) {
  //     throw DragonRepositoryException('Failed to fetch dragons: $e');
  //   }
  // }

  // === User Item Data ===

  /// Get user's items and environments
  Future<List<dynamic>> fetchUserItems(String userId) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('acquired_accessories')
          .eq('id', userId)
          .single();

      if (response['acquired_accessories'] == null) {
        throw ItemRepositoryException('User $userId has no items');
      }

      // Returns a list with a string of ids ['long-id', 'long-id']
      return response['acquired_accessories'];
    }
    catch (e) {
      throw ItemRepositoryException('Error fetching user items: $e');
    }
  }



  Future<Map<String, Item>> fetchUserAllItems(String userId, String classId) async {
  try {
    final response = await _supabase
        .from('Users')
        .select('acquired_accessories')
        .eq('id', userId)
        .single();

    if (response['acquired_accessories'] == null) {
      throw ItemRepositoryException('User $userId has no items');
    }

    final List<dynamic> acquiredItems = response['acquired_accessories'];


    final List<Map<String, dynamic>> assets = await fetchClassAssets(classId);

    Map<String, Item> foundItems = {};

    // Find accessories with matching IDs
    for (var asset in assets) {
      if (asset['type'] == 'accessory' && acquiredItems.contains(asset['id'])) {

        ItemType type;
        switch (asset['type']) {
          case 'accessory':
            type = ItemType.item;
            break;

          case 'environment':
            type = ItemType.environment;
            break;

          default:
            type = ItemType.item;
            break;
        }

        final item = Item(
          id: asset['id'],
          name: asset['name'],
          type: type,
          imageUrl: asset['imageUrl'],
          cost: asset['cost'] ?? 1,
        );

        foundItems[item.id] = item;

      }
    }

    return foundItems;
  }
  catch (e) {
    // throw ItemRepositoryException('Failed to fetch user items for user $userId for class $classId: $e');
    return {};
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

  // /// Get user's current i environment
  // Future<String?> fetchCurrentEnvironment(String userId) async {
  //   try {
  //     final response = await _supabase
  //         .from('Users')
  //         .select('dragons')
  //         .eq('id', userId)
  //         .single();
  //
  //     return response['dragons']?['current_dragon_env'];
  //   } catch (e) {
  //     throw DragonRepositoryException('Failed to fetch current environment for $userId: $e');
  //   }
  // }

  // === Update Operations ===


}

/// Custom exception for repository operations
class ItemRepositoryException implements Exception {
  final String message;

  ItemRepositoryException(this.message);

  @override
  String toString() => 'ItemRepositoryException: $message';
}