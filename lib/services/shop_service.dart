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

      print(items);

      return items;
    }
    catch (e) {
      print(e);
      return [];
    }
  }

  // Get environments


}