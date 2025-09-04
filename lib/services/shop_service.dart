import '../models/sticker_item_model.dart';
import '../repositories/item_repository.dart';
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

}