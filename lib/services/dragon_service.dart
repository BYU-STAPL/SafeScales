import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dragon.dart';

class DragonService {
  final SupabaseClient supabase;
  List<Map<String, dynamic>> _dragons = [];
  bool _isInitialized = false;

  DragonService(this.supabase);

  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        final response = await supabase
            .from('dragons')
            .select()
            .order('id', ascending: true);

        _dragons = List<Map<String, dynamic>>.from(response);
        _isInitialized = true;
      } catch (e) {
        _dragons = [];
      }
    }
  }

  /// Return Dragons with dragon id as key
  Future<Map<String, Dragon>> getUserDragons(String userId, String classId) async {
    try {

      final response = await supabase
          .from('Users')
          .select('dragons')
          .eq('id', userId)
          .single();


      /*
      Response

      {dragons: [
        'long id for dragon': ['egg', 'stage1', 'stage2'],
        'long id for dragon': ['egg', 'stage1', 'stage2', 'final]
      ]}
       */

      // Get the dragons the user has and unlocked phases
      final Map<String, dynamic> dragonIdsAndPhases = {};
      response['dragons'].forEach((key, phases) {
        if (key != 'current_dragon_env' && phases is List) {
          dragonIdsAndPhases[key] = phases;
        }
      });

      final classResponse = await supabase
          .from('classes')
          .select('assets')
          .eq('id', classId)
          .single();

      /*
      Response

      {assets: [
        { 'id': 'long id',
          'name': 'Boskaris',
          'type': '',
          'stages': {'egg': 'image url', 'baby': 'image url', 'teen': 'image url', 'adult': 'image url',
          'imageURL': '',
          'moduleId': 'module id'
        },
        { 'id': 'long id',
          'name': 'Nivallis',
          'type': '',
          'stages': {'egg': 'image url', 'baby': 'image url', 'teen': 'image url', 'adult': 'image url',
          'imageURL': '',
          'moduleId': 'module id'
        },
      ]}
       */

      final tempDragons = <String, Dragon>{};

      for (var asset in classResponse['assets']) {
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
              speciesName: asset['name'] ?? 'Unnamed Dragon',
              moduleId: asset['moduleId'] ?? '',
              phaseImages: images,
              phaseOrder: phaseOrder,
              preferredEnvironment: 'Mountain', // Default value
              favoriteItem: asset['favorite_item'] ?? 'Ice Cream',
              name: asset['name'] ?? 'Unnamed Dragon',
            );

            tempDragons[dragonId] = tempDragon;
          }
        }
      }


      final sortedDragons = tempDragons.entries.toList()
        ..sort((b, a) => a.value.moduleId.compareTo(b.value.moduleId));

      Map<String, Dragon> dragons = Map.fromEntries(sortedDragons);


      return dragons;
    }
    catch (e) {
      print('❌ DragonService: Error loading user dragons for user $userId: $e');
      return {};
    }
  }

  /// Return Dragons with lesson id as the key
  Future<Map<String, Dragon>> getUserDragonsWithLessonId(String userId, String classId) async {
    try {

      final response = await supabase
          .from('Users')
          .select('dragons')
          .eq('id', userId)
          .single();


      /*
      Response

      {dragons: [
        'long id for dragon': ['egg', 'stage1', 'stage2'],
        'long id for dragon': ['egg', 'stage1', 'stage2', 'final]
      ]}
       */

      // Get the dragons the user has and unlocked phases
      final Map<String, dynamic> dragonIdsAndPhases = {};
      response['dragons'].forEach((key, phases) {
        if (key != 'current_dragon_env' && phases is List) {
          dragonIdsAndPhases[key] = phases;
        }
      });

      final classResponse = await supabase
          .from('classes')
          .select('assets')
          .eq('id', classId)
          .single();

      /*
      Response

      {assets: [
        { 'id': 'long id',
          'name': 'Boskaris',
          'type': '',
          'stages': {'egg': 'image url', 'baby': 'image url', 'teen': 'image url', 'adult': 'image url',
          'imageURL': '',
          'moduleId': 'module id'
        },
        { 'id': 'long id',
          'name': 'Nivallis',
          'type': '',
          'stages': {'egg': 'image url', 'baby': 'image url', 'teen': 'image url', 'adult': 'image url',
          'imageURL': '',
          'moduleId': 'module id'
        },
      ]}
       */

      // final tempDragons = <String, Dragon>{};
      final dragons = <String, Dragon>{};

      for (var asset in classResponse['assets']) {
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
              speciesName: asset['name'] ?? 'Unnamed Dragon',
              moduleId: asset['moduleId'] ?? '',
              phaseImages: images,
              phaseOrder: phaseOrder,
              preferredEnvironment: 'Mountain', // Default value
              favoriteItem: asset['favorite_item'] ?? 'Ice Cream',
              name: asset['name'] ?? 'Unnamed Dragon',
            );

            if (asset['moduleId'] != null) {
              dragons[asset['moduleId']] = tempDragon;
            }
          }
        }
      }

      return dragons;
    }
    catch (e) {
      print('❌ DragonService: Error loading user dragons with lesson id for user $userId: $e');
      return {};
    }
  }

  /// Return DragonId and unlocked phases for that dragon
  Future<Map<String, List<String>>> getUnlockedPhases(String userId, String classId) async {
    try {
      final classResponse = await supabase
          .from('classes')
          .select('assets')
          .eq('id', classId)
          .single();

      final Map<String, int> dragonsInClass = {};
      for (var asset in classResponse['assets']) {
        if (asset['type'] != 'dragon') {
          continue;
        }
        else {
          final dragonId = asset['id'];

          dragonsInClass[dragonId] = 0;
        }
      }


      final response = await supabase
          .from('Users')
          .select('dragons')
          .eq('id', userId)
          .single();

      /*
      Response

      {dragons: [
        'long id for dragon': ['egg', 'stage1', 'stage2'],
        'long id for dragon': ['egg', 'stage1', 'stage2', 'final]
      ]}
       */

      // Get the dragons the user has that in this class and add the unlocked phases
      final Map<String, List<String>> unlockedPhases = {};
      response['dragons'].forEach((key, phases) {
        if ((key != 'current_dragon_env' && phases is List) && dragonsInClass.containsKey(key)) {
          unlockedPhases[key] = phases.cast<String>();
        }
      });

      return unlockedPhases;

    }
    catch (e) {
      print('❌ DragonService: Error loading unlocked dragon phases for user $userId: $e');
      return {};
    }
  }

  /// Get Dragon current env
  Future<String?> getCurrentEnvironment(String userId) async {
    // TODO: Update function to return a map of strings of dragon id and the selected environments for each
    try {
      final response = await supabase
          .from('Users')
          .select('dragons')
          .eq('id', userId)
          .single();

      final env = response['dragons']['current_dragon_env'];

      return env;

    }
    catch (e) {
      print('❌ DragonService: Error loading current environments for user $userId: $e');
      return '';
    }
  }




  Future<Map<String, dynamic>> getDragonImagesForModule(int moduleIndex) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (_dragons.isNotEmpty && moduleIndex < _dragons.length) {
        final dragon = _dragons[moduleIndex];
        return {
          'egg': dragon['egg_image'],
          'stage1': dragon['baby_image'],
          'stage2': dragon['teen_image'],
          'final': dragon['final_stage_image'],
          'id': dragon['id'],
          'preferred_environment': dragon['preferred_environment'],
          'favorite_item': dragon['favorite_item'],
          // 'length': dragon['length'],
          // 'width': dragon['width'],
        };
      }

      return {
        'egg': 'assets/images/other/egg.png',
        'stage1': 'assets/images/other/young.png',
        'stage2': 'assets/images/other/teen.png',
        'final': 'assets/images/other/adult.png',
        'id': null,
        'preferred_environment': 'Unknown',
        'favorite_item': 'Unknown',
        // 'length': 0.0,
        // 'width': 0.0,
      };
    } catch (e) {
      print('✗ Error getting dragon for module $moduleIndex: $e');
      return {
        'egg': 'assets/images/other/egg.png',
        'stage1': 'assets/images/other/young.png',
        'stage2': 'assets/images/other/teen.png',
        'final': 'assets/images/other/adult.png',
        'id': null,
        'preferred_environment': 'Unknown',
        'favorite_item': 'Unknown',
        // 'length': 0.0,
        // 'width': 0.0,
      };
    }
  }

  List<Map<String, dynamic>> getAllDragons() {
    return _dragons;
  }

  Future<void> saveDragonPhases(
    String userId,
    String dragonId,
    List<String> phases,
  ) async {
    try {
      final response =
          await supabase
              .from('Users')
              .select('dragons')
              .eq('id', userId)
              .single();

      Map<String, dynamic> dragons = {};
      if (response['dragons'] != null) {
        dragons = Map<String, dynamic>.from(response['dragons']);
      }

      dragons[dragonId] = phases;

      await supabase
          .from('Users')
          .update({'dragons': dragons})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to save dragon phases: $e');
    }
  }


  // Future<void> updateDragonProgress(String userId, String dragonId, String newPhase) async {
  //   // Get current progress
  //   final currentProgress = await getUserDragonProgress(userId, dragonId);
  //
  //   // Add new phase if not already unlocked
  //   if (!currentProgress.unlockedPhases.contains(newPhase)) {
  //     currentProgress.unlockedPhases.add(newPhase);
  //     await saveUserDragonProgress(userId, dragonId, currentProgress);
  //
  //     // Trigger celebration UI
  //     _showPhaseUnlockedCelebration(dragonId, newPhase);
  //   }
  // }
}
