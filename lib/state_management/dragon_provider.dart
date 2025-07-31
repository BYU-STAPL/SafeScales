import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:safe_scales/services/class_service.dart';
import 'package:safe_scales/services/user_progress_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/models/dragon.dart';
import '../services/dragon_service.dart';
import '../services/quiz_service.dart';

/// Provider that manages dragon state for the UI
/// This layer handles UI state, loading states, and coordinates between UI and service layer
class DragonProvider extends ChangeNotifier {
  // === Services ===
  final DragonService _dragonService;
  final UserStateService _userState;
  final ClassService _classService;

  // === State ===
  bool _isLoading = false;
  String? _error;

  // === Dragon Data ===
  Map<String, Dragon> _dragons = {};
  Map<String, List<String>> _unlockedDragonPhases = {};
  Map<String, Dragon> _dragonsByModuleId = {};
  String? _currentEnvironment;

  // === Constructor ===
  DragonProvider({
    required DragonService dragonService,
    UserStateService? userState,
    required ClassService classService,
  }) : _dragonService = dragonService,
        _userState = userState ?? UserStateService(),
        _classService = classService;

  // === Getters ===
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, Dragon> get dragons => _dragons;
  Map<String, List<String>> get unlockedDragonPhases => _unlockedDragonPhases;
  Map<String, Dragon> get dragonsByModuleId => _dragonsByModuleId;
  String? get currentEnvironment => _currentEnvironment;

  /// Get dragon by ID
  Dragon? getDragonById(String dragonId) => _dragons[dragonId];

  /// Get dragon by module ID
  Dragon? getDragonByModuleId(String moduleId) => _dragonsByModuleId[moduleId];

  /// Get all dragons as a list
  List<Dragon> getAllDragons() => _dragons.values.toList();

  /// Check if a dragon has a specific phase unlocked
  bool hasPhase(String dragonId, String phase) {
    final phases = _unlockedDragonPhases[dragonId] ?? [];
    return _dragonService.isPhaseUnlocked(phases, phase);
  }

  /// Get display name for a phase
  String getPhaseDisplayName(String phase) {
    return _dragonService.getPhaseDisplayName(phase);
  }

  /// Get highest unlocked phase for a dragon
  String getDragonHighestPhase(String dragonId) {
    final phases = _unlockedDragonPhases[dragonId] ?? [];
    return _dragonService.getHighestUnlockedPhase(phases);
  }

  /// Get user's preferred phase for a dragon (currently returns highest unlocked)
  String getUserPreferredPhase(String dragonId) {
    // TODO: Implement user preference storage
    return getDragonHighestPhase(dragonId);
  }

  /// Check if play mode is unlocked for a dragon
  bool isPlayUnlocked(String dragonId) {
    final phases = _unlockedDragonPhases[dragonId] ?? [];
    return _dragonService.isPlayUnlocked(phases);
  }

  /// Get dragon image URL for specific or current phase
  String getDragonImageUrl(String dragonId, {String? forPhase}) {
    final dragon = _dragons[dragonId];
    if (dragon == null) return '';

    final phases = _unlockedDragonPhases[dragonId] ?? [];
    return _dragonService.getDragonImageUrl(dragon, phases, forPhase: forPhase);
  }

  // === Public Methods ===

  /// Initialize the provider
  Future<void> initialize() async {
    await loadUserDragons();
    print('DragonProvider initialized');
  }

  /// Load user dragons and related data
  Future<void> loadUserDragons() async {
    try {
      _setLoading(true);
      _clearError();

      final user = _userState.currentUser;
      if (user == null) {
        _clearData();
        return;
      }

      final classData = await _classService.getUserClass(user.id);
      if (classData.isEmpty) {
        _clearData();
        return;
      }

      await _loadDragonData(user.id, classData['id']);

    } catch (e) {
      _setError('Failed to load user dragons: $e');
      print('❌ DragonProvider: Error loading user dragons: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update dragon phases for a specific lesson
  Future<void> updateDragonPhases(String lessonId) async {
    try {
      final dragon = getDragonByModuleId(lessonId);
      if (dragon == null) return;

      final user = _userState.currentUser;
      if (user == null) return;

      await _dragonService.updateDragonProgressForLesson(user.id, dragon.id, lessonId);

      // Refresh local data
      await _refreshUnlockedPhases(user.id);

    } catch (e) {
      _setError('Failed to update dragon phases: $e');
      print('❌ DragonProvider: Error updating dragon progress: $e');
    }
  }

  /// Update all dragon progress based on current lesson progress
  Future<void> updateAllDragonProgress() async {
    try {
      _setLoading(true);
      _clearError();

      final user = _userState.currentUser;
      if (user == null) throw Exception('User is null');

      // final classData = await _classService.getUserClass(user.id);
      // if (classData.isEmpty) {
      //   throw Exception('Class data is missing for user ${user.id}');
      // }

      // final modules = await _classService.getClassModules(classData['id']);
      // final moduleIds = modules.map((m) => m['id'] as String).toList();
      // // final moduleProgress = await _quizService.getModuleProgress(
      // //   userId: user.id,
      // //   moduleIds: moduleIds,
      // // );
      //
      // // Get all module ids
      // _dragonsByModuleId


      // Update progress for each module
      for (final lessonId in _dragonsByModuleId.keys) {
        await updateDragonPhases(lessonId);
      }

      await _refreshUnlockedPhases(user.id);

    } catch (e) {
      _setError('Failed to update all dragon progress: $e');
      print('❌ DragonProvider: Error updating all dragon progress: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save environment selection for dragons
  Future<void> saveEnvironmentSelection(String dragonId, String environmentId) async {
    try {
      final user = _userState.currentUser;
      if (user == null) return;

      await _dragonService.saveEnvironmentSelection(user.id, environmentId, _unlockedDragonPhases);

      _currentEnvironment = environmentId;
      notifyListeners();

      print('✅ Environment selection saved successfully');
    } catch (e) {
      _setError('Failed to save environment selection: $e');
      print('❌ Error saving environment selection: $e');
    }
  }

  // === Private Helper Methods ===

  /// Load all dragon-related data for a user
  Future<void> _loadDragonData(String userId, String classId) async {
    // Get raw data
    final userDragonsData = await _dragonService.getUserDragonsData(userId);
    final classAssets = await _dragonService.getClassAssets(classId);

    // Process data using service business logic
    _dragons = _dragonService.processUserDragons(userDragonsData, classAssets);
    _dragons = _dragonService.sortDragonsByModuleId(_dragons);

    _dragonsByModuleId = _dragonService.createDragonsByModuleMap(_dragons);
    _unlockedDragonPhases = _dragonService.extractClassDragonPhases(userDragonsData, classAssets);
    _currentEnvironment = await _dragonService.getCurrentEnvironment(userId);

    notifyListeners();
  }

  /// Refresh unlocked phases data
  Future<void> _refreshUnlockedPhases(String userId) async {
    final user = _userState.currentUser;
    if (user == null) return;

    final classData = await _classService.getUserClass(user.id);
    if (classData.isEmpty) return;

    final userDragonsData = await _dragonService.getUserDragonsData(userId);
    final classAssets = await _dragonService.getClassAssets(classData['id']);

    _unlockedDragonPhases = _dragonService.extractClassDragonPhases(userDragonsData, classAssets);
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error state
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error state
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Clear all data
  void _clearData() {
    _dragons = {};
    _unlockedDragonPhases = {};
    _dragonsByModuleId = {};
    _currentEnvironment = null;
    notifyListeners();
  }
}