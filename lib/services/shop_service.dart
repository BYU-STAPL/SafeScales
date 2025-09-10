import '../models/sticker_item_model.dart';
import '../repositories/shop_repository.dart';

class ShopService {
  final ShopRepository _repository;

  ShopService({ShopRepository? repository})
      : _repository = repository ?? ShopRepository();

  // Get items
  Future<List<Item>> getShopItems() async {
    try {
      List<Item> items = [];

      final List<Map<String, dynamic>> rawData = await _repository.getAccessories();

      for (var rawItem in rawData) {
        // Build Item
        Item item = Item(
          id: rawItem['id'],
          type: ItemType.item,
          name: rawItem['name'],
          imageUrl: rawItem['imageUrl'] ?? rawItem['image_url'] ?? '',
          cost: rawItem['cost'] ?? 1,
        );

        items.add(item);
      }

      return items;
    }
    catch (e) {
      print(e);
      return [];
    }
  }

  Future<Map<String, Item>> getShopItemsAsMap() async {
    try {
      Map<String, Item> items = {};

      final List<Map<String, dynamic>> rawData = await _repository.getAccessories();

      for (var rawItem in rawData) {
        // Build Item
        Item item = Item(
          id: rawItem['id'],
          type: ItemType.item,
          name: rawItem['name'],
          imageUrl: rawItem['imageUrl'] ?? rawItem['image_url'] ?? '',
          cost: rawItem['cost'] ?? 1,
        );

        items[item.id] = item;
      }

      return items;
    }
    catch (e) {
      print(e);
      return {};
    }
  }

  Future<List<Item>> getShopEnvironments() async {
    try {
      List<Item> environments = [];

      final List<Map<String, dynamic>> rawData = await _repository.getEnvironments();

      for (var rawItem in rawData) {

        // Build Item
        Item env = Item(
          id: rawItem['id'],
          type: ItemType.environment,
          name: rawItem['name'],
          imageUrl: rawItem['imageUrl'] ?? rawItem['image_url'] ?? '',
          cost: rawItem['cost'] ?? 1,
        );

        environments.add(env);
      }

      return environments;
    }
    catch (e) {
      print(e);
      return [];
    }
  }

  Future<Map<String, Item>> getShopEnvironmentsAsMap() async {
    try {
      Map<String, Item> environments = {};

      final List<Map<String, dynamic>> rawData = await _repository.getEnvironments();

      for (var rawItem in rawData) {

        // Build Item
        Item env = Item(
          id: rawItem['id'],
          type: ItemType.environment,
          name: rawItem['name'],
          imageUrl: rawItem['imageUrl'] ?? rawItem['image_url'] ?? '',
          cost: rawItem['cost'] ?? 1,
        );

        environments[env.id] = env;
      }

      return environments;
    }
    catch (e) {
      print(e);
      return {};
    }
  }

  // === Purchase Methods ===

  /// Purchase an item (accessory)
  Future<bool> purchaseItem(String userId, String itemId) async {
    try {
      return await _repository.purchaseAccessory(userId, itemId);
    } catch (e) {
      throw ShopServiceException('Failed to purchase item: $e');
    }
  }

  /// Purchase an environment
  Future<bool> purchaseEnvironment(String userId, String environmentId) async {
    try {
      return await _repository.purchaseEnvironment(userId, environmentId);
    } catch (e) {
      throw ShopServiceException('Failed to purchase environment: $e');
    }
  }

  /// Generic purchase method that handles both items and environments
  Future<bool> purchaseShopItem(String userId, Item item) async {
    try {
      switch (item.type) {
        case ItemType.item:
          return await purchaseItem(userId, item.id);
        case ItemType.environment:
          return await purchaseEnvironment(userId, item.id);
        default:
          throw ShopServiceException('Unknown item type: ${item.type}');
      }
    } catch (e) {
      throw ShopServiceException('Failed to purchase shop item: $e');
    }
  }
}

/// Custom exception for shop service operations
class ShopServiceException implements Exception {
  final String message;
  ShopServiceException(this.message);

  @override
  String toString() => 'ShopServiceException: $message';
}