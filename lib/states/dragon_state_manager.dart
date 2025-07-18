import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/dragon_service.dart';
import 'package:safe_scales/services/class_service.dart';
import 'package:safe_scales/services/quiz_service.dart';

class DragonStateManager {
  static const List<String> PHASE_ORDER = ['egg', 'stage1', 'stage2', 'final'];

  final UserStateService _userState = UserStateService();
  late final DragonService _dragonService;
  late final ClassService _classService;

  Map<String, dynamic> _userDragons = {};
  Map<String, Map<String, dynamic>> _dragonDetails = {};
  bool _isLoading = true;

  // Singleton pattern
  static DragonStateManager? _instance;
  DragonStateManager._internal() {
    _dragonService = DragonService(QuizService().supabase);
    _classService = ClassService(QuizService().supabase);
  }

  factory DragonStateManager() {
    _instance ??= DragonStateManager._internal();
    return _instance!;
  }

  // Getters
  Map<String, dynamic> get userDragons => _userDragons;
  Map<String, Map<String, dynamic>> get dragonDetails => _dragonDetails;
  bool get isLoading => _isLoading;

  // Initialize the dragon service
  Future<void> initialize() async {
    await _dragonService.initialize();
  }

  // Calculate current phase based on lesson progress
  String getCurrentPhase(List<String> unlockedPhases) {
    print("Current Phases");
    print(unlockedPhases);
    for (int i = PHASE_ORDER.length - 1; i >= 0; i--) {
      if (unlockedPhases.contains(PHASE_ORDER[i])) {
        return PHASE_ORDER[i];
      }
    }
    return 'egg';
  }

  // Get display phase for different contexts
  String getDisplayPhase(String dragonId, String context) {
    switch (context) {
      case 'home':
      case 'dragon_page':
        return getCurrentPhase(getUserPhases(dragonId));
      case 'play_page':
        return getUserPreferredPhase(dragonId);
      default:
        return getCurrentPhase(getUserPhases(dragonId));
    }
  }

  // Get user's phases for a specific dragon
  List<String> getUserPhases(String dragonId) {
    final phases = _userDragons[dragonId];
    if (phases is List) {
      return phases.map((phase) => phase.toString()).toList();
    }
    return [];
  }

  // Get user's preferred phase (for now, returns current phase)
  String getUserPreferredPhase(String dragonId) {
    // TODO: Implement
    return getCurrentPhase(getUserPhases(dragonId));
  }

  // Get current environment
  String? getCurrentEnvironment() {
    return _userDragons['current_dragon_env'] as String?;
  }

  // Check if a dragon has a specific phase
  bool hasPhase(String dragonId, String phase) {
    final phases = _userDragons[dragonId];
    if (phases is List) {
      // Map new phase names to old phase names for checking
      String phaseToCheck = phase;
      if (phase == 'stage1') phaseToCheck = 'baby';
      if (phase == 'stage2') phaseToCheck = 'teen';
      if (phase == 'final') phaseToCheck = 'adult';

      return phases.contains(phase) || phases.contains(phaseToCheck);
    } else if (phases is Map) {
      String phaseToCheck = phase;
      if (phase == 'stage1') phaseToCheck = 'baby';
      if (phase == 'stage2') phaseToCheck = 'teen';
      if (phase == 'final') phaseToCheck = 'adult';

      final phasesList = phases['phases'] ?? [];
      return phasesList.contains(phase) || phasesList.contains(phaseToCheck);
    }
    return false;
  }

  // Get the highest phase achieved for a dragon in terms of lesson progress
  String getHighestPhase(String dragonId) {
    final phases = _userDragons[dragonId];
    if (phases == null) return 'egg';

    if (hasPhase(dragonId, 'final') || hasPhase(dragonId, 'adult')) {
      return 'final';
    } else if (hasPhase(dragonId, 'stage2') || hasPhase(dragonId, 'teen')) {
      return 'stage2';
    } else if (hasPhase(dragonId, 'stage1') || hasPhase(dragonId, 'baby')) {
      return 'stage1';
    }
    return 'egg';
  }

  // NEW: Get dragon phase based on module progress
  String getPhaseByProgress(double progress) {
    if (progress >= 80) {
      return 'final';
    } else if (progress >= 50) {
      return 'stage2';
    } else if (progress >= 30) {
      return 'stage1';
    } else {
      return 'egg';
    }
  }

  // Get the appropriate image URL for a dragon's current phase
  String getDragonImageUrl(String dragonId) {
    final dragonData = _dragonDetails[dragonId];
    if (dragonData == null) return '';

    final currentPhase = getHighestPhase(dragonId);
    switch (currentPhase) {
      case 'final':
        return dragonData['final_stage_image'] ?? dragonData['egg_image'];
      case 'stage2':
        return dragonData['stage2_image'] ?? dragonData['egg_image'];
      case 'stage1':
        return dragonData['stage1_image'] ?? dragonData['egg_image'];
      default:
        return dragonData['egg_image'] ?? '';
    }
  }

  // NEW: Get dragon image URL based on specific phase
  String getDragonImageUrlByPhase(String dragonId, String phase) {
    final dragonData = _dragonDetails[dragonId];
    if (dragonData == null) return '';

    switch (phase) {
      case 'final':
        return dragonData['final_stage_image'] ?? dragonData['egg_image'];
      case 'stage2':
        return dragonData['stage2_image'] ?? dragonData['egg_image'];
      case 'stage1':
        return dragonData['stage1_image'] ?? dragonData['egg_image'];
      default:
        return dragonData['egg_image'] ?? '';
    }
  }

  // NEW: Get dragon for a specific module
  Map<String, dynamic>? getDragonByModuleId(String moduleId) {
    for (final entry in _dragonDetails.entries) {
      final dragonData = entry.value;
      if (dragonData['module_id'] == moduleId) {
        return {
          'id': entry.key,
          'name': dragonData['name'],
          'egg_image': dragonData['egg_image'],
          'stage1_image': dragonData['stage1_image'],
          'stage2_image': dragonData['stage2_image'],
          'final_stage_image': dragonData['final_stage_image'],
          'module_id': dragonData['module_id'],
        };
      }
    }
    return null;
  }

  // NEW: Get dragon image URL for lesson display based on progress
  String getDragonImageForLesson(String? moduleId, double progress) {
    String? dragonId;

    // Find dragon by module ID
    if (moduleId != null) {
      for (final entry in _dragonDetails.entries) {
        final dragonData = entry.value;
        if (dragonData['module_id'] == moduleId) {
          dragonId = entry.key;
          break;
        }
      }
    }

    if (dragonId == null) {
      // Fallback to default images
      final phase = getPhaseByProgress(progress);
      switch (phase) {
        case 'final':
          return 'assets/images/other/adult.png';
        case 'stage2':
          return 'assets/images/other/teen.png';
        case 'stage1':
          return 'assets/images/other/young.png';
        default:
          return 'assets/images/other/egg.png';
      }
    }

    final phase = getPhaseByProgress(progress);
    return getDragonImageUrlByPhase(dragonId, phase);
  }

  // Check if play is unlocked for a dragon
  bool isPlayUnlocked(String dragonId) {
    return hasPhase(dragonId, 'final') || hasPhase(dragonId, 'adult');
  }

  // Load user dragons from database
  Future<void> loadUserDragons() async {
    try {
      _isLoading = true;

      // Initialize dragon service
      await _dragonService.initialize();

      // Get user's dragons
      final user = _userState.currentUser;
      if (user != null) {
        // Get user's dragons data
        final response = await _dragonService.supabase
            .from('Users')
            .select('dragons')
            .eq('id', user.id)
            .single();

        if (response['dragons'] != null) {
          // Convert the dragons map to the correct types
          final dragonsMap = Map<String, dynamic>.from(response['dragons']);

          // Convert each dragon's phases from List<dynamic> to List<String>
          _userDragons = dragonsMap.map((key, value) {
            if (key == 'current_dragon_env') {
              return MapEntry(key, value);
            }
            if (value is List) {
              return MapEntry(
                key,
                value.map((phase) => phase.toString()).toList(),
              );
            }
            return MapEntry(key, value);
          });

          // Get user's current class
          final userClass = await _classService.getUserClass(user.id);
          if (userClass.isNotEmpty) {
            final classId = userClass['id'];

            // Get assets from the current class only
            final classAssets = await _classService.getClassAssets(classId);

            if (classAssets != null) {
              // Filter _userDragons to only include dragons from this class
              final sortedUserDragons = <String, dynamic>{};

              // Always keep the current_dragon_env
              if (_userDragons.containsKey('current_dragon_env')) {
                sortedUserDragons['current_dragon_env'] = _userDragons['current_dragon_env'];
              }

              const moduleIdKeyName = 'module_id';

              // Find dragons in the class assets and check if user has them
              for (var asset in classAssets) {
                if (asset['type'] == 'dragon') {
                  final dragonId = asset['id'];

                  // Only include this dragon if the user has it
                  if (_userDragons.containsKey(dragonId)) {
                    // Convert the new structure to match the expected format
                    final dragonData = {
                      'id': asset['id'],
                      'name': asset['name'],
                      // Map new stage names to old field names for compatibility
                      'egg_image': asset['stages']['egg'],
                      'stage1_image': asset['stages']['baby'],
                      'stage2_image': asset['stages']['teen'],
                      'final_stage_image': asset['stages']['adult'],
                      // Add some default values
                      'length': 15,
                      'weight': 2000,
                      'preferred_environment': 'Mountain',
                      'favorite_item': asset['favorite_item'] ?? 'Unknown',
                      moduleIdKeyName: asset['moduleId']!,
                    };

                    _dragonDetails[dragonId] = dragonData;
                  }
                }
              }

              // Sort Dragons by Module ID
              final sortedEntries = _dragonDetails.entries.toList()
                ..sort((b, a) => (a.value[moduleIdKeyName] ?? 0).compareTo(b.value[moduleIdKeyName] ?? 0));

              final sortedDragonMaps = Map.fromEntries(sortedEntries);

              // Create the Sorted User Dragons
              for (var dragonId in sortedDragonMaps.keys) {
                if (_userDragons.containsKey(dragonId)) {
                  sortedUserDragons[dragonId] = _userDragons[dragonId];
                }
              }

              _userDragons = sortedUserDragons;
            }
          } else {
            print('⚠️ No class found for user');
            // If no class found, show no dragons
            _userDragons = {};
          }
        }
      }

      _isLoading = false;

    } catch (e) {
      print('❌ Error loading user dragons: $e');
      _isLoading = false;
    }
  }

  // Save environment selection
  Future<void> saveEnvironmentSelection(String dragonId, String environmentId) async {
    try {
      final user = _userState.currentUser;
      if (user != null) {
        // Create a new map with the updated environment
        final updatedDragons = Map<String, dynamic>.from(_userDragons);

        // Add the current_dragon_env field
        updatedDragons['current_dragon_env'] = environmentId;

        // Ensure we keep the existing dragon phases
        if (!updatedDragons.containsKey(dragonId)) {
          final phases = getUserPhases(dragonId);
          updatedDragons[dragonId] = phases;
        }

        // Update the database
        await _dragonService.supabase
            .from('Users')
            .update({'dragons': updatedDragons})
            .eq('id', user.id);

        // Update local state
        _userDragons = updatedDragons;

        print('✅ Environment selection saved successfully');
      } else {
        print('❌ No user found when trying to save environment selection');
      }
    } catch (e) {
      print('❌ Error saving environment selection: $e');
    }
  }

  // Get dragon data for UI display
  Map<String, dynamic>? getDragonDisplayData(String dragonId) {
    final dragonData = _dragonDetails[dragonId];
    if (dragonData == null) return null;

    final currentPhase = getHighestPhase(dragonId);
    final imageUrl = getDragonImageUrl(dragonId);
    final isUnlocked = isPlayUnlocked(dragonId);

    return {
      'id': dragonId,
      'name': dragonData['name'] ?? 'Unknown',
      'currentPhase': currentPhase,
      'imageUrl': imageUrl,
      'favoriteItem': dragonData['favorite_item'] ?? 'Unknown',
      'favoriteEnvironment': dragonData['preferred_environment'] ?? 'Unknown',
      'isPlayUnlocked': isUnlocked,
      'phases': getUserPhases(dragonId),
    };
  }

  // Get all dragons for display
  List<Map<String, dynamic>> getAllDragonsForDisplay() {
    final List<Map<String, dynamic>> dragons = [];

    for (final entry in _userDragons.entries) {
      final dragonId = entry.key;

      // Skip non-dragon entries
      if (dragonId == 'current_dragon_env') continue;

      final displayData = getDragonDisplayData(dragonId);
      if (displayData != null) {
        dragons.add(displayData);
      }
    }

    return dragons;
  }
}