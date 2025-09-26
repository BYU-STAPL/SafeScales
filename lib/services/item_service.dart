import 'package:safe_scales/repositories/item_repository.dart';

import '../models/sticker_item_model.dart';

class ItemService {
  final ItemRepository _repository;

  ItemService({ItemRepository? repository})
      : _repository = repository ?? ItemRepository();

  // === Data Processing ===

  /// Process and return user's items organized by type
  Future<Map<String, List<Item>>> processUserItems(String userId, String classId) async {
    try {

      final List<dynamic> acquiredItems = await _repository.fetchUserItemIDList(userId);

      final assets = await _repository.fetchClassAssets(classId);

      List<Item> items = [];
      List<Item> environments = [];

      // Find accessories with matching IDs
      for (var asset in assets) {
        if (asset['type'] != 'dragon' && acquiredItems.contains(asset['id'])) {

          final Item item = _createItemFromAsset(asset);

          switch (item.type) {
            case ItemType.item:
              items.add(item);
              break;

            case ItemType.environment:
              environments.add(item);
              break;
          }
        }
      }

      return {
        'accessories': items,
        'environments': environments,
      };
    } catch (e) {
      throw ItemServiceException('Failed to process user items: $e');
    }
  }

  /// Get only user's accessories
  Future<List<Item>> getUserAccessories(String userId, String classId) async {
    try {
      final processedItems = await processUserItems(userId, classId);
      return processedItems['accessories'] ?? [];
    } catch (e) {
      throw ItemServiceException('Failed to get user accessories: $e');
    }
  }

  /// Get only user's environments
  Future<List<Item>> getUserEnvironments(String userId, String classId) async {
    try {
      final processedItems = await processUserItems(userId, classId);
      return processedItems['environments'] ?? [];
    } catch (e) {
      throw ItemServiceException('Failed to get user environments: $e');
    }
  }

  /// Check if user has a specific item
  Future<bool> userHasItem(String userId, String classId, String itemId) async {
    try {

      final userItems = await _repository.fetchUserItemIDList(userId);
      return userItems.contains(itemId);
    } catch (e) {
      throw ItemServiceException('Failed to check if user has item: $e');
    }
  }

  /// Get item details by ID
  Future<Item?> getItemById(String classId, String itemId) async {
    try {
      final assets = await _repository.fetchClassAssets(classId);

      for (var asset in assets) {
        if (asset['id'] == itemId) {
          return _createItemFromAsset(asset);
        }
      }

      return null;
    } catch (e) {
      throw ItemServiceException('Failed to get item by ID: $e');
    }
  }

  Item _createItemFromAsset(Map<String, dynamic> asset) {
    try {

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

      return Item(
        id: asset['id'],
        type: type,
        name: asset['name'],
        imageUrl: asset['imageUrl'],
        cost: asset['cost'] ?? 1,
      );

    } catch (e) {
      throw ItemServiceException('Error creating item from asset: $e');
    }
  }

  // === Business Logic Methods ===

  /// Validate if an item can be equipped/used
  bool canUseItem(Item item, String itemType) {
    // Add any business rules here
    // For example: check if item is appropriate for user's level, etc.
    return item.id.isNotEmpty && item.name.isNotEmpty;
  }

  /// Filter items based on criteria
  List<Item> filterItems(List<Item> items, {
    String? nameFilter,
    bool Function(Item)? customFilter,
  }) {
    var filtered = items;

    if (nameFilter != null && nameFilter.isNotEmpty) {
      filtered = filtered
          .where((item) => item.name.toLowerCase().contains(nameFilter.toLowerCase()))
          .toList();
    }

    if (customFilter != null) {
      filtered = filtered.where(customFilter).toList();
    }

    return filtered;
  }

  /// Sort items by name
  List<Item> sortItemsByName(List<Item> items, {bool ascending = true}) {
    final sorted = List<Item>.from(items);
    sorted.sort((a, b) => ascending
        ? a.name.compareTo(b.name)
        : b.name.compareTo(a.name));
    return sorted;
  }

  // === Repository Delegates ===

  /// Direct access to fetch user items (delegates to repository)
  // Future<Map<String, Item>> fetchUserItems(String userId, String classId) async {
  //   return await _repository.fetchAllUserItemsAndEnvs(userId, classId);
  // }

  /// Direct access to fetch class assets (delegates to repository)
  Future<List<Map<String, dynamic>>> fetchClassAssets(String classId) async {
    return await _repository.fetchClassAssets(classId);
  }
}

/// Custom exception for service operations
class ItemServiceException implements Exception {
  final String message;
  ItemServiceException(this.message);

  @override
  String toString() => 'ItemServiceException: $message';
}