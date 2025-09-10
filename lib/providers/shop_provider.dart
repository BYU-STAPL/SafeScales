import 'package:flutter/material.dart';
import 'package:safe_scales/repositories/shop_repository.dart';

import '../models/lesson.dart';
import '../models/sticker_item_model.dart';
import '../models/user.dart';
import '../services/course_service.dart';
import '../services/item_service.dart';
import '../services/shop_service.dart';
import '../services/user_state_service.dart';

class ShopProvider extends ChangeNotifier {
  // Services
  final ShopService _shopService;
  final ItemService _itemService;
  final UserStateService _userStateService;

  // State Variables
  bool _isLoading = false;
  bool _isPurchasing = false; // Add purchasing state
  String? _error;
  bool _isInitialized = false;

  // Data
  List<Lesson> _completedLessons = [];
  List<Item> _availableItems = [];
  List<Item> _availableEnvironments = [];

  ShopProvider({
    ShopService? shopService,
    ItemService? itemService,
    UserStateService? userStateService,
  }) : _shopService = shopService ?? ShopService(),
        _itemService = itemService ?? ItemService(),
        _userStateService = userStateService ?? UserStateService();

  // === GETTERS ===
  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  List<Lesson> get completedLessons => _completedLessons;
  List<Item> get availableItems => _availableItems;
  List<Item> get availableEnvironments => _availableEnvironments;

  // === Utility ===
  void _clearData() {
    _completedLessons = [];
    _availableItems = [];
    _availableEnvironments = [];
    _isInitialized = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setPurchasing(bool purchasing) {
    if (_isPurchasing != purchasing) {
      _isPurchasing = purchasing;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadShopData();
  }

  // === Initialization ===
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      await loadShopData();
      _isInitialized = true;

    } catch (e) {
      _clearData();
      _setError('Failed to initialize shop: $e');
      debugPrint('❌ Error initializing shop: $e');
    } finally {
      _setLoading(false);
    }
  }

  // === Load Shop Data from Shop Service ===
  Future<void> loadShopData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Move filtering logic over to shop service
      final availableItems = await _shopService.getShopItems();
      final availableEnvironments = await _shopService.getShopEnvironments();

      User? currentUser = _userStateService.currentUser;
      if (currentUser == null) {
        _clearData();
        _isInitialized = true;
        return;
      }

      String? courseId = await CourseService().getUserCourseId(currentUser.id);
      if (courseId == null) {
        _clearData();
        _isInitialized = true;
        return;
      }

      _availableItems = [];
      for (Item item in availableItems) {
        if (!await _itemService.userHasItem(currentUser.id, courseId, item.id)) {
          _availableItems.add(item);
        }
      }

      _availableEnvironments = [];
      for (Item env in availableEnvironments) {
        if (!await _itemService.userHasItem(currentUser.id, courseId, env.id)) {
          _availableEnvironments.add(env);
        }
      }

      _isLoading = false;
      notifyListeners();
    }
    catch (e) {
      print(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  // === Purchase Methods ===

  /// Purchase a specific item by index from available items
  Future<PurchaseResult> purchaseItemByIndex(int itemIndex, bool isEnvironment) async {
    User? currentUser = _userStateService.currentUser;
    if (currentUser == null) {
      return PurchaseResult.failure('User not logged in');
    }

    List<Item> sourceList = isEnvironment ? _availableEnvironments : _availableItems;

    if (itemIndex < 0 || itemIndex >= sourceList.length) {
      return PurchaseResult.failure('Invalid item selection');
    }

    Item selectedItem = sourceList[itemIndex];
    return await purchaseItem(selectedItem);
  }

  /// Purchase a specific item
  Future<PurchaseResult> purchaseItem(Item item) async {
    User? currentUser = _userStateService.currentUser;
    if (currentUser == null) {
      return PurchaseResult.failure('User not logged in');
    }

    _setPurchasing(true);
    _clearError();

    try {
      debugPrint('🛒 Attempting to purchase: ${item.name} (${item.id})');

      bool success = await _shopService.purchaseShopItem(currentUser.id, item);

      if (success) {
        // Remove the item from available items since it's now owned
        if (item.type == ItemType.item) {
          _availableItems.removeWhere((i) => i.id == item.id);
        } else if (item.type == ItemType.environment) {
          _availableEnvironments.removeWhere((i) => i.id == item.id);
        }

        notifyListeners();

        debugPrint('✅ Purchase successful: ${item.name}');
        return PurchaseResult.success(item);
      } else {
        debugPrint('❌ Purchase failed: ${item.name}');
        return PurchaseResult.failure('Purchase failed');
      }

    } catch (e) {
      debugPrint('❌ Error during purchase: $e');
      _setError('Purchase error: $e');
      return PurchaseResult.failure('Error: ${e.toString()}');
    } finally {
      _setPurchasing(false);
    }
  }

  /// Get item by index for UI purposes
  Item? getItemByIndex(int index, bool isEnvironment) {
    List<Item> sourceList = isEnvironment ? _availableEnvironments : _availableItems;
    if (index < 0 || index >= sourceList.length) return null;
    return sourceList[index];
  }
}

/// Result class for purchase operations
class PurchaseResult {
  final bool isSuccess;
  final String message;
  final Item? item;

  PurchaseResult._({
    required this.isSuccess,
    required this.message,
    this.item,
  });

  factory PurchaseResult.success(Item item) {
    return PurchaseResult._(
      isSuccess: true,
      message: 'Purchase successful!',
      item: item,
    );
  }

  factory PurchaseResult.failure(String message) {
    return PurchaseResult._(
      isSuccess: false,
      message: message,
    );
  }
}

class ShopProviderException implements Exception {
  final String message;
  ShopProviderException(this.message);

  @override
  String toString() => 'ShopProviderException: $message';
}