import 'package:supabase_flutter/supabase_flutter.dart';

class DragonService {
  final SupabaseClient supabase;
  List<Map<String, dynamic>> _dragons = [];
  bool _isInitialized = false;

  DragonService(this.supabase);

  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        print('Fetching dragons from Supabase...');
        final response = await supabase
            .from('dragons')
            .select()
            .order('created_at', ascending: true);

        _dragons = List<Map<String, dynamic>>.from(response);
        _isInitialized = true;
        print('Successfully loaded ${_dragons.length} dragons from database:');
        for (var i = 0; i < _dragons.length; i++) {
          final dragon = _dragons[i];
          print('Dragon $i:');
          print('  ID: ${dragon['id']}');
          print('  Egg: ${dragon['egg_image']}');
          print('  Stage1: ${dragon['stage1_image']}');
          print('  Stage2: ${dragon['stage2_image']}');
          print('  Final: ${dragon['final_stage_image']}');
        }
      } catch (e) {
        print('Error initializing dragons: $e');
        _dragons = [];
      }
    } else {
      print('Dragons already initialized with ${_dragons.length} dragons');
    }
  }

  Future<Map<String, dynamic>> getDragonImagesForModule(int moduleIndex) async {
    if (!_isInitialized) {
      print('Dragons not initialized, initializing now...');
      await initialize();
    }

    try {
      // If we have dragons and the module index is valid
      if (_dragons.isNotEmpty && moduleIndex < _dragons.length) {
        final dragon = _dragons[moduleIndex];
        print('Assigning dragon to module $moduleIndex:');
        print('  ID: ${dragon['id']}');
        print('  Egg: ${dragon['egg_image']}');
        return {
          'egg': dragon['egg_image'],
          'stage1': dragon['stage1_image'],
          'stage2': dragon['stage2_image'],
          'final': dragon['final_stage_image'],
          'id': dragon['id'],
          'preferred_environment': dragon['preferred_environment'],
          'favorite_item': dragon['favorite_item'],
          'length': dragon['length'],
          'width': dragon['width'],
        };
      }

      // If no dragons or invalid index, return default images
      print(
        'No dragon found for module index $moduleIndex (total dragons: ${_dragons.length})',
      );
      return {
        'egg': 'assets/images/other/egg.png',
        'stage1': 'assets/images/other/young.png',
        'stage2': 'assets/images/other/teen.png',
        'final': 'assets/images/other/adult.png',
        'id': null,
        'preferred_environment': 'Unknown',
        'favorite_item': 'Unknown',
        'length': 0.0,
        'width': 0.0,
      };
    } catch (e) {
      print('Error getting dragon images for module $moduleIndex: $e');
      return {
        'egg': 'assets/images/other/egg.png',
        'stage1': 'assets/images/other/young.png',
        'stage2': 'assets/images/other/teen.png',
        'final': 'assets/images/other/adult.png',
        'id': null,
        'preferred_environment': 'Unknown',
        'favorite_item': 'Unknown',
        'length': 0.0,
        'width': 0.0,
      };
    }
  }

  // Get all dragons for debugging/testing
  List<Map<String, dynamic>> getAllDragons() {
    return _dragons;
  }
}
