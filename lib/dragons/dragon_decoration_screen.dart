// --- Dragon Dress Up Page ---
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safe_scales/dragons/sticker_collection_widget.dart';

import 'package:safe_scales/dragons/sticker_item_model.dart';

import '../services/dragon_service.dart';
import '../services/quiz_service.dart';
import '../services/user_state_service.dart';

class DragonDressUpPage extends StatefulWidget {
  final String dragonId;
  final Map<String, dynamic> dragonData;
  final dynamic phases;
  final Function(String dragonId, String environmentId)? onEnvironmentChanged;
  final Function(String dragonId)? onDragonUpdated;

  const DragonDressUpPage({
    Key? key,
    required this.dragonId,
    required this.dragonData,
    required this.phases,
    this.onEnvironmentChanged,
    this.onDragonUpdated,
    // this.parentState,
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
    final double dragonSize = MediaQuery.of(context).size.width * 0.75;


    final environmentSize = dragonSize * 1.25; // 25% larger

    final stickerEnvironmentSize = environmentSize - 10;


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
                      width: environmentSize,
                      height: environmentSize,
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

                  // Dragon Image
                  Container(
                    height: dragonSize * 0.75,
                    width: dragonSize * 0.75,
                    child: Image.network(
                      getCurrentPhaseImage(),
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                        Icons.pets,
                        size: dragonSize,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                  // Drop zone for dragon
                  DragTarget<Map<String, dynamic>>(
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        width: environmentSize,
                        height: environmentSize,
                        decoration: BoxDecoration(
                          color:
                          candidateData.isNotEmpty
                              ? colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                            candidateData.isNotEmpty
                                ? colorScheme.primary
                                : colorScheme.primary.withOpacity(0.2),
                            width: candidateData.isNotEmpty ? 3 : 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [

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
                                                (stickerEnvironmentSize - sticker.size),);
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                              border: Border.all(
                                                color:
                                                isSelected ? theme.colorScheme.primary : Colors.transparent,
                                                width: isSelected ? 3 : 1,
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
                                                final newSize = sticker.size + details.delta.dx;
                                                _updateStickerSize(sticker.id, newSize,);
                                              },
                                              child: Container(
                                                width: 25,
                                                height: 25,
                                                decoration: BoxDecoration(
                                                  color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
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
                      setDetails(details, dragonSize, environmentSize);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Accessory picker
          StickerCollectionWidget(isLoadingAccessories: _isLoadingAccessories, userAccessories: userAccessories),
        ],
      ),
      backgroundColor: colorScheme.surface,
    );
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
        final userResponse = await dragonService.supabase
            .from('Users')
            .select('dragons')
            .eq('id', user.id)
            .single();

        if (userResponse['dragons'] != null) {
          final dragonsData = Map<String, dynamic>.from(userResponse['dragons']);

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

          // Notify parent that dragon was updated
          if (widget.onDragonUpdated != null) {
            widget.onDragonUpdated!(widget.dragonId);
          }
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loading environments...'))
      );
      return;
    }

    if (userEnvironments.isEmpty) {
      print('❌ No environments available');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No environments available'))
      );
      return;
    }

    print('📦 Available environments: $userEnvironments');
    print('📦 Environment IDs: $userEnvironmentIds');

    int? choice = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
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

      // Use the callback instead of parent state
      if (widget.onEnvironmentChanged != null) {
        print('🔄 Calling environment changed callback...');
        widget.onEnvironmentChanged!(widget.dragonId, userEnvironmentIds[choice]);
      } else {
        print('⚠️ No environment change callback provided');
      }
    } else {
      print('❌ Invalid environment selection or dialog cancelled');
    }
  }

  void _updateStickerPosition(String id, Offset newPosition, double containerSize) {
    setState(() {
      final sticker = placedStickers.firstWhere((s) => s.id == id);

      // Allow stickers to move in the expanded area
      // Subtract an extra for padding
      final clampedX = newPosition.dx.clamp(
          0,
          containerSize
      ).toDouble();

      final clampedY = newPosition.dy.clamp(
          0,
          containerSize
      ).toDouble();

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
        final userResponse = await dragonService.supabase
            .from('Users')
            .select('dragons')
            .eq('id', user.id)
            .single();

        if (userResponse['dragons'] != null) {
          final dragonsData = Map<String, dynamic>.from(userResponse['dragons']);

          // Convert stickers to the format we want to save
          final stickersData = placedStickers.map((sticker) => {
            'id': sticker.id,
            'size': sticker.size,
            'position': {
              'x': sticker.position.dx,
              'y': sticker.position.dy,
            },
            'accessory_id': sticker.name,
          }).toList();

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

          // Notify parent that dragon was updated
          if (widget.onDragonUpdated != null) {
            widget.onDragonUpdated!(widget.dragonId);
          }
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

  void setDetails(DragTargetDetails details, double dragonSize, double dragTargetSize) {
    final data = details.data;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.offset);

    // Find the dragon container's position
    final dragonBox = context.findRenderObject() as RenderBox;
    final dragonPosition = dragonBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    // Calculate position relative to drag target container (which is now larger)
    final dragTargetLeft = (screenSize.width - dragTargetSize) / 2;
    final dragTargetTop = dragonPosition.dy + (dragonBox.size.height - dragTargetSize) / 2;

    // Calculate position relative to the actual dragon area within the drag target
    final dragonOffsetX = (dragTargetSize - dragonSize) / 2;
    final dragonOffsetY = (dragTargetSize - dragonSize) / 2;

    final relativeX = details.offset.dx - dragTargetLeft - dragonOffsetX - 24; // Adjust for icon size
    final relativeY = details.offset.dy - dragTargetTop - dragonOffsetY - 24;

    // Allow stickers to be placed in the expanded area (outside dragon bounds)
    final expandedBounds = dragTargetSize - 48; // Account for sticker size
    final clampedX = relativeX.clamp(-dragonOffsetX, expandedBounds - dragonOffsetX).toDouble();
    final clampedY = relativeY.clamp(-dragonOffsetY, expandedBounds - dragonOffsetY).toDouble();

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
  }


}

