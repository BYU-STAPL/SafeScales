import 'dart:core';

import 'package:flutter/cupertino.dart';

import 'package:safe_scales/services/class_service.dart';
import 'package:safe_scales/services/dragon_service.dart';
import 'package:safe_scales/services/user_state_service.dart';

import 'package:safe_scales/models/dragon.dart';

import '../services/quiz_service.dart';

class DragonProvider extends ChangeNotifier {
  // === For tracking growth phases ===
  static const List<String> PHASE_ORDER = ['egg', 'stage1', 'stage2', 'final'];

  static const Map<String, String> PHASE_ALIASES = {
    'baby': 'stage1',
    'teen': 'stage2',
    'adult': 'final',
  };

  /// Normalize phase name (handle legacy names)
  String _normalizePhase(String phase) {
    return PHASE_ALIASES[phase] ?? phase;
  }

  // === Data ===
  bool _isLoading = true;

  // === Dragon Data ===
  Map<String, Dragon> _dragons = {};
  Map<String, List<String>> _unlockedDragonPhases = {}; // DragonID to list of phases unlocked for the dragon
  Map<String, Dragon> _dragonsByModuleId = {};

  // === Services ===
  final UserStateService _userState = UserStateService();
  final QuizService _quizService = QuizService();
  late final DragonService _dragonService;
  late final ClassService _classService;

  // === init ===
  DragonProvider() {
    _dragonService = DragonService(_quizService.supabase);
    _classService = ClassService(_quizService.supabase);
  }

  Future<void> initialize() async {
    await _dragonService.initialize();
  }

  // === GETTERS ===
  bool get isLoading => _isLoading;

  Map<String, Dragon> get dragons => _dragons;

  Dragon? getDragonById(String dragonId) {
    return _dragons[dragonId];
  }

  Dragon? getDragonByModuleId(String moduleId) {
    return _dragonsByModuleId[moduleId];
  }

  List<Dragon> getAllDragons() {
    return _dragons.values.toList();
  }

  bool hasPhase(String dragonId, String phase) {
    final phases = _unlockedDragonPhases[dragonId] ?? [];
    final normalizedPhase = _normalizePhase(phase);
    return phases.any((p) => _normalizePhase(p) == normalizedPhase);
  }

  String getPhaseDisplayName(String phase) {
    const displayNames = {
      'egg': 'Egg',
      'stage1': 'Baby',
      'stage2': 'Teen',
      'final': 'Adult',
    };
    return displayNames[phase] ?? 'Unknown';
  }

  /// Get highest unlocked phase for a dragon
  String getDragonHighestPhase(String dragonId) {
    // Check phases in reverse order (highest to lowest)
    for (int i = PHASE_ORDER.length - 1; i >= 0; i--) {
      final phase = PHASE_ORDER[i];
      if(hasPhase(dragonId, phase)) {
        return phase;
      }
    }

    return 'egg';
  }

  String getUserPreferredPhase(String dragonId) {
    /// TODO: Implement user preference storage
    // For now, return the current phase
    // In the future, this could check user preferences from database
    return getDragonHighestPhase(dragonId);
  }

  /// Check if play is unlocked (final phase reached)
  bool isPlayUnlocked(String dragonId) {
    return hasPhase(dragonId, 'final');
  }

  // Get Image path for dragon default to highest unlocked or get specific phase
  String getDragonImageUrl(String dragonId, {String? forPhase}) {
    final dragon = _dragons[dragonId];
    if (dragon == null) return '';

    String? normalizePhase = forPhase;
    if (normalizePhase != null) {
      normalizePhase = _normalizePhase(normalizePhase);
    }

    // If not looking for a specific phase use the highest unlocked phase
    final phase = normalizePhase ?? getDragonHighestPhase(dragonId);

    // Use the phaseImages map from the Dragon model
    return dragon.phaseImages[phase] ?? dragon.phaseImages['egg'] ?? '';
  }

  // === Load Dragons ===
  Future<void> loadUserDragons() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dragonService.initialize();
      await _loadUserProgress();

      // Get User
      final user = _userState.currentUser;
      if (user == null) {
        _unlockedDragonPhases = {};
        _dragons = {};
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get user's dragons data
      final response = await _dragonService.supabase
          .from('Users')
          .select('dragons')
          .eq('id', user.id)
          .single();

      final dragonsData = response['dragons'] as Map<String, dynamic>?;
      if (dragonsData == null) {
        _unlockedDragonPhases = {};
        _dragons = {};
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get the dragons the user has and unlocked phases
      final Map<String, dynamic> dragonIdsAndPhases = {};
      dragonsData.forEach((key, phases) {
        if (key != 'current_dragon_env' && phases is List) {
          dragonIdsAndPhases[key] = phases;
        }
      });

      // Only get the user dragons that belong to this class

      final classData = await _classService.getUserClass(user.id);
      if (classData.isEmpty) {
        _unlockedDragonPhases = {};
        _dragons = {};
        _isLoading = false;
        notifyListeners();
        return;
      }

      final classAssets = await _classService.getClassAssets(classData['id']);
      if (classAssets == null) {
        _unlockedDragonPhases = {};
        _dragons = {};
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Add dragons to temp list
      final tempDragons = <String, Dragon>{};
      final tempDragonModuleId = <String, Dragon>{};
      for (var asset in classAssets) {
        if (asset['type'] != 'dragon') {
          continue;
        }
        else {
          final dragonId = asset['id'];

          if (dragonIdsAndPhases.containsKey(dragonId)) {
            final phaseOrder = ['egg', 'stage1', 'stage2', 'final'];

            final Map<String, String> images = {
              phaseOrder[0]: asset['stages']['egg'] ?? '',
              phaseOrder[1]: asset['stages']['baby'] ?? '',
              phaseOrder[2]: asset['stages']['teen'] ?? '',
              phaseOrder[3]: asset['stages']['adult'] ?? '',
            };

            final tempDragon = Dragon(
              id: dragonId,
              speciesName: asset['name'] ?? 'Unknown Dragon',
              moduleId: asset['moduleId'] ?? '',
              phaseImages: images,
              phaseOrder: phaseOrder,
              preferredEnvironment: 'Mountain', // Default value
              favoriteItem: asset['favorite_item'] ?? 'Unknown',
              name: asset['name'] ?? 'Unknown Dragon',
            );


            tempDragons[dragonId] = tempDragon;

            if (asset['moduleId'] != null) {
              tempDragonModuleId[asset['moduleId']] = tempDragon;
            }
          }
        }
      }

      // Sort the tempDragon list by module id
      final sortedDragons = tempDragons.entries.toList()
        ..sort((a, b) => a.value.moduleId.compareTo(b.value.moduleId));

      // Assign dragons to sortedDragons
      _dragons = Map.fromEntries(sortedDragons);

      // Rebuild Dragons by module id
      _dragonsByModuleId = tempDragonModuleId;

      // Rebuild _unlockedDragonPhases in sorted order
      _unlockedDragonPhases = {};
      for (final dragon in sortedDragons) {
        final dragonId = dragon.key;
        if (dragonIdsAndPhases.containsKey(dragonId)) {
          _unlockedDragonPhases[dragonId] = List<String>.from(dragonIdsAndPhases[dragonId]!);
        }
      }

      _isLoading = false;
      notifyListeners();

    } catch (e) {
      print('❌ DragonProvider: Error loading user dragons: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProgress() async {
    try {
      // Get User
      final user = _userState.currentUser;
      if (user == null) {
        _isLoading = false;
        throw Exception('User is null');
      }

      // Get module list
      final classData = await _classService.getUserClass(user.id);

      if (classData.isEmpty) {
        _isLoading = false;
        throw Exception('Class Data is missing for user ${user.id}');
      }

      // Get class modules
      final modules = await _classService.getClassModules(classData['id']);

      // Get module progress
      final moduleIds = modules.map((m) => m['id'] as String).toList();
      final moduleProgress = await _quizService.getModuleProgress(
        userId: user.id,
        moduleIds: moduleIds,
      );

      for (var moduleId in moduleProgress.keys) {
        // Get the dragon for that module
        final dragon = getDragonByModuleId(moduleId);
        if (dragon == null) continue;

        String dragonId = dragon.id;

        // for progress calculate unlocked phases
        final progress = moduleProgress[moduleId];
        if (progress == null) {
          throw Exception('Progress for module "$moduleId" is missing.');
        }

        List<String> phases = ['egg']; // Always start with egg
        if (progress >= 30) {
          phases.add('stage1'); // Add stage 1 phase
        }
        if (progress >= 50) {
          phases.add('stage2'); // Add stage 2 phase
        }
        if (progress >= 80) {
          phases.add('final'); // Add final phase
        }

        // Check current dragon data
        final response = await _quizService.supabase
            .from('Users')
            .select('dragons')
            .eq('id', user.id)
            .single();

        Map<String, List<String>> currentDatabaseDragonData = {};
        if (response['dragons'] != null) {
          final dragonsMap = Map<String, dynamic>.from(response['dragons']);
          dragonsMap.forEach((key, value) {
            if (value is List) {
              currentDatabaseDragonData[key] = List<String>.from(value);
            }
          });
        }

        // Did the current and new change?
        final currentPhases = currentDatabaseDragonData[dragonId];
        if (currentPhases == null || !_areListsEqual(currentPhases, phases)) {
          currentDatabaseDragonData[dragonId] = phases;

          // Update database
          await _quizService.supabase
              .from('Users')
              .update({'dragons': currentDatabaseDragonData})
              .eq('id', user.id);
        }

        // Update provider's unlocked dragon phase data
        _unlockedDragonPhases = currentDatabaseDragonData;
      }

      notifyListeners();
    } catch (e) {
      print('❌ DragonProvider: Error loading user progress: $e');
    }
  }

  // === Helper ===
  bool _areListsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}