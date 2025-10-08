import '../models/dragon.dart';
import '../models/lesson_progress.dart';
import '../repositories/dragon_repository.dart';
import 'course_service.dart';

/// Service that handles all dragon-related business logic
/// This layer processes data from repository and applies business rules
class DragonService {
  final DragonRepository _repository;
  final CourseService _courseService;

  // DragonService(this._repository);

  DragonService({required courseService, DragonRepository? repository})
    : _repository = repository ?? DragonRepository(),
      _courseService = courseService;

  // Phase constants and mappings
  static const List<String> phaseOrder = ['egg', 'stage1', 'stage2', 'final'];

  static const Map<String, String> phaseAliases = {
    'baby': 'stage1',
    'teen': 'stage2',
    'adult': 'final',
  };

  static const Map<String, String> phaseDisplayNames = {
    'egg': 'Egg',
    'stage1': 'Baby',
    'stage2': 'Teen',
    'final': 'Adult',
  };

  // Progress thresholds for dragon phase unlocking
  // Note: Progress uses full percent not decimals
  static const Map<String, double> phaseThresholds = {
    'egg': 0.0,
    'stage1': 30.0,
    'stage2': 50.0,
    'final': 80.0,
  };

  // === Phase Utilities ===

  /// Normalize phase names (handle legacy names)
  String normalizePhase(String phase) {
    return phaseAliases[phase] ?? phase;
  }

  /// Get display name for a phase
  String getPhaseDisplayName(String phase) {
    return phaseDisplayNames[normalizePhase(phase)] ?? 'Unknown';
  }

  /// Calculate unlocked phases based on progress percentage
  List<String> calculateUnlockedPhases(double progressPercent) {
    final unlockedPhases = <String>[];

    for (final phase in phaseOrder) {
      final threshold = phaseThresholds[phase] ?? 100.0;
      if (progressPercent >= threshold) {
        unlockedPhases.add(phase);
      }
    }

    return unlockedPhases;
  }

  /// Get the highest unlocked phase for given phases list
  String getHighestUnlockedPhase(List<String> unlockedPhases) {
    for (int i = phaseOrder.length - 1; i >= 0; i--) {
      final phase = phaseOrder[i];
      if (unlockedPhases.any(
        (p) => normalizePhase(p) == normalizePhase(phase),
      )) {
        return phase;
      }
    }
    return 'egg'; // Default to egg if nothing unlocked
  }

  /// Check if a specific phase is unlocked
  bool isPhaseUnlocked(List<String> unlockedPhases, String phase) {
    final normalizedPhase = normalizePhase(phase);
    return unlockedPhases.any((p) => normalizePhase(p) == normalizedPhase);
  }

  /// Check if play mode is unlocked (final phase reached)
  bool isPlayUnlocked(List<String> unlockedPhases) {
    return isPhaseUnlocked(unlockedPhases, 'final');
  }

  // === Data Processing ===

  /// Process raw user dragons data and class assets into Dragon objects
  Map<String, Dragon> processUserDragons(
    Map<String, dynamic> userDragonsData,
    List<Map<String, dynamic>> classAssets,
  ) {
    final dragons = <String, Dragon>{};

    // Process each dragon asset
    for (final asset in classAssets) {
      if (asset['type'] != 'dragon') continue;

      final dragonId = asset['id'] as String?;
      if (dragonId == null) continue;

      // Initialize phases list for new dragons
      if (!userDragonsData.containsKey(dragonId)) {
        userDragonsData[dragonId] = ['egg'];
      }

      final dragon = _createDragonFromAsset(
        userDragonsData[dragonId],
        asset,
        dragonId,
      );
      if (dragon != null) {
        dragons[dragonId] = dragon;
      }
    }
    return dragons;
  }

  /// Process dragons from Supabase dragons table into Dragon objects
  Map<String, Dragon> processDragonsFromSupabase(
    Map<String, dynamic> userDragonsData,
    List<Map<String, dynamic>> supabaseDragons,
  ) {
    final dragons = <String, Dragon>{};

    // Process each dragon from Supabase
    for (final dragonData in supabaseDragons) {
      final dragonId = dragonData['id']?.toString();
      if (dragonId == null || dragonId.isEmpty) continue;

      // Initialize phases list for new dragons
      if (!userDragonsData.containsKey(dragonId)) {
        userDragonsData[dragonId] = ['egg'];
      }

      // Get user dragon info, handling both Map and List formats
      final userDragonInfo = userDragonsData[dragonId];

      final dragon = _createDragonFromSupabaseData(userDragonInfo, dragonData);
      if (dragon != null) {
        dragons[dragonId] = dragon;
      }
    }

    return dragons;
  }

  /// Create Dragon object from asset data
  Dragon? _createDragonFromAsset(
    dynamic userDragonInfo,
    Map<String, dynamic> asset,
    String dragonId,
  ) {
    try {
      final stages = asset['stages'] as Map<String, dynamic>?;
      if (stages == null) {
        return null;
      }

      final images = <String, String>{
        'egg': stages['egg']?.toString() ?? '',
        'stage1': stages['baby']?.toString() ?? '',
        'stage2': stages['teen']?.toString() ?? '',
        'final': stages['adult']?.toString() ?? '',
      };

      final moduleId = asset['moduleId']?.toString() ?? '';

      // Handle different user dragon info formats
      String dragonName = 'Unnamed';
      if (userDragonInfo is Map<String, dynamic>) {
        dragonName = userDragonInfo['name']?.toString() ?? 'Unnamed';
      } else if (userDragonInfo is List) {
        // Legacy format - just phases list, no name
        dragonName = 'Unnamed';
      }

      return Dragon(
        id: dragonId,
        speciesName: asset['name']?.toString() ?? 'Unknown Species',
        moduleId: moduleId,
        phaseImages: images,
        phaseOrder: phaseOrder,
        preferredEnvironment:
            asset['favorite_item']?.toString() ?? 'Unknown', // Default value
        favoriteItem: asset['favorite_item']?.toString() ?? 'Unknown',
        name: dragonName,
      );
    } catch (e) {
      print('❌ Error creating dragon from asset: $e');
      return null;
    }
  }

  /// Create Dragon object from Supabase dragons table data
  Dragon? _createDragonFromSupabaseData(
    dynamic userDragonInfo,
    Map<String, dynamic> dragonData,
  ) {
    try {
      final dragonId = dragonData['id']?.toString() ?? '';
      if (dragonId.isEmpty) return null;

      print('🐉 Creating dragon for ID: $dragonId');
      print('🐉 Raw dragon data: $dragonData');

      // Extract image URLs from Supabase storage
      final images = <String, String>{
        'egg': dragonData['egg_image']?.toString() ?? '',
        'stage1': dragonData['stage1_image']?.toString() ?? '',
        'stage2': dragonData['stage2_image']?.toString() ?? '',
        'final': dragonData['final_stage_image']?.toString() ?? '',
      };

      print('🐉 Extracted images: $images');

      // Handle different user dragon info formats
      String dragonName = 'Unnamed';
      if (userDragonInfo is Map<String, dynamic>) {
        dragonName = userDragonInfo['name']?.toString() ?? 'Unnamed';
      } else if (userDragonInfo is List) {
        // Legacy format - just phases list, no name
        dragonName = 'Unnamed';
      }

      final dragon = Dragon(
        id: dragonId,
        speciesName:
            dragonData['species_name']?.toString() ?? 'Unknown Species',
        moduleId: dragonData['module_id']?.toString() ?? '',
        phaseImages: images,
        phaseOrder: phaseOrder,
        preferredEnvironment:
            dragonData['preferred_environment']?.toString() ?? 'Unknown',
        favoriteItem: dragonData['favorite_item']?.toString() ?? 'Unknown',
        name: dragonName,
      );

      print('🐉 Created dragon: ${dragon.speciesName}');
      print('🐉 Dragon phase images: ${dragon.phaseImages}');

      return dragon;
    } catch (e) {
      print('❌ Error creating dragon from Supabase data: $e');
      return null;
    }
  }

  /// Create dragons map indexed by module ID
  Map<String, Dragon> createDragonsByModuleMap(Map<String, Dragon> dragons) {
    final dragonsByModule = <String, Dragon>{};

    for (final dragon in dragons.values) {
      if (dragon.moduleId.isNotEmpty) {
        dragonsByModule[dragon.moduleId] = dragon;
      }
    }

    return dragonsByModule;
  }

  /// Sort dragons by module ID
  Map<String, Dragon> sortDragonsByModuleId(Map<String, Dragon> dragons) {
    final sortedEntries =
        dragons.entries.toList()
          ..sort((a, b) => b.value.moduleId.compareTo(a.value.moduleId));

    return Map.fromEntries(sortedEntries);
  }

  /// Extract only unlocked phases for dragons in a specific class
  Map<String, List<String>> extractClassDragonPhases(
    Map<String, dynamic> userDragonsData,
    List<Map<String, dynamic>> classAssets,
  ) {
    final classUnlockedPhases = <String, List<String>>{};

    // Get dragon IDs that exist in this class
    final classDragonIds = <String>{};
    for (final asset in classAssets) {
      if (asset['type'] == 'dragon' && asset['id'] != null) {
        classDragonIds.add(asset['id'] as String);
      }
    }

    // Filter user dragons to only include those in this class
    userDragonsData.forEach((key, data) {
      if (classDragonIds.contains(key)) {
        List<String> phases = [];

        if (data is List) {
          // Legacy format - data is directly the phases list
          phases = data.cast<String>();
        } else if (data is Map && data.containsKey('phases')) {
          // New format - phases are in a 'phases' key
          final phasesData = data['phases'];
          if (phasesData is List) {
            phases = phasesData.cast<String>();
          }
        }

        if (phases.isNotEmpty) {
          classUnlockedPhases[key] = phases;
        }
      }
    });
    return classUnlockedPhases;
  }

  // === Business Logic Methods ===

  /// Update dragon phases based on lesson progress
  Future<void> updateDragonProgressForLesson(
    String userId,
    String dragonId,
    String lessonId,
  ) async {
    // Ask Course Service for lesson progress
    LessonProgress? lessonProgress = await _courseService.getLessonProgress(
      userId,
      lessonId,
    );

    if (lessonProgress == null) {
      throw DragonServiceException(
        'Progress for module "$lessonId" is missing.',
      );
    }

    final progressPercent = lessonProgress.getProgressPercent();
    final newPhases = calculateUnlockedPhases(progressPercent);

    await _repository.updateUserDragonPhases(userId, dragonId, newPhases);
  }

  /// Validate that a dragon exists before updating
  void validateDragonExists(
    String dragonId,
    Map<String, List<String>> existingPhases,
  ) {
    if (!existingPhases.containsKey(dragonId)) {
      throw DragonServiceException('Dragon with ID $dragonId does not exist');
    }
  }

  /// Get image URL for dragon at specific or highest unlocked phase
  String getDragonImageUrl(
    Dragon dragon,
    List<String> unlockedPhases, {
    String? forPhase,
  }) {
    String phase;

    if (forPhase != null) {
      phase = normalizePhase(forPhase);
    } else {
      phase = getHighestUnlockedPhase(unlockedPhases);
    }

    return dragon.phaseImages[phase] ?? dragon.phaseImages['egg'] ?? '';
  }

  // === Repository Delegates ===

  /// Get all dragons from database
  Future<List<Map<String, dynamic>>> getAllDragons() async {
    return await _repository.fetchAllDragons();
  }

  /// Get user's dragons data
  Future<Map<String, dynamic>> getUserDragonsData(String userId) async {
    return await _repository.fetchUserDragons(userId);
  }

  /// Get class assets
  Future<List<Map<String, dynamic>>> getClassAssets(String classId) async {
    return await _repository.fetchClassAssets(classId);
  }

  Future<void> updateUserPreferredPhase(
    String userId,
    String dragonId,
    String phase,
  ) async {
    String normalizedPhase = normalizePhase(phase);

    return await _repository.updateUserPreferredPhase(
      userId,
      dragonId,
      normalizedPhase,
    );
  }

  Future<Map<String, String>> loadUserPreferredPhases(String userId) async {
    return await _repository.fetchUserPreferredPhases(userId);
  }

  /// Update dragon name
  Future<void> updateDragonName(
    String userId,
    String dragonId,
    String newName,
    int maxNameLength,
  ) async {
    try {
      // Validate name
      final trimmedName = newName.trim();
      if (trimmedName.isEmpty) {
        throw DragonServiceException('Dragon name cannot be empty');
      }

      // Limit name length to 10 characters
      if (trimmedName.length > maxNameLength) {
        throw DragonServiceException(
          'Dragon name cannot be longer than $maxNameLength characters',
        );
      }

      // Update name in repository
      await _repository.updateDragonName(userId, dragonId, trimmedName);
    } catch (e) {
      throw DragonServiceException('Failed to update dragon name: $e');
    }
  }
}

/// Custom exception for service operations
class DragonServiceException implements Exception {
  final String message;
  DragonServiceException(this.message);

  @override
  String toString() => 'DragonServiceException: $message';
}
