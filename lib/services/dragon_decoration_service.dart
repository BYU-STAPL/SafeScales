import 'dart:math';
import 'package:flutter/material.dart';
import 'package:safe_scales/models/sticker_item_model.dart';
import 'package:safe_scales/repositories/dragon_decoration_repository.dart';
import 'package:safe_scales/services/item_service.dart';

class DragonDecorationService {
  final DragonDecorationRepository _repository;
  final ItemService _itemService;

  DragonDecorationService({
    DragonDecorationRepository? repository,
    ItemService? itemService
  }) : _repository = repository ?? DragonDecorationRepository(),
        _itemService = itemService ?? ItemService();

  /// Convert sticker items to database format
  Map<String, dynamic> _stickersToAccessoriesData(List<StickerItem> stickers) {
    final Map<String, dynamic> accessoriesForDragon = {};
    for (final sticker in stickers) {
      accessoriesForDragon[sticker.accessoryId] = {
        'position': {'x': sticker.position.dx, 'y': sticker.position.dy},
        'size': sticker.size,
      };
    }
    return accessoriesForDragon;
  }

  /// Convert database format to sticker items
  Future<List<StickerItem>> _accessoriesDataToStickers({
    required Map<String, dynamic> accessoriesData,
    required List<Item> userItems,
  }) async {
    final List<StickerItem> restored = [];

    accessoriesData.forEach((accId, data) {
      final Map<String, dynamic> d = Map<String, dynamic>.from(data);
      final Map<String, dynamic> pos = Map<String, dynamic>.from(
        d['position'] ?? {},
      );

      // Find accessory image by ID
      //
      // final item = userItems[accId.toString()] ?? Item(
      //   id: 'id',
      //   type: ItemType.item,
      //   name: '',
      //   imageUrl: '',
      //   cost: 0,
      // );

      final item = userItems.firstWhere(
            (i) => i.toString() == accId.toString(),
        orElse: () => Item(
          id: 'id',
          type: ItemType.item,
          name: '',
          imageUrl: '',
          cost: 0,
        ),
      );

      restored.add(
        StickerItem(
          id: 'acc_$accId',
          imageUrl: item.imageUrl, //accessory['image'] ?? accessory['image_url'] ?? '',
          name: item.name, //accessory['name']?.toString() ?? accId.toString(),
          accessoryId: item.id, //accId.toString(),
          position: Offset(
            (pos['x'] ?? 0).toDouble(),
            (pos['y'] ?? 0).toDouble(),
          ),
          size: (d['size'] ?? 48).toDouble(),
        ),
      );
    });

    return restored;
  }

  /// Save dragon decoration
  Future<bool> saveDragonDecoration({
    required String userId,
    required String dragonId,
    required List<StickerItem> stickers,
  }) async {
    try {
      final accessoriesData = _stickersToAccessoriesData(stickers);
      return await _repository.saveDragonDressUp(
        userId: userId,
        dragonId: dragonId,
        accessoriesData: accessoriesData,
      );
    } catch (e) {
      throw DragonDecorationServiceException('Failed to save decoration: $e');
    }
  }

  /// Load dragon decoration
  Future<List<StickerItem>> loadDragonDecoration({
    required String userId,
    required String dragonId,
    required List<Item> userItems,
  }) async {
    try {
      final accessoriesData = await _repository.loadDragonDressUp(
        userId: userId,
        dragonId: dragonId,
      );

      if (accessoriesData == null || accessoriesData.isEmpty) {
        return [];
      }

      return await _accessoriesDataToStickers(
        accessoriesData: accessoriesData,
        userItems: userItems,
      );
    } catch (e) {
      throw DragonDecorationServiceException('Failed to load decoration: $e');
    }
  }

  /// Clear all decorations for a dragon
  Future<bool> clearDragonDecoration({
    required String userId,
    required String dragonId,
  }) async {
    try {
      return await _repository.clearDragonDressUp(
        userId: userId,
        dragonId: dragonId,
      );
    } catch (e) {
      throw DragonDecorationServiceException('Failed to clear decoration: $e');
    }
  }

  /// Get user's available accessories
  Future<List<Item>> getUserItems(String userId, String classId) async {
    try {
      List<Item> userItems = await _itemService.getUserAccessories(userId, classId);

      return userItems;

    } catch (e) {
      throw DragonDecorationServiceException('Failed to get user accessories: $e');
    }
  }

  /// Get user's available environments
  Future<List<Item>> getUserEnvironments(String userId, String classId) async {
    try {
      List<Item> userEnvs = await _itemService.getUserEnvironments(userId, classId);

      return userEnvs;

    }
    catch (e) {
      throw DragonDecorationServiceException('Failed to get user environments: $e');
    }
  }

  /// Add a new sticker to the decoration
  StickerItem createSticker({
    required Item item,
    required Offset position,
    double size = 48.0,
  }) {
    return StickerItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imageUrl: item.imageUrl, //accessoryData['image'] ?? accessoryData['image_url'] ?? '',
      name: item.name, //accessoryData['name']?.toString() ?? '',
      accessoryId: item.id, //accessoryData['id'].toString(),
      position: position,
      size: size,
    );
  }

  /// Update sticker position with bounds checking
  Offset constrainStickerPosition({
    required Offset newPosition,
    required Size containerSize,
    required double stickerSize,
  }) {
    final clampedX = newPosition.dx.clamp(
      0,
      containerSize.width - stickerSize,
    ).toDouble();

    final clampedY = newPosition.dy.clamp(
      0,
      containerSize.height - stickerSize,
    ).toDouble();

    return Offset(clampedX, clampedY);
  }

  /// Update sticker size with limits
  double constrainStickerSize(double newSize) {
    return newSize.clamp(20.0, 150.0);
  }

  /// Calculate drop position for new stickers
  Offset calculateDropPosition({
    required Offset screenOffset,
    required Size dragonSize,
    required Size environmentSize,
    required Size screenSize,
    required Offset dragonPosition,
    double stickerSize = 48.0,
  }) {
    // Calculate position relative to drag target container
    final dragTargetLeft = (screenSize.width - environmentSize.width) / 2;
    final dragTargetTop = dragonPosition.dy + (dragonSize.height - environmentSize.height) / 2;

    // Calculate position relative to the actual dragon area within the drag target
    final dragonOffsetX = (environmentSize.width - dragonSize.width) / 2;
    final dragonOffsetY = (environmentSize.height - dragonSize.height) / 2;

    final relativeX = screenOffset.dx - dragTargetLeft - dragonOffsetX - (stickerSize / 2);
    final relativeY = screenOffset.dy - dragTargetTop - dragonOffsetY - (stickerSize / 2);

    // Constrain to environment bounds
    return constrainStickerPosition(
      newPosition: Offset(relativeX, relativeY),
      containerSize: Size(
        environmentSize.width - stickerSize,
        environmentSize.height - stickerSize,
      ),
      stickerSize: stickerSize,
    );
  }
}

/// Custom exception for dragon decoration service operations
class DragonDecorationServiceException implements Exception {
  final String message;
  DragonDecorationServiceException(this.message);

  @override
  String toString() => 'DragonDecorationServiceException: $message';
}