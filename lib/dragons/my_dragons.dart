import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/dragons/dragon_id_card.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/dragon_service.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:flutter/rendering.dart';

import '../themes/app_theme.dart';

class MyDragonsPage extends StatefulWidget {
  const MyDragonsPage({super.key});

  @override
  State<MyDragonsPage> createState() => _MyDragonsPageState();
}

class _MyDragonsPageState extends State<MyDragonsPage> {
  final _userState = UserStateService();
  late final DragonService _dragonService;
  Map<String, dynamic> _userDragons = {};
  Map<String, Map<String, dynamic>> _dragonDetails = {};
  bool _isLoading = true;

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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                          DragonDressUpPage(
                                            dragonId: dragonId,
                                            dragonData:
                                            dragonData,
                                            phases: phases,
                                            parentState: this,
                                          ),
                                    ),
                                  );
                                },
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

  IconData _getPhaseIcon(String phase) {
    switch (phase) {
      case 'egg':
        return Icons.egg;
      case 'stage1':
        return FontAwesomeIcons.babyCarriage;
      case 'stage2':
        return FontAwesomeIcons.dragon;
      case 'final':
        return Icons.star;
      default:
        return Icons.pets;
    }
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {

    ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10 * AppTheme.fontSizeScale,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 12 * AppTheme.fontSizeScale,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
  Future<void> saveEnvironmentSelection(
    String dragonId,
    String environmentId,
  ) async {
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

// --- Dragon Dress Up Page ---
class DragonDressUpPage extends StatefulWidget {
  final String dragonId;
  final Map<String, dynamic> dragonData;
  final dynamic phases;
  final _MyDragonsPageState? parentState;

  const DragonDressUpPage({
    Key? key,
    required this.dragonId,
    required this.dragonData,
    required this.phases,
    this.parentState,
  }) : super(key: key);

  @override
  _DragonDressUpPageState createState() => _DragonDressUpPageState();
}

class _DragonDressUpPageState extends State<DragonDressUpPage> {
  int selectedPhase = 0;
  int selectedEnvironment = 0;
  List<String> userEnvironments = [];
  List<String> userEnvironmentIds = [];
  List<String> userEnvironmentImages = [];
  bool _isLoadingEnvironments = true;
  bool _isLoadingAccessories = true;
  List<Map<String, dynamic>> userAccessories = [];

  // List to store placed stickers with their positions
  List<StickerItem> placedStickers = [];
  String? selectedStickerId;

  @override
  void initState() {
    super.initState();
    print('🚀 Initializing DragonDressUpPage...');
    _loadUserEnvironments();
    _loadUserAccessories();
    _loadCurrentPhase();
  }

  Future<void> _loadUserEnvironments() async {
    try {
      final userState = UserStateService();
      final user = userState.currentUser;

      if (user != null) {
        final dragonService = DragonService(QuizService().supabase);

        // First, get the user's acquired environment IDs
        final userResponse =
            await dragonService.supabase
                .from('Users')
                .select('acquired_environments, dragons')
                .eq('id', user.id)
                .single();

        if (userResponse['acquired_environments'] != null) {
          final acquiredEnvs = userResponse['acquired_environments'];
          List<String> environmentIds = [];

          // Handle both List and Map cases
          if (acquiredEnvs is List) {
            environmentIds = acquiredEnvs.map((e) => e.toString()).toList();
          } else if (acquiredEnvs is Map) {
            environmentIds =
                acquiredEnvs.keys.map((e) => e.toString()).toList();
          }

          if (environmentIds.isNotEmpty) {
            // Now fetch the environment details from classes.assets
            final classesResponse = await dragonService.supabase
                .from('classes')
                .select('assets');

            List<Map<String, dynamic>> foundEnvironments = [];

            for (var classData in classesResponse) {
              if (classData['assets'] != null) {
                final assets = List<dynamic>.from(classData['assets']);

                // Find environments with matching IDs
                for (var asset in assets) {
                  if (asset['type'] == 'environment' &&
                      environmentIds.contains(asset['id'])) {
                    foundEnvironments.add({
                      'id': asset['id'],
                      'name': asset['name'],
                      'image_url':
                          asset['imageUrl'], // Note: imageUrl not image_url in new structure
                    });
                  }
                }
              }
            }

            if (foundEnvironments.isNotEmpty && mounted) {
              setState(() {
                userEnvironmentIds =
                    foundEnvironments
                        .map((env) => env['id'] as String)
                        .toList();
                userEnvironments =
                    foundEnvironments
                        .map((env) => env['name'] as String)
                        .toList();
                userEnvironmentImages =
                    foundEnvironments
                        .map((env) => env['image_url'] as String)
                        .toList();
                _isLoadingEnvironments = false;
              });

              // Check for current environment in dragons column
              if (userResponse['dragons'] != null) {
                final dragonsData =
                    userResponse['dragons'] as Map<String, dynamic>;
                final currentEnvId =
                    dragonsData['current_dragon_env'] as String?;

                if (currentEnvId != null) {
                  final envIndex = userEnvironmentIds.indexOf(currentEnvId);
                  if (envIndex != -1) {
                    setState(() {
                      selectedEnvironment = envIndex;
                    });
                    print(
                      '✅ Set initial environment to: ${userEnvironments[envIndex]}',
                    );
                  }
                }
              }
            } else {
              if (mounted) {
                setState(() {
                  userEnvironments = ['Default'];
                  userEnvironmentIds = [];
                  userEnvironmentImages = [];
                  _isLoadingEnvironments = false;
                });
              }
            }
          } else {
            if (mounted) {
              setState(() {
                userEnvironments = ['Default'];
                userEnvironmentIds = [];
                userEnvironmentImages = [];
                _isLoadingEnvironments = false;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              userEnvironments = ['Default'];
              userEnvironmentIds = [];
              userEnvironmentImages = [];
              _isLoadingEnvironments = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user environments: $e');
      if (mounted) {
        setState(() {
          userEnvironments = ['Default'];
          userEnvironmentIds = [];
          userEnvironmentImages = [];
          _isLoadingEnvironments = false;
        });
      }
    }
  }

  Future<void> _loadUserAccessories() async {
    try {
      setState(() => _isLoadingAccessories = true);

      final userState = UserStateService();
      final user = userState.currentUser;

      if (user != null) {
        final dragonService = DragonService(QuizService().supabase);
        final userResponse =
            await dragonService.supabase
                .from('Users')
                .select('acquired_accessories')
                .eq('id', user.id)
                .single();

        if (userResponse['acquired_accessories'] != null) {
          final List<dynamic> acquiredAccessories =
              userResponse['acquired_accessories'];
          print('📦 Acquired accessories IDs: $acquiredAccessories');

          // Get accessories from classes.assets
          final classesResponse = await dragonService.supabase
              .from('classes')
              .select('assets');

          List<Map<String, dynamic>> foundAccessories = [];

          for (var classData in classesResponse) {
            if (classData['assets'] != null) {
              final assets = List<dynamic>.from(classData['assets']);

              // Find accessories with matching IDs
              for (var asset in assets) {
                if (asset['type'] == 'accessory' &&
                    acquiredAccessories.contains(asset['id'])) {
                  foundAccessories.add({
                    'id': asset['id'],
                    'name': asset['name'],
                    'image':
                        asset['imageUrl'], // Note: imageUrl not image in new structure
                  });
                }
              }
            }
          }

          setState(() {
            userAccessories = foundAccessories;
            _isLoadingAccessories = false;
          });
          print('✅ Loaded ${userAccessories.length} accessories');
          _onAccessoriesLoaded();
        } else {
          print('⚠️ No acquired accessories found');
          setState(() => _isLoadingAccessories = false);
        }
      } else {
        print('⚠️ No user found');
        setState(() => _isLoadingAccessories = false);
      }
    } catch (e) {
      print('❌ Error loading accessories: $e');
      setState(() => _isLoadingAccessories = false);
    }
  }

  // Get available phases based on the dragon data
  List<String> get availablePhases {
    List<String> phases = ['egg'];

    // Handle both List and Map formats for phases
    bool hasPhase(String phase) {
      if (widget.phases is List) {
        // Check for both old and new phase names
        List<String> phasesToCheck = [phase];
        if (phase == 'stage1') phasesToCheck.addAll(['baby', 'stage1']);
        if (phase == 'stage2') phasesToCheck.addAll(['teen', 'stage2']);
        if (phase == 'final') phasesToCheck.addAll(['adult', 'final']);

        return phasesToCheck.any((p) => (widget.phases as List).contains(p));
      } else if (widget.phases is Map) {
        List<String> phasesToCheck = [phase];
        if (phase == 'stage1') phasesToCheck.addAll(['baby', 'stage1']);
        if (phase == 'stage2') phasesToCheck.addAll(['teen', 'stage2']);
        if (phase == 'final') phasesToCheck.addAll(['adult', 'final']);

        final phasesList = (widget.phases['phases'] as List?) ?? [];
        return phasesToCheck.any((p) => phasesList.contains(p));
      }
      return false;
    }

    if (hasPhase('stage1')) phases.add('stage1');
    if (hasPhase('stage2')) phases.add('stage2');
    if (hasPhase('final')) phases.add('final');

    return phases;
  }

  // Get phase display names
  String getPhaseDisplayName(String phase) {
    switch (phase) {
      case 'egg':
        return 'Egg';
      case 'stage1':
        return 'Baby';
      case 'stage2':
        return 'Teen';
      case 'final':
        return 'Adult';
      default:
        return 'Unknown';
    }
  }

  // Get image URL for current phase
  String getCurrentPhaseImage() {
    final currentPhase = availablePhases[selectedPhase];
    switch (currentPhase) {
      case 'egg':
        return widget.dragonData['egg_image'];
      case 'stage1':
        return widget.dragonData['stage1_image'];
      case 'stage2':
        return widget.dragonData['stage2_image'];
      case 'final':
        return widget.dragonData['final_stage_image'];
      default:
        return widget.dragonData['egg_image'];
    }
  }

  void _showPhaseDialog() async {
    int? choice = await showDialog<int>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Select Dragon Phase'),
            children: List.generate(
              availablePhases.length,
              (i) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, i),
                child: Text(getPhaseDisplayName(availablePhases[i])),
              ),
            ),
          ),
    );
    if (choice != null) {
      setState(() => selectedPhase = choice);
      _saveCurrentPhase(availablePhases[choice]);
    }
  }

  Future<void> _saveCurrentPhase(String phase) async {
    try {
      final userState = UserStateService();
      final user = userState.currentUser;

      if (user != null) {
        final dragonService = DragonService(QuizService().supabase);

        // Get current dragons data
        final userResponse =
            await dragonService.supabase
                .from('Users')
                .select('dragons')
                .eq('id', user.id)
                .single();

        if (userResponse['dragons'] != null) {
          final dragonsData = Map<String, dynamic>.from(
            userResponse['dragons'],
          );

          // Update the dragon's data
          if (dragonsData[widget.dragonId] is Map) {
            dragonsData[widget.dragonId]['current_phase'] = phase;
          } else {
            dragonsData[widget.dragonId] = {
              'phases': widget.phases,
              'current_phase': phase,
            };
          }

          // Save the updated dragons data
          await dragonService.supabase
              .from('Users')
              .update({'dragons': dragonsData})
              .eq('id', user.id);

          print('✅ Current phase saved: $phase');
        }
      }
    } catch (e) {
      print('❌ Error saving current phase: $e');
    }
  }

  void _showEnvironmentDialog() async {
    print('🔄 Opening environment selection dialog...');

    if (_isLoadingEnvironments) {
      print('⏳ Environments still loading...');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Loading environments...')));
      return;
    }

    if (userEnvironments.isEmpty) {
      print('❌ No environments available');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No environments available')));
      return;
    }

    print('📦 Available environments: $userEnvironments');
    print('📦 Environment IDs: $userEnvironmentIds');

    int? choice = await showDialog<int>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Select Environment'),
            children: List.generate(
              userEnvironments.length,
              (i) => SimpleDialogOption(
                onPressed: () {
                  print('✅ User selected environment: ${userEnvironments[i]}');
                  Navigator.pop(context, i);
                },
                child: Text(userEnvironments[i]),
              ),
            ),
          ),
    );

    if (choice != null && choice < userEnvironments.length) {
      print('🔄 Processing environment selection...');
      print('📦 Selected environment: ${userEnvironments[choice]}');
      print('📦 Selected environment ID: ${userEnvironmentIds[choice]}');

      setState(() => selectedEnvironment = choice);

      // Use the parent state if available
      if (widget.parentState != null) {
        print('🔄 Saving environment selection...');
        await widget.parentState!.saveEnvironmentSelection(
          widget.dragonId,
          userEnvironmentIds[choice],
        );
      } else {
        print('⚠️ No parent state available to save environment selection');
      }
    } else {
      print('❌ Invalid environment selection or dialog cancelled');
    }
  }

  void _updateStickerPosition(String id, Offset newPosition) {
    setState(() {
      final sticker = placedStickers.firstWhere((s) => s.id == id);
      final dragonSize = MediaQuery.of(context).size.width * 0.8;

      // Ensure sticker stays within dragon bounds
      final clampedX =
          newPosition.dx.clamp(0.0, dragonSize - sticker.size).toDouble();
      final clampedY =
          newPosition.dy.clamp(0.0, dragonSize - sticker.size).toDouble();

      sticker.position = Offset(clampedX, clampedY);
    });
    _saveStickers(); // Save after moving
  }

  void _updateStickerSize(String id, double newSize) {
    setState(() {
      final sticker = placedStickers.firstWhere((s) => s.id == id);
      sticker.size = newSize.clamp(
        24.0,
        120.0,
      ); // Limit size between 24 and 120
    });
    _saveStickers(); // Save after resizing
  }

  void _removeSticker(String id) {
    setState(() {
      placedStickers.removeWhere((sticker) => sticker.id == id);
      if (selectedStickerId == id) {
        selectedStickerId = null;
      }
    });
    _saveStickers(); // Save after removing
  }

  Future<void> _saveStickers() async {
    try {
      final userState = UserStateService();
      final user = userState.currentUser;

      if (user != null) {
        final dragonService = DragonService(QuizService().supabase);

        // Get current dragons data
        final userResponse =
            await dragonService.supabase
                .from('Users')
                .select('dragons')
                .eq('id', user.id)
                .single();

        if (userResponse['dragons'] != null) {
          final dragonsData = Map<String, dynamic>.from(
            userResponse['dragons'],
          );

          // Convert stickers to the format we want to save
          final stickersData =
              placedStickers
                  .map(
                    (sticker) => {
                      'id': sticker.id,
                      'size': sticker.size,
                      'position': {
                        'x': sticker.position.dx,
                        'y': sticker.position.dy,
                      },
                      'accessory_id': sticker.name,
                    },
                  )
                  .toList();

          // Update the dragon's data
          if (dragonsData[widget.dragonId] is Map) {
            dragonsData[widget.dragonId]['stickers'] = stickersData;
          } else {
            dragonsData[widget.dragonId] = {
              'phases': widget.phases,
              'stickers': stickersData,
              'current_dragon_env': userEnvironmentIds[selectedEnvironment],
            };
          }

          // Save the updated dragons data
          await dragonService.supabase
              .from('Users')
              .update({'dragons': dragonsData})
              .eq('id', user.id);

          print('✅ Stickers saved: ${stickersData.length} stickers');
        }
      }
    } catch (e) {
      print('❌ Error saving stickers: $e');
    }
  }

  Future<void> _loadStickers() async {
    try {
      final userState = UserStateService();
      final user = userState.currentUser;

      if (user != null) {
        final dragonService = DragonService(QuizService().supabase);

        // Get current dragons data
        final userResponse =
            await dragonService.supabase
                .from('Users')
                .select('dragons')
                .eq('id', user.id)
                .single();

        if (userResponse['dragons'] != null) {
          final dragonsData = Map<String, dynamic>.from(
            userResponse['dragons'],
          );
          final dragonData = dragonsData[widget.dragonId];

          if (dragonData is Map && dragonData['stickers'] != null) {
            final stickersData = List<Map<String, dynamic>>.from(
              dragonData['stickers'],
            );

            setState(() {
              placedStickers =
                  stickersData.map((sticker) {
                    final accessory = userAccessories.firstWhere(
                      (acc) => acc['name'] == sticker['accessory_id'],
                      orElse: () => {'image': ''},
                    );

                    return StickerItem(
                      id: sticker['id'],
                      imageUrl: accessory['image'],
                      name: sticker['accessory_id'],
                      position: Offset(
                        sticker['position']['x'].toDouble(),
                        sticker['position']['y'].toDouble(),
                      ),
                      size: sticker['size'].toDouble(),
                    );
                  }).toList();
            });
            print('✅ Loaded ${placedStickers.length} stickers');
          }
        }
      }
    } catch (e) {
      print('❌ Error loading stickers: $e');
    }
  }

  // Add a method to load stickers after accessories are loaded
  void _onAccessoriesLoaded() {
    _loadStickers();
  }

  Future<void> _loadCurrentPhase() async {
    try {
      final userState = UserStateService();
      final user = userState.currentUser;

      if (user != null) {
        final dragonService = DragonService(QuizService().supabase);

        // Get current dragons data
        final userResponse =
            await dragonService.supabase
                .from('Users')
                .select('dragons')
                .eq('id', user.id)
                .single();

        if (userResponse['dragons'] != null) {
          final dragonsData = Map<String, dynamic>.from(
            userResponse['dragons'],
          );
          final dragonData = dragonsData[widget.dragonId];

          if (dragonData is Map && dragonData['current_phase'] != null) {
            final savedPhase = dragonData['current_phase'] as String;
            final phaseIndex = availablePhases.indexOf(savedPhase);

            if (phaseIndex != -1 && mounted) {
              setState(() {
                selectedPhase = phaseIndex;
              });
              print('✅ Loaded saved phase: $savedPhase');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error loading current phase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    final colorScheme = theme.colorScheme;
    final double dragonSize = MediaQuery.of(context).size.width * 0.8;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dress Up Your Dragon',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'phase') _showPhaseDialog();
              if (value == 'env') _showEnvironmentDialog();
              if (value == 'clear') {
                setState(() {
                  placedStickers.clear();
                });
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'phase',
                    child: Text('Select Dragon Phase'),
                  ),
                  PopupMenuItem(
                    value: 'env',
                    child: Text('Select Environment'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'clear',
                    child: Text('Clear All Stickers'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Phase and Environment info
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  'Phase: ${getPhaseDisplayName(availablePhases[selectedPhase])}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  'Environment: ${_isLoadingEnvironments ? 'Loading...' : (userEnvironments.isNotEmpty && selectedEnvironment < userEnvironments.length ? userEnvironments[selectedEnvironment] : 'None')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Dragon area with drop zone
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Environment background
                  if (userEnvironmentImages.isNotEmpty &&
                      selectedEnvironment < userEnvironmentImages.length)
                    Container(
                      width: dragonSize,
                      height: dragonSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        image: DecorationImage(
                          image: NetworkImage(
                            userEnvironmentImages[selectedEnvironment],
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  // Drop zone for dragon
                  DragTarget<Map<String, dynamic>>(
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        width: dragonSize,
                        height: dragonSize,
                        decoration: BoxDecoration(
                          color:
                              candidateData.isNotEmpty
                                  ? colorScheme.primary.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                candidateData.isNotEmpty
                                    ? colorScheme.primary
                                    : colorScheme.primary.withOpacity(0.2),
                            width: candidateData.isNotEmpty ? 3 : 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            children: [
                              // Dragon image
                              Positioned.fill(
                                child: Image.network(
                                  getCurrentPhaseImage(),
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Icons.pets,
                                        size: dragonSize * 0.7,
                                        color: colorScheme.primary,
                                      ),
                                ),
                              ),
                              // Placed stickers
                              ...placedStickers.map((sticker) {
                                final isSelected =
                                    selectedStickerId == sticker.id;
                                return Positioned(
                                  left: sticker.position.dx,
                                  top: sticker.position.dy,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedStickerId =
                                            isSelected ? null : sticker.id;
                                      });
                                    },
                                    onLongPress:
                                        () => _removeSticker(sticker.id),
                                    child: Stack(
                                      children: [
                                        GestureDetector(
                                          onPanUpdate: (details) {
                                            if (isSelected) {
                                              final newPosition = Offset(
                                                sticker.position.dx +
                                                    details.delta.dx,
                                                sticker.position.dy +
                                                    details.delta.dy,
                                              );
                                              _updateStickerPosition(
                                                sticker.id,
                                                newPosition,
                                              );
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color:
                                                    isSelected
                                                        ? Theme.of(
                                                          context,
                                                        ).colorScheme.primary
                                                        : Colors.white
                                                            .withOpacity(0.5),
                                                width: isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: Image.network(
                                              sticker.imageUrl,
                                              width: sticker.size,
                                              height: sticker.size,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            right: -8,
                                            bottom: -8,
                                            child: GestureDetector(
                                              onPanUpdate: (details) {
                                                // Calculate new size based on drag distance
                                                final newSize =
                                                    sticker.size +
                                                    details.delta.dx;
                                                _updateStickerSize(
                                                  sticker.id,
                                                  newSize,
                                                );
                                              },
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.open_with,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                    onAcceptWithDetails: (details) {
                      final data = details.data;
                      final RenderBox renderBox =
                          context.findRenderObject() as RenderBox;
                      final localPosition = renderBox.globalToLocal(
                        details.offset,
                      );

                      // Find the dragon container's position
                      final dragonBox = context.findRenderObject() as RenderBox;
                      final dragonPosition = dragonBox.localToGlobal(
                        Offset.zero,
                      );
                      final screenSize = MediaQuery.of(context).size;

                      // Calculate position relative to dragon container
                      final dragonLeft = (screenSize.width - dragonSize) / 2;
                      final dragonTop =
                          dragonPosition.dy +
                          (dragonBox.size.height - dragonSize) / 2;

                      final relativeX =
                          details.offset.dx -
                          dragonLeft -
                          24; // Adjust for icon size
                      final relativeY = details.offset.dy - dragonTop - 24;

                      // Ensure sticker stays within dragon bounds
                      final clampedX =
                          relativeX.clamp(0.0, dragonSize - 48).toDouble();
                      final clampedY =
                          relativeY.clamp(0.0, dragonSize - 48).toDouble();

                      setState(() {
                        final newSticker = StickerItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          imageUrl: data['image'],
                          name: data['name'],
                          position: Offset(clampedX, clampedY),
                        );
                        placedStickers.add(newSticker);
                      });
                      _saveStickers(); // Save after adding
                    },
                  ),
                ],
              ),
            ),
          ),

          // Accessory picker
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Drag accessories onto your dragon',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _isLoadingAccessories
                    ? const Center(child: CircularProgressIndicator())
                    : userAccessories.isEmpty
                    ? Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 48,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No accessories yet.\nVisit the shop to buy some!',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            userAccessories.map((accessory) {
                              return Draggable<Map<String, dynamic>>(
                                data: {
                                  'image': accessory['image'],
                                  'name': accessory['name'],
                                },
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Image.network(
                                    accessory['image'],
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                childWhenDragging: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Image.network(
                                    accessory['image'],
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: colorScheme.primary.withOpacity(
                                        0.3,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: Image.network(
                                    accessory['image'],
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                const SizedBox(height: 18),
                Text(
                  'Long press a sticker to remove it',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
    );
  }
}

// Model class for placed stickers
class StickerItem {
  final String id;
  final String imageUrl;
  final String name;
  Offset position;
  double size;

  StickerItem({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.position,
    this.size = 48.0,
  });
}
