// Model class for placed stickers
import 'dart:ui';

enum ItemType { item, environment }

class Item {
  final String id;
  final ItemType type;
  final String name;
  final String imageUrl;

  // TODO: Later add a cost parameter for the shop

  Item({
    required this.id,
    required this.type,
    required this.name,
    required this.imageUrl,
  });
}

class StickerItem {
  final String id;
  final String imageUrl;
  final String name;
  final String accessoryId;
  Offset position;
  double size;

  StickerItem({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.accessoryId,
    required this.position,
    this.size = 48.0,
  });
}
