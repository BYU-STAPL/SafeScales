// import 'dart:core';
//
// import 'package:flutter/cupertino.dart';
// import 'package:safe_scales/models/lesson_progress.dart';
//
// import 'package:safe_scales/services/class_service.dart';
// import 'package:safe_scales/services/old_dragon_service.dart';
// import 'package:safe_scales/services/user_progress_service.dart';
// import 'package:safe_scales/services/user_state_service.dart';
//
// import 'package:safe_scales/models/dragon.dart';
//
// import '../models/user.dart';
// import '../services/quiz_service.dart';
//
// class OldDragonProvider extends ChangeNotifier {
//   // === For tracking growth phases ===
//   static const List<String> phaseOrder = ['egg', 'stage1', 'stage2', 'final'];
//
//   static const Map<String, String> phaseAliases = {
//     'baby': 'stage1',
//     'teen': 'stage2',
//     'adult': 'final',
//   };
//
//   /// Normalize phase name (handle legacy names)
//   String _normalizePhase(String phase) {
//     return phaseAliases[phase] ?? phase;
//   }
//
//   // === Data ===
//   bool _isLoading = false;
//
//   // === Dragon Data ===
//   Map<String, Dragon> _dragons = {};
//   Map<String, List<String>> _unlockedDragonPhases = {}; // DragonID to list of phases unlocked for the dragon
//   Map<String, Dragon> _dragonsByModuleId = {};
//
//   String? _currentEnvironment;
//   Map<String, String> _preferredPhases = {}; // DragonID to preferred phase string
//
//   // === Services ===
//   final UserStateService _userState = UserStateService();
//   final QuizService _quizService = QuizService();
//
//
//   final UserProgressService _userProgressService = UserProgressService();
//   late final OldDragonService _dragonService;
//   late final ClassService _classService;
//
//   // === init ===
//   OldDragonProvider() {
//     _dragonService = OldDragonService(_quizService.supabase);
//     _classService = ClassService(_quizService.supabase);
//   }
//
//   Future<void> initialize() async {
//     await _dragonService.initialize();
//     await loadUserDragons();
//
//     print('DragonProvider finished loading');
//     print(_dragons);
//   }
//
//   // === GETTERS ===
//   bool get isLoading => _isLoading;
//
//   Map<String, Dragon> get dragons => _dragons;
//   Map<String, List<String>> get unlockedDragonPhases => _unlockedDragonPhases;
//   String? get currentEnvironment => _currentEnvironment;
//
//
//   Dragon? getDragonById(String dragonId) {
//     return _dragons[dragonId];
//   }
//
//   Dragon? getDragonByModuleId(String moduleId) {
//     return _dragonsByModuleId[moduleId];
//   }
//
//   List<Dragon> getAllDragons() {
//     return _dragons.values.toList();
//   }
//
//   bool hasPhase(String dragonId, String phase) {
//     final phases = _unlockedDragonPhases[dragonId] ?? [];
//     final normalizedPhase = _normalizePhase(phase);
//     return phases.any((p) => _normalizePhase(p) == normalizedPhase);
//   }
//
//   String getPhaseDisplayName(String phase) {
//     const displayNames = {
//       'egg': 'Egg',
//       'stage1': 'Baby',
//       'stage2': 'Teen',
//       'final': 'Adult',
//     };
//     return displayNames[phase] ?? 'Unknown';
//   }
//
//   /// Get highest unlocked phase for a dragon
//   String getDragonHighestPhase(String dragonId) {
//     // Check phases in reverse order (highest to lowest)
//     for (int i = phaseOrder.length - 1; i >= 0; i--) {
//       final phase = phaseOrder[i];
//       if(hasPhase(dragonId, phase)) {
//         return phase;
//       }
//     }
//
//     return 'egg';
//   }
//
//   String getUserPreferredPhase(String dragonId) {
//     /// TODO: Implement user preference for dragon phase
//     // For now, return the current phase
//     // In the future, this could check user preferences from database
//     return getDragonHighestPhase(dragonId);
//   }
//
//   /// Check if play is unlocked (final phase reached)
//   bool isPlayUnlocked(String dragonId) {
//     return hasPhase(dragonId, 'final');
//   }
//
//   // Get Image path for dragon default to highest unlocked or get specific phase
//   String getDragonImageUrl(String dragonId, {String? forPhase}) {
//     final dragon = _dragons[dragonId];
//     if (dragon == null) return '';
//
//     String? normalizePhase = forPhase;
//     if (normalizePhase != null) {
//       normalizePhase = _normalizePhase(normalizePhase);
//     }
//
//     // If not looking for a specific phase use the highest unlocked phase
//     final phase = normalizePhase ?? getDragonHighestPhase(dragonId);
//
//     // Use the phaseImages map from the Dragon model
//     return dragon.phaseImages[phase] ?? dragon.phaseImages['egg'] ?? '';
//   }
//
//   // === Load Dragons ===
//   Future<void> loadUserDragons() async {
//     try {
//       _isLoading = true;
//       notifyListeners();
//
//       print('LOAD USER DRAGONS');
//
//       await _dragonService.initialize();
//
//       // Get User
//       final user = _userState.currentUser;
//       if (user == null) {
//         _unlockedDragonPhases = {};
//         _dragons = {};
//         _currentEnvironment = null;
//         _preferredPhases = {};
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }
//
//       final classData = await _classService.getUserClass(user.id);
//       if (classData.isEmpty) {
//         _unlockedDragonPhases = {};
//         _dragons = {};
//         _currentEnvironment = null;
//         _preferredPhases = {};
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }
//
//       _dragons = await _dragonService.getUserDragons(user.id, classData['id']);
//
//       // Rebuild Dragons by module id
//       _dragonsByModuleId = await _dragonService.getUserDragonsWithLessonId(user.id, classData['id']);
//
//       // Rebuild _unlockedDragonPhases in sorted order
//       _unlockedDragonPhases = await _dragonService.getUnlockedPhases(user.id, classData['id']);
//
//       // Extract environment
//       _currentEnvironment = await _dragonService.getCurrentEnvironment(user.id);
//
//       // TODO: Extract Preferred Phases
//       _preferredPhases = {};
//
//       _isLoading = false;
//       notifyListeners();
//
//     } catch (e) {
//       print('❌ DragonProvider: Error loading user dragons: $e');
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> updateDragonPhases(String lessonId) async {
//     try {
//       // Get dragon associated with this lesson
//       final dragon = getDragonByModuleId(lessonId);
//       if (dragon == null) return;
//
//       String dragonId = dragon.id;
//
//       // Get user
//       User? user = _userState.currentUser;
//       if (user == null) return;
//
//       LessonProgress? lessonProgress = await _userProgressService.loadSingleLessonProgress(user.id, lessonId);
//
//       // Calculate the new unlocked phases
//       if (lessonProgress == null) {
//         throw Exception('Progress for module "$lessonId" is missing.');
//       }
//
//       double progress = lessonProgress.getProgressPercent();
//
//       List<String> phases = ['egg']; // Always start with egg
//       if (progress >= 30) {
//         phases.add('stage1'); // Add stage 1 phase
//       }
//       if (progress >= 50) {
//         phases.add('stage2'); // Add stage 2 phase
//       }
//       if (progress >= 80) {
//         phases.add('final'); // Add final phase
//       }
//
//       await _dragonService.updateUnlockedPhasesForDragon(user.id, dragonId, phases);
//
//     }
//     catch (e) {
//       print('❌ DragonProvider: Error updating dragon progress $e');
//     }
//
//   }
//
//   Future<void> updateAllDragonProgress() async {
//     try {
//       // Get User
//       final user = _userState.currentUser;
//       if (user == null) {
//         _isLoading = false;
//         throw Exception('User is null');
//       }
//
//       // Get module list
//       final classData = await _classService.getUserClass(user.id);
//
//       if (classData.isEmpty) {
//         _isLoading = false;
//         throw Exception('Class Data is missing for user ${user.id}');
//       }
//
//       // Get class modules
//       final modules = await _classService.getClassModules(classData['id']);
//
//       // Get module progress
//       final moduleIds = modules.map((m) => m['id'] as String).toList();
//       final moduleProgress = await _quizService.getModuleProgress(
//         userId: user.id,
//         moduleIds: moduleIds,
//       );
//
//       for (var lessonId in moduleProgress.keys) {
//         updateDragonPhases(lessonId);
//       }
//
//       // Update provider's unlocked dragon phase data
//       _unlockedDragonPhases = await _dragonService.getUnlockedPhases(user.id, classData['id']);
//
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _isLoading = false;
//       print('❌ DragonProvider: Error loading user progress: $e');
//     }
//   }
//
//   // === Load Environment ===
//   Future<void> saveEnvironmentSelection(String dragonId, String environmentId) async {
//     try {
//       final user = _userState.currentUser;
//       if (user == null) return;
//
//       // Prepare updated dragons data
//       final updatedDragons = <String, dynamic>{
//         'current_dragon_env': environmentId,
//       };
//
//       // Add all existing dragon phases
//       _unlockedDragonPhases.forEach((key, phases) {
//         updatedDragons[key] = phases;
//       });
//
//       // Ensure the dragon exists
//       if (!updatedDragons.containsKey(dragonId)) {
//         updatedDragons[dragonId] = <String>[];
//       }
//
//       // Update database
//       await _dragonService.supabase
//           .from('Users')
//           .update({'dragons': updatedDragons})
//           .eq('id', user.id);
//
//       // Update local state
//       _currentEnvironment = environmentId;
//
//       print('✅ Environment selection saved successfully');
//     } catch (e) {
//       print('❌ Error saving environment selection: $e');
//     }
//   }
// }