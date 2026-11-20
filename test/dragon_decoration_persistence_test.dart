import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_scales/models/sticker_item_model.dart';
import 'package:safe_scales/services/dragon_decoration_service.dart';

void main() {
  final chestItem = Item(
    id: 'chest-1',
    type: ItemType.item,
    name: 'Treasure Chest',
    imageUrl: 'https://example.com/chest.png',
    cost: 10,
  );

  test('stickersToAccessoriesData round-trips position and size', () async {
    final stickers = [
      StickerItem(
        id: 'instance-a',
        imageUrl: chestItem.imageUrl,
        name: chestItem.name,
        accessoryId: chestItem.id,
        position: const Offset(42.5, 80),
        size: 64,
        isBehindDragon: true,
      ),
    ];

    final data = DragonDecorationService.stickersToAccessoriesData(stickers);
    expect(data.keys, ['instance-a']);
    expect(data['instance-a']['accessoryId'], 'chest-1');
    expect(data['instance-a']['position']['x'], 42.5);
    expect(data['instance-a']['position']['y'], 80);
    expect(data['instance-a']['size'], 64);
    expect(data['instance-a']['isBehindDragon'], isTrue);

    final restored = await DragonDecorationService.accessoriesDataToStickers(
      accessoriesData: data,
      userItems: [chestItem],
    );

    expect(restored, hasLength(1));
    expect(restored.first.id, 'instance-a');
    expect(restored.first.accessoryId, 'chest-1');
    expect(restored.first.position, const Offset(42.5, 80));
    expect(restored.first.size, 64);
    expect(restored.first.isBehindDragon, isTrue);
  });

  test('two stickers with the same accessoryId both survive save→load', () async {
    final stickers = [
      StickerItem(
        id: 'instance-1',
        imageUrl: chestItem.imageUrl,
        name: chestItem.name,
        accessoryId: chestItem.id,
        position: const Offset(10, 20),
        size: 48,
      ),
      StickerItem(
        id: 'instance-2',
        imageUrl: chestItem.imageUrl,
        name: chestItem.name,
        accessoryId: chestItem.id,
        position: const Offset(100, 120),
        size: 72,
      ),
    ];

    final data = DragonDecorationService.stickersToAccessoriesData(stickers);
    expect(data.keys, unorderedEquals(['instance-1', 'instance-2']));

    final restored = await DragonDecorationService.accessoriesDataToStickers(
      accessoriesData: data,
      userItems: [chestItem],
    );

    expect(restored, hasLength(2));
    final byId = {for (final s in restored) s.id: s};
    expect(byId['instance-1']!.position, const Offset(10, 20));
    expect(byId['instance-1']!.size, 48);
    expect(byId['instance-2']!.position, const Offset(100, 120));
    expect(byId['instance-2']!.size, 72);
    expect(byId['instance-1']!.accessoryId, 'chest-1');
    expect(byId['instance-2']!.accessoryId, 'chest-1');
  });

  test('legacy accessoryId-keyed format still loads', () async {
    final legacyData = {
      'chest-1': {
        'position': {'x': 15.0, 'y': 25.0},
        'size': 48.0,
        'isBehindDragon': false,
      },
    };

    final restored = await DragonDecorationService.accessoriesDataToStickers(
      accessoriesData: legacyData,
      userItems: [chestItem],
    );

    expect(restored, hasLength(1));
    expect(restored.first.id, 'acc_chest-1');
    expect(restored.first.accessoryId, 'chest-1');
    expect(restored.first.position, const Offset(15, 25));
    expect(restored.first.size, 48);
    expect(restored.first.isBehindDragon, isFalse);
  });
}
