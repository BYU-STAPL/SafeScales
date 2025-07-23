import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/dragon_service.dart';
import 'package:safe_scales/services/class_service.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/models/dragon.dart';

class DragonStateManager {
  static const List<String> PHASE_ORDER = ['egg', 'stage1', 'stage2', 'final'];

  // Phase name mappings for backward compatibility
  static const Map<String, String> PHASE_ALIASES = {
    'baby': 'stage1',
    'teen': 'stage2',
    'adult': 'final',
  };

  final UserStateService _userState = UserStateService();
  late final DragonService _dragonService;
  late final ClassService _classService;

  Map<String, List<String>> _userDragons = {};
  Map<String, Dragon> _dragons = {};
  String? _currentEnvironment;
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
  Map<String, List<String>> get userDragons => _userDragons;
  Map<String, Dragon> get dragons => _dragons;
  String? get currentEnvironment => _currentEnvironment;
  bool get isLoading => _isLoading;

  // Initialize the dragon service
  Future<void> initialize() async {
    await _dragonService.initialize();
  }


  // ==== GET Dragon Functions ====

  Dragon? getDragonById(String dragonId) {
    final dragon = _dragons[dragonId];
    if (dragon == null) return null;
    return dragon;
  }

  Dragon? getDragonByModuleId(String moduleId) {
    return _findDragonByModuleId(moduleId);
  }

  List<Dragon?> getAllDragons() {
    return _userDragons.keys
        .map((dragonId) => getDragonById(dragonId))
        .where((data) => data != null)
        .toList();
  }


  // ==== GET Dragon Phase Functions ====

  /// Normalize phase name (handle legacy names)
  String _normalizePhase(String phase) {
    return PHASE_ALIASES[phase] ?? phase;
  }

  /// Get highest unlocked phase for a dragon
  String getDragonHighestPhase(String dragonId) {
    final phases = _userDragons[dragonId] ?? [];

    // Check phases in reverse order (highest to lowest)
    for (int i = PHASE_ORDER.length - 1; i >= 0; i--) {
      final phase = PHASE_ORDER[i];
      if (phases.any((p) => _normalizePhase(p) == phase)) {
        return phase;
      }
    }

    return 'egg';
  }

  /// Get dragon image URL for highest or requested phase
  String getDragonImageUrl(String dragonId, {String? forPhase}) {
    final dragon = _dragons[dragonId];
    if (dragon == null) return '';

    String? normalizePhase = forPhase;
    if (normalizePhase != null) {
      normalizePhase = _normalizePhase(normalizePhase);
    }

    // If not looking for a specific phase use the highest unlocked phase
    final phase = normalizePhase ?? getDragonHighestPhase(dragonId);

    String image = dragon.eggImage;
    switch (phase) {
      case 'final':
        image = dragon.finalImage;
        break;
      case 'stage2':
        image = dragon.stage2Image;
        break;

      case 'stage1':
        image = dragon.stage1Image;
        break;

      default:
        image = dragon.eggImage;
        break;
    }

    return image;
  }

  /// Get dragon image for lesson based on progress
  String getDragonImageUrlForLesson(String moduleId) {

    // if (progress >= 80) {
    //   phase = 'final';
    // }
    // else if (progress >= 50) {
    //   phase = 'stage2';
    // }
    // else if (progress >= 30) {
    //   phase = 'stage1';
    // }

    final dragon = _findDragonByModuleId(moduleId);

    if (dragon != null) {
      return getDragonImageUrl(dragon.id);
    }

      // Fallback to default images
    return getDragonImageUrl('egg');
  }

  /// Check if dragon has unlocked a specific phase
  bool hasPhase(String dragonId, String phase) {
    final phases = _userDragons[dragonId] ?? [];
    final normalizedPhase = _normalizePhase(phase);
    return phases.any((p) => _normalizePhase(p) == normalizedPhase);
  }

  /// Get phase display name
  String getPhaseDisplayName(String phase) {
    const displayNames = {
      'egg': 'Egg',
      'stage1': 'Baby',
      'stage2': 'Teen',
      'final': 'Adult',
    };
    return displayNames[phase] ?? 'Unknown';
  }

  /// Check if play is unlocked (final phase reached)
  bool isPlayUnlocked(String dragonId) {
    return hasPhase(dragonId, 'final');
  }

  String getUserPreferredPhase(String dragonId) {
    /// TODO: Implement user preference storage
    // For now, return the current phase
    // In the future, this could check user preferences from database
    return getDragonHighestPhase(dragonId);
  }

  /// Load user dragons from database
  Future<void> loadUserDragons() async {
    try {
      _isLoading = true;
      await _dragonService.initialize();

      final user = _userState.currentUser;
      if (user == null) {
        _userDragons = {};
        _dragons = {};
        _currentEnvironment = null;
        _isLoading = false;
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
        _userDragons = {};
        _dragons = {};
        _currentEnvironment = null;
        _isLoading = false;
        return;
      }

      // Extract environment and dragons
      _currentEnvironment = dragonsData['current_dragon_env'] as String?;

      final userDragons = <String, List<String>>{};
      dragonsData.forEach((key, value) {
        if (key != 'current_dragon_env' && value is List) {
          userDragons[key] = value.map((phase) => phase.toString()).toList();
        }
      });

      // Get user's class and filter dragons
      await _loadDragonDetailsForClass(user.id, userDragons);

      _isLoading = false;
    } catch (e) {
      print('❌ Error loading user dragons: $e');
      _isLoading = false;
    }
  }

  /// Save environment selection
  Future<void> saveEnvironmentSelection(String dragonId, String environmentId) async {
    try {
      final user = _userState.currentUser;
      if (user == null) return;

      // Prepare updated dragons data
      final updatedDragons = <String, dynamic>{
        'current_dragon_env': environmentId,
      };

      // Add all existing dragon phases
      _userDragons.forEach((key, phases) {
        updatedDragons[key] = phases;
      });

      // Ensure the dragon exists
      if (!updatedDragons.containsKey(dragonId)) {
        updatedDragons[dragonId] = <String>[];
      }

      // Update database
      await _dragonService.supabase
          .from('Users')
          .update({'dragons': updatedDragons})
          .eq('id', user.id);

      // Update local state
      _currentEnvironment = environmentId;

      print('✅ Environment selection saved successfully');
    } catch (e) {
      print('❌ Error saving environment selection: $e');
    }
  }

  // Private helper methods
  Dragon? _findDragonByModuleId(String moduleId) {
    for (final dragon in _dragons.values) {
      if (dragon.moduleId == moduleId) {
        return dragon;
      }
    }
    return null;
  }

  // String _getImageForPhase(Dragon dragon, String phase) {
  //   switch (phase) {
  //     case 'final':
  //       return dragon.finalImage;
  //     case 'stage2':
  //       return dragon.stage2Image;
  //     case 'stage1':
  //       return dragon.stage1Image;
  //     default:
  //       return dragon.eggImage;
  //   }
  // }

  String _getDefaultImageForPhase(String phase) {
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

  Future<void> _loadDragonDetailsForClass(String userId, Map<String, List<String>> userDragons) async {
    final userClass = await _classService.getUserClass(userId);
    if (userClass.isEmpty) {
      print('⚠️ No class found for user');
      _userDragons = {};
      _dragons = {};
      return;
    }

    final classAssets = await _classService.getClassAssets(userClass['id']);
    if (classAssets == null) {
      _userDragons = {};
      _dragons = {};
      return;
    }

    final dragons = <String, Dragon>{};
    final filteredUserDragons = <String, List<String>>{};

    // Process class dragon assets
    for (var asset in classAssets) {
      if (asset['type'] == 'dragon') {
        final dragonId = asset['id'];

        // Only include if user has this dragon
        if (userDragons.containsKey(dragonId)) {

          final phaseOrder = ['egg', 'baby', 'teen', 'adult'];

          final Map<String, String> images = {
            phaseOrder[0]: asset['stages']['egg'] ?? '',
            phaseOrder[1]: asset['stages']['baby'] ?? '',
            phaseOrder[2]: asset['stages']['teen'] ?? '',
            phaseOrder[3]: asset['stages']['adult'] ?? '',
          };

          dragons[dragonId] = Dragon(
            id: dragonId,
            speciesName: asset['name'] ?? 'Unknown Dragon',
            moduleId: asset['moduleId'] ?? '',
            phaseImages: images,
            phaseOrder: phaseOrder,
            preferredEnvironment: 'Mountain', // Default value
            favoriteItem: asset['favorite_item'] ?? 'Unknown',
            name: asset['name'] ?? 'Unknown Dragon',
          );

          filteredUserDragons[dragonId] = userDragons[dragonId]!;
        }
      }
    }

    // Sort by module ID (ascending)
    final sortedEntries = dragons.entries.toList()
      ..sort((a, b) => b.value.moduleId.compareTo(a.value.moduleId));

    _dragons = Map.fromEntries(sortedEntries);

    // Rebuild user dragons in sorted order
    _userDragons = {};
    for (final entry in sortedEntries) {
      final dragonId = entry.key;
      if (filteredUserDragons.containsKey(dragonId)) {
        _userDragons[dragonId] = filteredUserDragons[dragonId]!;
      }
    }
  }
}