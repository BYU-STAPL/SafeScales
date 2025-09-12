import 'package:flutter/material.dart';
import 'package:safe_scales/models/sticker_item_model.dart';
import 'package:safe_scales/services/dragon_decoration_service.dart';
import 'package:safe_scales/services/user_state_service.dart';

import '../services/course_service.dart';

class DragonDecorationProvider extends ChangeNotifier {
  final DragonDecorationService _service;
  final UserStateService _userStateService;

  // State Variables
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingAccessories = false;
  bool _isLoadingEnvironments = false;
  String? _error;
  bool _isInitialized = false;

  // Decoration Data
  List<StickerItem> _placedStickers = [];
  String? _selectedStickerId;

  // Assets Data
  List<Item> _userItems = [];
  List<Item> _userEnvironments = [];

  // Current selections
  int _selectedEnvironmentIndex = 0;
  bool isNoEnvironmentSelected = true;
  String _currentDragonId = '';

  DragonDecorationProvider({
    DragonDecorationService? service,
    UserStateService? userStateService,
  }) : _service = service ?? DragonDecorationService(),
        _userStateService = userStateService ?? UserStateService();

  // === GETTERS ===
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isLoadingAccessories => _isLoadingAccessories;
  bool get isLoadingEnvironments => _isLoadingEnvironments;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  List<StickerItem> get placedStickers => _placedStickers;
  String? get selectedStickerId => _selectedStickerId;
  List<Item> get userItems => _userItems;
  List<Item> get userEnvironments => _userEnvironments;
  int get selectedEnvironmentIndex => _selectedEnvironmentIndex;
  String get currentDragonId => _currentDragonId;

  Item? getCurrentEnvironment() {
    if (isNoEnvironmentSelected || _selectedEnvironmentIndex >= _userEnvironments.length) {
      return null;
    }

    return _userEnvironments[_selectedEnvironmentIndex];
  }

  // === UTILITY METHODS ===
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setSaving(bool saving) {
    if (_isSaving != saving) {
      _isSaving = saving;
      notifyListeners();
    }
  }

  void _setLoadingAccessories(bool loading) {
    if (_isLoadingAccessories != loading) {
      _isLoadingAccessories = loading;
      notifyListeners();
    }
  }

  void _setLoadingEnvironments(bool loading) {
    if (_isLoadingEnvironments != loading) {
      _isLoadingEnvironments = loading;
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

  void _clearData() {
    _placedStickers = [];
    _selectedStickerId = null;
    _userItems = [];
    _userEnvironments = [];
    _selectedEnvironmentIndex = 0;
    _currentDragonId = '';
    _isInitialized = false;
    notifyListeners();
  }

  // === INITIALIZATION ===
  Future<void> initialize(String dragonId) async {
    if (_isInitialized && _currentDragonId == dragonId) {
      return; // Already initialized for this dragon
    }

    _setLoading(true);
    _clearError();
    _currentDragonId = dragonId;

    try {
      await Future.wait([
        _loadUserAccessories(),
        _loadUserEnvironments(),
      ]);

      await _loadDragonDecoration();
      await _loadCurrentDragonEnvironment();
      _isInitialized = true;

    } catch (e) {
      _clearData();
      _setError('Failed to initialize dragon decoration: $e');
      debugPrint('❌ Error initializing dragon decoration: $e');
    } finally {
      _setLoading(false);
    }
  }

  // === LOAD DATA METHODS ===
  Future<void> _loadUserAccessories() async {
    final currentUser = _userStateService.currentUser;
    if (currentUser == null) {
      _setError('User not logged in');
      return;
    }

    _setLoadingAccessories(true);

    //TODO: How do I use my dependency injection with this?
    String? courseId = await CourseService().getUserCourseId(currentUser.id);
    if (courseId == null) {
      _clearData();
      _isInitialized = true;
      _setLoadingAccessories(false);
      return;
    }

    try {
      _userItems = await _service.getUserItems(currentUser.id, courseId);

    }
    catch (e) {
      debugPrint('❌ Error loading accessories: $e');
      _setError('Failed to load accessories: $e');
      _userItems = [];
    }
    finally {
      _setLoadingAccessories(false);
    }
  }

  Future<void> _loadUserEnvironments() async {
    final currentUser = _userStateService.currentUser;
    if (currentUser == null) {
      _setError('User not logged in');
      return;
    }

    _setLoadingEnvironments(true);

    String? courseId = await CourseService().getUserCourseId(currentUser.id);
    if (courseId == null) {
      _clearData();
      _isInitialized = true;
      _setLoadingAccessories(false);
      return;
    }


    try {
      _userEnvironments = await _service.getUserEnvironments(currentUser.id, courseId);

      // If no environments, add default
      if (_userEnvironments.isEmpty) {
        _userEnvironments = [];
      }
    } catch (e) {
      debugPrint('❌ Error loading environments: $e');
      _setError('Failed to load environments: $e');
      _userEnvironments = [];
    } finally {
      _setLoadingEnvironments(false);
    }
  }

  Future<void> _loadCurrentDragonEnvironment() async {
    try {
      final user = _userStateService.currentUser;
      if (user == null) return;

      final environmentId = await _service.loadCurrentDragonEnvironment(
        user.id,
        _currentDragonId,
      );

      if (environmentId != "") {
        for (int i = 0; i < _userEnvironments.length ; i++) {
          if (environmentId == _userEnvironments[i].id) {
            _selectedEnvironmentIndex = i;
            isNoEnvironmentSelected = false;
            return;
          }
        }
      }
      else {
        isNoEnvironmentSelected = true;
        _selectedEnvironmentIndex = 0;
      }
    }
    catch (e) {
      debugPrint('❌ Error loading dragon decoration: $e');
      _selectedEnvironmentIndex = 0;
      isNoEnvironmentSelected = true;
    }
  }

  Future<void> saveEnvironmentSelection(String dragonId, String environmentId,) async {
    try {

      final user = _userStateService.currentUser;
      if (user == null) return;


      await _service.saveEnvironmentSelection(
        user.id,
        environmentId,
        dragonId,
      );


      if (environmentId != "") {
        for (int i = 0; i < _userEnvironments.length ; i++) {
          if (environmentId == _userEnvironments[i].id) {
            _selectedEnvironmentIndex = i;
            isNoEnvironmentSelected = false;
            return;
          }
        }
      }
      else {
        isNoEnvironmentSelected = true;
        _selectedEnvironmentIndex = 0;
      }

      notifyListeners();

    } catch (e) {
      _setError('Failed to save environment selection: $e');
      print('❌ Error saving environment selection: $e');
    }
  }

  Future<void> _loadDragonDecoration() async {
    final user = _userStateService.currentUser;
    if (user == null) return;

    try {
      _placedStickers = await _service.loadDragonDecoration(
        userId: user.id,
        dragonId: _currentDragonId,
        userItems: _userItems,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading dragon decoration: $e');
      _placedStickers = [];
    }
  }

  // === STICKER MANAGEMENT ===
  Future<void> addSticker({
    required Item item,
    required Offset position,
    double size = 48.0,
  }) async {
    try {
      final newSticker = _service.createSticker(
        item: item,
        position: position,
        size: size,
      );

      _placedStickers.add(newSticker);
      notifyListeners();

      await _saveDecoration();
    } catch (e) {
      _setError('Failed to add sticker: $e');
    }
  }

  void updateStickerPosition({
    required String stickerId,
    required Offset newPosition,
    required Size containerSize,
  }) {
    try {
      final stickerIndex = _placedStickers.indexWhere((s) => s.id == stickerId);
      if (stickerIndex == -1) return;

      final sticker = _placedStickers[stickerIndex];
      final constrainedPosition = _service.constrainStickerPosition(
        newPosition: newPosition,
        containerSize: containerSize,
        stickerSize: sticker.size,
      );

      _placedStickers[stickerIndex] = StickerItem(
        id: sticker.id,
        imageUrl: sticker.imageUrl,
        name: sticker.name,
        accessoryId: sticker.accessoryId,
        position: constrainedPosition,
        size: sticker.size,
      );

      notifyListeners();
      _saveDecoration();
    } catch (e) {
      _setError('Failed to update sticker position: $e');
    }
  }

  void updateStickerSize(String stickerId, double newSize) {
    try {
      final stickerIndex = _placedStickers.indexWhere((s) => s.id == stickerId);
      if (stickerIndex == -1) return;

      final sticker = _placedStickers[stickerIndex];
      final constrainedSize = _service.constrainStickerSize(newSize);

      _placedStickers[stickerIndex] = StickerItem(
        id: sticker.id,
        imageUrl: sticker.imageUrl,
        name: sticker.name,
        accessoryId: sticker.accessoryId,
        position: sticker.position,
        size: constrainedSize,
      );

      notifyListeners();
      _saveDecoration();
    } catch (e) {
      _setError('Failed to update sticker size: $e');
    }
  }

  void selectSticker(String? stickerId) {
    if (_selectedStickerId != stickerId) {
      _selectedStickerId = stickerId;
      notifyListeners();
    }
  }

  Future<void> removeSticker(String stickerId) async {
    try {
      _placedStickers.removeWhere((sticker) => sticker.id == stickerId);

      if (_selectedStickerId == stickerId) {
        _selectedStickerId = null;
      }

      notifyListeners();
      await _saveDecoration();
    } catch (e) {
      _setError('Failed to remove sticker: $e');
    }
  }

  Future<void> clearAllStickers() async {
    try {
      _placedStickers.clear();
      _selectedStickerId = null;
      notifyListeners();

      await _saveDecoration();
    } catch (e) {
      _setError('Failed to clear stickers: $e');
    }
  }

  // === ENVIRONMENT MANAGEMENT ===
  void selectEnvironment(int environmentIndex, bool isNoneSelected) {

    if (isNoneSelected) {
      isNoEnvironmentSelected = true;
      _selectedEnvironmentIndex = 0;
      notifyListeners();
      return;
    }

    if (environmentIndex >= 0 && environmentIndex < _userEnvironments.length) {
      _selectedEnvironmentIndex = environmentIndex;
      isNoEnvironmentSelected = false;
      notifyListeners();
      return;
    }
  }

  // === SAVE OPERATIONS ===
  Future<void> _saveDecoration() async {
    final user = _userStateService.currentUser;
    if (user == null) return;

    _setSaving(true);
    _clearError();

    try {
      final success = await _service.saveDragonDecoration(
        userId: user.id,
        dragonId: _currentDragonId,
        stickers: _placedStickers,
      );

      if (!success) {
        _setError('Failed to save decoration');
      }
    } catch (e) {
      _setError('Error saving decoration: $e');
    } finally {
      _setSaving(false);
    }
  }

  // === UTILITY METHODS FOR UI ===
  Offset calculateDropPosition({
    required Offset screenOffset,
    required Size dragonSize,
    required Size environmentSize,
    required Size screenSize,
    required Offset dragonPosition,
    double stickerSize = 48.0,
  }) {
    return _service.calculateDropPosition(
      screenOffset: screenOffset,
      dragonSize: dragonSize,
      environmentSize: environmentSize,
      screenSize: screenSize,
      dragonPosition: dragonPosition,
      stickerSize: stickerSize,
    );
  }

  /// Refresh all data for the current dragon
  Future<void> refresh() async {
    if (_currentDragonId.isNotEmpty) {
      _isInitialized = false;
      await initialize(_currentDragonId);
    }
  }
}