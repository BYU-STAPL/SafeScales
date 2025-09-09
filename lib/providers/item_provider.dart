import 'package:flutter/foundation.dart';
import 'package:safe_scales/services/course_service.dart';
import 'package:safe_scales/services/item_service.dart';
import 'package:safe_scales/models/sticker_item_model.dart';

import '../models/user.dart';
import '../services/user_state_service.dart';

/// Provider for managing item state across the app
class ItemProvider extends ChangeNotifier {
  final ItemService _itemService;
  final UserStateService _userStateService;

  // State variables
  List<Item> _items = [];
  List<Item> _environments = [];

  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Current user context
  String? _currentUserId;
  String? _currentCourseId;

  ItemProvider({ItemService? itemService, UserStateService? userStateService,})
      : _itemService = itemService ?? ItemService(),
        _userStateService = userStateService ?? UserStateService();

  // === Getters ===

  List<Item> get items => List.unmodifiable(_items);
  List<Item> get environments => List.unmodifiable(_environments);

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  bool get hasAccessories => _items.isNotEmpty;
  bool get hasEnvironments => _environments.isNotEmpty;

  // Combined getter for all items
  List<Item> get allItems => [..._items, ..._environments];

  User? get currentUser => _userStateService.currentUser;

  // === Public Methods ===

  /// Initialize provider with user context
  Future<void> initialize() async {
    _currentUserId = currentUser?.id;

    if (currentUser == null) {
      _clearData();
      _isInitialized = true;
      return;
    }

    String? courseId = await CourseService().getUserCourseId(currentUser!.id);
    if (courseId == null) {
      _clearData();
      return;
    }
    _currentCourseId = courseId;

    await loadUserItems();

    _isInitialized = true;
  }

  void _clearData() {
    _items = [];
    _environments = [];
    notifyListeners();
  }

  /// Load all user items (accessories and environments)
  Future<void> loadUserItems() async {
    if (_currentUserId == null || _currentCourseId == null) {
      // _setError('User context not initialized');
      // _setLoading(false);
      _clearData();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final processedItems = await _itemService.processUserItems(
        _currentUserId!,
        _currentCourseId!,
      );

      _items = processedItems['accessories'] ?? [];
      _environments = processedItems['environments'] ?? [];

      debugPrint('✅ Loaded ${_items.length} accessories and ${_environments.length} environments');

    } catch (e) {
      _setError('Failed to load user items: $e');
      debugPrint('❌ Error loading user items: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load only accessories
  Future<void> loadAccessories() async {
    if (_currentUserId == null || _currentCourseId == null) {
      // _setError('User context not initialized');
      return;
    }



    _setLoading(true);
    _clearError();

    try {
      _items = await _itemService.getUserAccessories(
        _currentUserId!,
        _currentCourseId!,
      );

      debugPrint('✅ Loaded ${_items.length} accessories');

    } catch (e) {
      _setError('Failed to load accessories: $e');
      debugPrint('❌ Error loading accessories: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load only environments
  Future<void> loadEnvironments() async {
    if (_currentUserId == null || _currentCourseId == null) {
      _setError('User context not initialized');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _environments = await _itemService.getUserEnvironments(
        _currentUserId!,
        _currentCourseId!,
      );

      debugPrint('✅ Loaded ${_environments.length} environments');

    } catch (e) {
      _setError('Failed to load environments: $e');
      debugPrint('❌ Error loading environments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadUserItems();
  }

  /// Check if user has a specific item
  Future<bool> hasItem(String itemId) async {
    if (_currentUserId == null || _currentCourseId == null) {
      return false;
    }

    try {
      return await _itemService.userHasItem(
        _currentUserId!,
        _currentCourseId!,
        itemId,
      );
    } catch (e) {
      debugPrint('❌ Error checking if user has item: $e');
      return false;
    }
  }

  /// Get item by ID from loaded items
  Item? getItemById(String itemId) {
    try {
      return allItems.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  /// Filter accessories by name
  List<Item> filterAccessories(String query) {
    if (query.isEmpty) return items;

    return _itemService.filterItems(
      _items,
      nameFilter: query,
    );
  }

  /// Filter environments by name
  List<Item> filterEnvironments(String query) {
    if (query.isEmpty) return environments;

    return _itemService.filterItems(
      _environments,
      nameFilter: query,
    );
  }

  /// Sort accessories
  List<Item> getSortedAccessories({bool ascending = true}) {
    return _itemService.sortItemsByName(_items, ascending: ascending);
  }

  /// Sort environments
  List<Item> getSortedEnvironments({bool ascending = true}) {
    return _itemService.sortItemsByName(_environments, ascending: ascending);
  }

  /// Clear all data (useful for logout)
  void clear() {
    _items.clear();
    _environments.clear();
    _currentUserId = null;
    _currentCourseId = null;
    _clearError();
    notifyListeners();
  }

  // === Private Helper Methods ===

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

  // === Development/Debug Methods ===

  /// Get debug info about current state
  Map<String, dynamic> getDebugInfo() {
    return {
      'accessories_count': _items.length,
      'environments_count': _environments.length,
      'is_loading': _isLoading,
      'has_error': _error != null,
      'error_message': _error,
      'user_id': _currentUserId,
      'class_id': _currentCourseId,
      'total_items': allItems.length,
    };
  }
}