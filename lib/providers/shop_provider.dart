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
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  List<Lesson> get completedLessons => _completedLessons;
  List<Item> get availableItems => _availableItems;
  List<Item> get availableEnvironments => _availableEnvironments;


  // === Utility ===
  void _clearData() {
    _completedLessons = [];
    _availableItems = [];
    _isInitialized = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
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


  // === Process a completed Purchase ===
  // Update the available items to buy




}

class ShopProviderException implements Exception {
  final String message;
  ShopProviderException(this.message);

  @override
  String toString() => 'ShopProviderException: $message';
}