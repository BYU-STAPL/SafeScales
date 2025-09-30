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

      // DEBUG: Print what we're looking for
      debugPrint('🔍 Looking for accessory ID: "$accId"');
      debugPrint('🔍 Available user items: ${userItems.map((i) => '${i.id}:"${i.imageUrl}"').join(', ')}');

      // Find accessory by ID - FIXED: Compare i.id instead of i.toString()
      final item = userItems.firstWhere(
            (i) => i.id == accId.toString(), // This is the fix!
        orElse: () {
          debugPrint('❌ Could not find item with ID: $accId');
          return Item(
            id: accId.toString(),
            type: ItemType.item,
            name: 'Missing Item',
            imageUrl: '', // This will cause the file:/// error
            cost: 0,
          );
        },
      );

      // DEBUG: Print the found item
      debugPrint('🔍 Found item: ${item.name}, URL: "${item.imageUrl}"');

      // Validate the image URL before creating the sticker
      if (item.imageUrl.isEmpty ||
          item.imageUrl.startsWith('file:') ||
          item.imageUrl == 'null') {
        debugPrint('❌ Skipping item with invalid image URL: "${item.imageUrl}"');
        return; // Skip this item
      }

      restored.add(
        StickerItem(
          id: 'acc_$accId',
          imageUrl: item.imageUrl,
          name: item.name,
          accessoryId: item.id,
          position: Offset(
            (pos['x'] ?? 0).toDouble(),
            (pos['y'] ?? 0).toDouble(),
          ),
          size: (d['size'] ?? 48).toDouble(),
        ),
      );
    });

    debugPrint('✅ Successfully restored ${restored.length} stickers');
    return restored;
  }

  /// Save dragon decoration
  Future<bool> saveDragonDecoration({
    required String userId,
    required String dragonId,
    required List<StickerItem> stickers,
  }) async {
    try {
      // DEBUG: Print what we're saving
      debugPrint('🔍 Saving ${stickers.length} stickers for dragon $dragonId');
      for (final sticker in stickers) {
        debugPrint('🔍 Saving sticker: ${sticker.name} (${sticker.accessoryId}) - URL: "${sticker.imageUrl}"');
      }

      final accessoriesData = _stickersToAccessoriesData(stickers);
      return await _repository.saveDragonDressUp(
        userId: userId,
        dragonId: dragonId,
        accessoriesData: accessoriesData,
      );
    } catch (e) {
      debugPrint('❌ Error saving dragon decoration: $e');
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
      debugPrint('🔍 Loading dragon decoration for dragon: $dragonId');
      debugPrint('🔍 Available user items count: ${userItems.length}');

      final accessoriesData = await _repository.loadDragonDressUp(
        userId: userId,
        dragonId: dragonId,
      );

      if (accessoriesData == null || accessoriesData.isEmpty) {
        debugPrint('🔍 No decoration data found');
        return [];
      }

      debugPrint('🔍 Found decoration data: $accessoriesData');

      return await _accessoriesDataToStickers(
        accessoriesData: accessoriesData,
        userItems: userItems,
      );
    } catch (e) {
      debugPrint('❌ Error loading dragon decoration: $e');
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

  // Load/get current environment
  Future<String> loadCurrentDragonEnvironment(String userId, String dragonId) async {
    try {
      return await _repository.loadCurrentDragonEnvironment(userId, dragonId);
    }
    catch (e) {
      throw DragonDecorationServiceException('Failed to load current dragon environment for ${dragonId}: $e');
    }
  }

  /// Save environment selection
  Future<void> saveEnvironmentSelection(String userId, String environmentId, String dragonId,) async {
    await _repository.updateUserEnvironment(
      userId,
      environmentId,
      dragonId,
    );
  }

  /// Get user's available accessories
  Future<List<Item>> getUserItems(String userId, String classId) async {
    try {
      List<Item> userItems = await _itemService.getUserAccessories(userId, classId);

      // DEBUG: Print loaded items
      debugPrint('🔍 Loaded ${userItems.length} user accessories');
      for (final item in userItems) {
        debugPrint('🔍 Item: ${item.name} (${item.id}) - URL: "${item.imageUrl}"');
      }

      return userItems;

    } catch (e) {
      debugPrint('❌ Error getting user accessories: $e');
      throw DragonDecorationServiceException('Failed to get user accessories: $e');
    }
  }

  /// Get user's available environments
  Future<List<Item>> getUserEnvironments(String userId, String classId) async {
    try {
      List<Item> userEnvs = await _itemService.getUserEnvironments(userId, classId);

      // DEBUG: Print loaded environments
      debugPrint('🔍 Loaded ${userEnvs.length} user environments');
      for (final env in userEnvs) {
        debugPrint('🔍 Environment: ${env.name} (${env.id}) - URL: "${env.imageUrl}"');
      }

      return userEnvs;

    }
    catch (e) {
      debugPrint('❌ Error getting user environments: $e');
      throw DragonDecorationServiceException('Failed to get user environments: $e');
    }
  }

  /// Add a new sticker to the decoration
  StickerItem createSticker({
    required Item item,
    required Offset position,
    double size = 48.0,
  }) {
    // DEBUG: Print item being used for sticker
    debugPrint('🔍 Creating sticker from item: ${item.name} (${item.id}) - URL: "${item.imageUrl}"');

    // Validate the image URL
    if (item.imageUrl.isEmpty ||
        item.imageUrl.startsWith('file:') ||
        item.imageUrl == 'null') {
      debugPrint('❌ Cannot create sticker with invalid image URL: "${item.imageUrl}"');
      throw DragonDecorationServiceException('Invalid image URL for item: ${item.name}');
    }

    return StickerItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imageUrl: item.imageUrl,
      name: item.name,
      accessoryId: item.id,
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
    final clampedX = newPosition.dx.clamp(0, containerSize.width - stickerSize,).toDouble();
    final clampedY = newPosition.dy.clamp(0, containerSize.height - stickerSize,).toDouble();

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

    /*
    // The details.offset is the position where the user dropped the sticker
    // We want the sticker to appear exactly where they dropped it
    final double stickerSize = 48.0;

    // Use the drop position directly
    final double x = details.offset.dx;
    final double y = details.offset.dy;

    // Clamp to stay within bounds (accounting for sticker size)
    // Use the constrain function that does this clamping
    final double clampedX = x.clamp(0, environmentSize.width - stickerSize);
    final double clampedY = y.clamp(0, environmentSize.height - stickerSize);

    setState(() {
      final newSticker = StickerItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageUrl: data['image'],
        name: data['name'],
        accessoryId: data['id'].toString(),
        position: Offset(clampedX, clampedY),
        size: stickerSize,
      );
      placedStickers.add(newSticker);
    });
     */

    // Calculate position relative to drag target container
    // final dragTargetLeft = (screenSize.width - environmentSize.width) / 2;
    // final dragTargetTop = dragonPosition.dy + (dragonSize.height - environmentSize.height) / 2;
    //
    // // Calculate position relative to the actual dragon area within the drag target
    // final dragonOffsetX = (environmentSize.width - dragonSize.width) / 2;
    // final dragonOffsetY = (environmentSize.height - dragonSize.height) / 2;
    //
    // final relativeX = screenOffset.dx - dragTargetLeft - dragonOffsetX - (stickerSize / 2);
    // final relativeY = screenOffset.dy - dragTargetTop - dragonOffsetY - (stickerSize / 2);

    // Constrain to environment bounds
    return constrainStickerPosition(
      newPosition: screenOffset,
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