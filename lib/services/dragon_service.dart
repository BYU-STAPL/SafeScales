import 'package:supabase_flutter/supabase_flutter.dart';

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
            .order('created_at', ascending: true);

        _dragons = List<Map<String, dynamic>>.from(response);
        _isInitialized = true;
      } catch (e) {
        _dragons = [];
      }
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
          'baby': dragon['baby_image'],
          'teen': dragon['teen_image'],
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
        'baby': 'assets/images/other/young.png',
        'teen': 'assets/images/other/teen.png',
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
        'baby': 'assets/images/other/young.png',
        'teen': 'assets/images/other/teen.png',
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
