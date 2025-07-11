import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/dragons/dragon_id_card.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/dragon_service.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:flutter/rendering.dart';

import '../services/class_service.dart';
import '../themes/app_theme.dart';
import 'dragon_decoration_screen.dart';

class DragonsPage extends StatefulWidget {
  const DragonsPage({super.key});

  @override
  State<DragonsPage> createState() => _DragonsPageState();
}

class _DragonsPageState extends State<DragonsPage> {
  final _userState = UserStateService();
  late final DragonService _dragonService;
  final QuizService _quizService = QuizService();
  late final ClassService _classService;
  Map<String, dynamic> _userDragons = {};
  Map<String, Map<String, dynamic>> _dragonDetails = {};
  bool _isLoading = true;
  Map<String, double> _moduleProgress = {};

  @override
  void initState() {
    super.initState();

    _dragonService = DragonService(QuizService().supabase);
    _loadUserDragons();

  }

  // Add refresh method
  Future<void> _refreshDragons() async {
    print('🔄 Refreshing dragons data...');
    await _loadUserDragons();
  }

  // When navigating to DragonDressUpPage:
  void navigateToDressUp(String dragonId, Map<String, dynamic> dragonData, dynamic phases) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DragonDressUpPage(
          dragonId: dragonId,
          dragonData: dragonData,
          phases: phases,
          onEnvironmentChanged: saveEnvironmentSelection,
          onDragonUpdated: (_) => _refreshDragons(), // Use your existing method
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);


    final Color primary = theme.colorScheme.primary;
    final Color cardBg = theme.colorScheme.surface;
    // final Color cardShadow = theme.colorScheme.shadow.withOpacity(0.07);
    // final Color lockedBg = theme.colorScheme.surfaceDim;
    // final double borderRadius = 28.0;
    // final double cardPadding = 24.0;


    return Scaffold(
      backgroundColor: cardBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDragons,
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_userDragons.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.egg_outlined,
                                      size: 64,
                                      color: primary.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No dragons yet.\nComplete topics to unlock dragons!',
                                      style: theme.textTheme.labelLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ..._userDragons.entries.map((entry) {
                              final dragonId = entry.key;
                              final phases = entry.value;
                              final dragonData = _dragonDetails[dragonId];

                              if (dragonData == null)
                                return const SizedBox.shrink();

                              // Get the highest phase achieved
                              String currentPhase = 'egg';
                              String imageUrl = dragonData['egg_image'];

                              // Handle both List and Map formats for phases
                              bool hasPhase(String phase) {
                                if (phases is List) {
                                  // Map new phase names to old phase names for checking
                                  String phaseToCheck = phase;
                                  if (phase == 'stage1') phaseToCheck = 'baby';
                                  if (phase == 'stage2') phaseToCheck = 'teen';
                                  if (phase == 'final') phaseToCheck = 'adult';

                                  return phases.contains(phase) ||
                                      phases.contains(phaseToCheck);
                                } else if (phases is Map) {
                                  String phaseToCheck = phase;
                                  if (phase == 'stage1') phaseToCheck = 'baby';
                                  if (phase == 'stage2') phaseToCheck = 'teen';
                                  if (phase == 'final') phaseToCheck = 'adult';

                                  final phasesList = phases['phases'] ?? [];
                                  return phasesList.contains(phase) ||
                                      phasesList.contains(phaseToCheck);
                                }
                                return false;
                              }

                              if (hasPhase('final') || hasPhase('adult')) {
                                currentPhase = 'final';
                                imageUrl = dragonData['final_stage_image'];
                              } else if (hasPhase('stage2') || hasPhase('teen')) {
                                currentPhase = 'stage2';
                                imageUrl = dragonData['stage2_image'];
                              } else if (hasPhase('stage1') || hasPhase('baby')) {
                                currentPhase = 'stage1';
                                imageUrl = dragonData['stage1_image'];
                              }

                              final String speciesName = dragonData['name'] ?? 'Unknown';
                              final String item = dragonData['favorite_item'] ?? 'Unknown';
                              final String environment = dragonData['preferred_environment'] ?? 'Unknown';

                              return DragonIdCard(
                                dragonImagePath: imageUrl,
                                species: speciesName,
                                name: 'Jack',
                                favoriteItem: item,
                                favoriteEnvironment: environment,
                                onTapPlayButton: () {
                                  navigateToDressUp(
                                      dragonId,
                                      dragonData,
                                      phases
                                  );
                                },


                                //     () {
                                //   Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder:
                                //           (context) =>
                                //           DragonDressUpPage(
                                //             dragonId: dragonId,
                                //             dragonData:
                                //             dragonData,
                                //             phases: phases,
                                //             // parentState: this,
                                //           ),
                                //     ),
                                //   );
                                // },
                                // TODO: Add backend to change dragon name
                                // onNameChanged: (newName) {
                                //   setState(() {
                                //     dragonName = newName;
                                //   });
                                // },
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  Future<void> _loadUserDragons() async {
    try {
      setState(() => _isLoading = true);

      // Initialize dragon service
      await _dragonService.initialize();

      // Get user's dragons
      final user = _userState.currentUser;
      if (user != null) {
        final response =
            await _dragonService.supabase
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

          // Load details for each dragon from classes.assets
          for (var dragonId in _userDragons.keys) {
            if (dragonId != 'current_dragon_env') {
              // Get all classes and their assets
              final classesResponse = await _dragonService.supabase
                  .from('classes')
                  .select('assets');

              for (var classData in classesResponse) {
                if (classData['assets'] != null) {
                  final assets = List<dynamic>.from(classData['assets']);

                  // Find the dragon with matching ID
                  for (var asset in assets) {
                    if (asset['type'] == 'dragon' && asset['id'] == dragonId) {
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
                      };
                      _dragonDetails[dragonId] = dragonData;
                      break;
                    }
                  }
                }
              }
            }
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('✗ Error loading user dragons: $e');
      setState(() => _isLoading = false);
    }
  }

  // Helper method to get phases for a dragon
  List<String> getDragonPhases(String dragonId) {
    final phases = _userDragons[dragonId];
    if (phases is List) {
      return phases.map((phase) => phase.toString()).toList();
    }
    return [];
  }

  // Helper method to get current environment
  String? getCurrentEnvironment() {
    return _userDragons['current_dragon_env'] as String?;
  }

  // Helper method to save environment selection
  Future<void> saveEnvironmentSelection(String dragonId, String environmentId,) async {
    try {
      final user = _userState.currentUser;
      if (user != null) {
        print('🔄 Starting environment selection save...');
        print('📦 Current dragons data: $_userDragons');

        // Create a new map with the updated environment
        final updatedDragons = Map<String, dynamic>.from(_userDragons);
        print('📦 Created updatedDragons map: $updatedDragons');

        // Add the current_dragon_env field
        updatedDragons['current_dragon_env'] = environmentId;
        print('📦 Added current_dragon_env: $environmentId');

        // Ensure we keep the existing dragon phases
        if (!updatedDragons.containsKey(dragonId)) {
          final phases = getDragonPhases(dragonId);
          updatedDragons[dragonId] = phases;
          print('📦 Added missing dragon phases for $dragonId: $phases');
        }

        print('📦 Final updatedDragons to save: $updatedDragons');

        // Update the database
        final response = await _dragonService.supabase
            .from('Users')
            .update({'dragons': updatedDragons})
            .eq('id', user.id);

        print('✅ Database update response: $response');

        // Update local state
        setState(() {
          _userDragons = updatedDragons;
        });
        print('✅ Local state updated with new dragons data');
      } else {
        print('❌ No user found when trying to save environment selection');
      }
    } catch (e) {
      print('❌ Error saving environment selection: $e');
      print('❌ Error details: ${e.toString()}');
    }
  }
}
