// Model class for placed stickers
import 'dart:ui';

class StickerItem {
  final String id;
  final String imageUrl;
  final String name;
  Offset position;
  double size;

  StickerItem({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.position,
    this.size = 48.0,
  });
}