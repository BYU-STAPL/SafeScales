// --- Dragon Dress Up Page ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/ui/widgets/dragon_image_widget.dart';
import 'package:safe_scales/ui/widgets/sticker_collection_widget.dart';

import 'package:safe_scales/models/sticker_item_model.dart';

import '../../../services/shop_service.dart';
import '../../../config/supabase_config.dart';
import '../../../services/user_state_service.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/dragon_provider.dart';

class DragonDressUpPage extends StatefulWidget {
  final String dragonId;
  final String currentPhase;
  // final Function(String dragonId, String environmentId)? onEnvironmentChanged;
  // final Function(String dragonId)? onDragonUpdated;

  const DragonDressUpPage({
    super.key,
    required this.dragonId,
    required this.currentPhase,
    // this.onEnvironmentChanged,
    // this.onDragonUpdated,
  });

  @override
  _DragonDressUpPageState createState() => _DragonDressUpPageState();
}

class _DragonDressUpPageState extends State<DragonDressUpPage> {
  String selectedPhase = '';
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

  // List<String> _availablePhases = [];

  @override
  void initState() {
    super.initState();
    _loadUserEnvironments();
    _loadUserAccessories();
    _loadCurrentPhase();

    // Set selected phase so no waiting
    setState(() {
      selectedPhase = widget.currentPhase;
    });
  }

  Future<void> _loadUserEnvironments() async {
    try {
      final userState = UserStateService();
      final user = userState.currentUser;

      if (user != null) {
        final shopService = ShopService();

        // Get user's acquired environment IDs
        final envIds = await shopService.getUserAcquiredEnvironments(user.id);

        // Get all environments for the user's class and filter to acquired
        final allEnvs = await shopService.getEnvironments();
        final foundEnvironments =
            allEnvs
                .where((env) => envIds.contains(env['id']))
                .map(
                  (env) => {
                    'id': env['id'],
                    'name': env['name'],
                    'image_url': env['image_url'] ?? env['imageUrl'],
                  },
                )
                .toList();

        if (mounted) {
          if (foundEnvironments.isNotEmpty) {
            setState(() {
              userEnvironmentIds =
                  foundEnvironments.map((env) => env['id'] as String).toList();
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

            // Use state manager to get current environment
            final dragonProvider = Provider.of<DragonProvider>(
              context,
              listen: false,
            );
            final currentEnvId = dragonProvider.currentEnvironment;
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
          } else {
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
      print('❌ Error loading user environments: $e');
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
        final shopService = ShopService();

        final acquiredIds = await shopService.getUserAcquiredAccessories(
          user.id,
        );
        final allAccessories = await shopService.getAccessories();

        final foundAccessories =
            allAccessories
                .where((acc) => acquiredIds.contains(acc['id'].toString()))
                .map(
                  (asset) => {
                    'id': asset['id'],
                    'name': asset['name'],
                    'image': asset['image_url'] ?? asset['imageUrl'],
                  },
                )
                .toList();

        setState(() {
          userAccessories = foundAccessories;
          _isLoadingAccessories = false;
        });
        print('✅ Loaded ${userAccessories.length} accessories');
        _onAccessoriesLoaded();
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
    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
    await dragonProvider.initialize();
    // await dragonProvider.loadUserDragons();

    final phase = dragonProvider.getUserPreferredPhase(widget.dragonId);

    try {
      final availablePhases =
          dragonProvider.unlockedDragonPhases[widget.dragonId]!;

      final index = availablePhases.indexOf(phase);

      if (index != -1 && mounted) {
        setState(() => selectedPhase = phase);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    final double dragonSize = MediaQuery.of(context).size.width * 0.75;

    final environmentSize = (
      width: dragonSize * 1.25,
      height: dragonSize * 1.75,
    );

    final stickerEnvironmentSize = (
      width: environmentSize.width - 10,
      height: environmentSize.height - 10,
    );

    return Consumer2<DragonProvider, CourseProvider>(
      builder: (context, dragonProvider, courseProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => _showNameDialog(dragonProvider),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dragonProvider.getDragonById(widget.dragonId)?.name ??
                        'Unnamed Dragon',
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 16),
                ],
              ),
            ),
            centerTitle: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: colorScheme.primary),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 35),
                onSelected: (value) {
                  if (value == 'phase') _showPhaseDialog();
                  if (value == 'env') _showEnvironmentDialog();
                  if (value == 'clear') {
                    setState(() {
                      placedStickers.clear();
                    });
                    _saveDressUp();
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
                      'Phase: ${dragonProvider.getPhaseDisplayName(selectedPhase)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Environment: ${_isLoadingEnvironments ? 'Loading...' : (userEnvironments.isNotEmpty && selectedEnvironment < userEnvironments.length ? userEnvironments[selectedEnvironment] : 'None')}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Dragon area with drop zone
              Expanded(
                child: Center(
                  child: DragTarget<Map<String, dynamic>>(
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        width: stickerEnvironmentSize.width,
                        height: stickerEnvironmentSize.height,
                        decoration: BoxDecoration(
                          color:
                              candidateData.isNotEmpty
                                  ? colorScheme.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                candidateData.isNotEmpty
                                    ? colorScheme.primary
                                    : colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                            width: candidateData.isNotEmpty ? 3 : 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // Environment background
                              if (userEnvironmentImages.isNotEmpty &&
                                  selectedEnvironment <
                                      userEnvironmentImages.length)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          userEnvironmentImages[selectedEnvironment],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),

                              // Dragon Image - centered
                              Center(
                                child: DragonImageWidget(
                                  dragonId: widget.dragonId,
                                  size: dragonSize * 0.75,
                                  phase: selectedPhase,
                                ),
                              ),

                              // Placed stickers
                              ...placedStickers.map((sticker) {
                                final isSelected =
                                    selectedStickerId == sticker.id;

                                return _buildSticker(
                                  sticker,
                                  isSelected,
                                  stickerEnvironmentSize,
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                    onAcceptWithDetails: (details) {
                      setDetails(details, dragonSize, stickerEnvironmentSize);
                    },
                  ),
                ),
              ),

              // Accessory picker
              StickerCollectionWidget(
                isLoadingAccessories: _isLoadingAccessories,
                userAccessories: userAccessories,
              ),
            ],
          ),
          backgroundColor: colorScheme.surface,
        );
      },
    );
  }

  // Get available phases using state manager
  // List<String> get availablePhases {
  //   // Get phases from state manager instead of widget.phases
  //   // final userPhases = _stateManager.userDragons;
  //
  //   List<String> phases = ['egg'];
  //
  //   // Check if dragon has each phase using state manager
  //   if (_stateManager.hasPhase(widget.dragonId, 'stage1')) phases.add('stage1');
  //   if (_stateManager.hasPhase(widget.dragonId, 'stage2')) phases.add('stage2');
  //   if (_stateManager.hasPhase(widget.dragonId, 'final')) phases.add('final');
  //
  //   return phases;
  // }

  // Get image URL for current phase using state manager
  // String getCurrentPhasePhase() {
  //   return availablePhases[selectedPhase];
  // }

  void _showPhaseDialog() async {
    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);

    final availablePhases =
        dragonProvider.unlockedDragonPhases[widget.dragonId];
    if (availablePhases == null) {
      print("Error DragonDecoration showPhaseDialog: No available phases");
      return;
    }

    int? choice = await showDialog<int>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Select Dragon Phase'),
            children: List.generate(
              availablePhases.length,
              (i) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, i),
                child: Text(
                  dragonProvider.getPhaseDisplayName(availablePhases[i]),
                ),
              ),
            ),
          ),
    );
    if (choice != null) {
      setState(() => selectedPhase = availablePhases[choice]);
      // Note: For now, we're just updating the UI.
      // When you implement user preference saving,
      // you would call something like:
      // await dragonProvider.saveUserPreferredPhase(widget.dragonId, availablePhases[choice]);
    }
  }

  void _showEnvironmentDialog() async {
    if (_isLoadingEnvironments) {
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

    int? choice = await showDialog<int>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Select Environment'),
            children: List.generate(
              userEnvironments.length,
              (i) => SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, i);
                },
                child: Text(userEnvironments[i]),
              ),
            ),
          ),
    );

    if (choice != null && choice < userEnvironments.length) {
      setState(() => selectedEnvironment = choice);

      // Use state manager to save environment selection
      final dragonProvider = Provider.of<DragonProvider>(
        context,
        listen: false,
      );
      await dragonProvider.saveEnvironmentSelection(
        widget.dragonId,
        userEnvironmentIds[choice],
      );

      // Use the callback for parent notification
      // if (widget.onEnvironmentChanged != null) {
      //   widget.onEnvironmentChanged!(widget.dragonId, userEnvironmentIds[choice]);
      // }
    }
  }

  Positioned _buildSticker(
    StickerItem sticker,
    bool isSelected,
    ({double width, double height}) stickerEnvironmentSize,
  ) {
    ThemeData theme = Theme.of(context);

    return Positioned(
      left: sticker.position.dx,
      top: sticker.position.dy,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedStickerId = isSelected ? null : sticker.id;
          });
        },
        onLongPress: () => _removeSticker(sticker.id),
        child: Stack(
          children: [
            GestureDetector(
              onPanUpdate: (details) {
                if (isSelected) {
                  final newPosition = Offset(
                    sticker.position.dx + details.delta.dx,
                    sticker.position.dy + details.delta.dy,
                  );
                  _updateStickerPosition(sticker.id, newPosition, (
                    width: stickerEnvironmentSize.width - sticker.size,
                    height: stickerEnvironmentSize.height - sticker.size,
                  ));
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
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
                    _updateStickerSize(sticker.id, newSize);
                  },
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _updateStickerPosition(
    String id,
    Offset newPosition,
    ({double width, double height}) containerSize,
  ) {
    setState(() {
      final sticker = placedStickers.firstWhere((s) => s.id == id);

      // Simple clamping to keep sticker within bounds
      final double clampedX = newPosition.dx.clamp(
        0,
        containerSize.width - sticker.size,
      );
      final double clampedY = newPosition.dy.clamp(
        0,
        containerSize.height - sticker.size,
      );

      sticker.position = Offset(clampedX, clampedY);
    });
    _saveDressUp(); // Save after moving
  }

  void _updateStickerSize(String id, double newSize) {
    setState(() {
      final sticker = placedStickers.firstWhere((s) => s.id == id);
      sticker.size = newSize.clamp(20.0, 150.0); // Limit size
    });
    _saveDressUp(); // Save after resizing
  }

  void _removeSticker(String id) {
    setState(() {
      placedStickers.removeWhere((sticker) => sticker.id == id);
      if (selectedStickerId == id) {
        selectedStickerId = null;
      }
    });
    _saveDressUp(); // Save after removing
  }

  Future<void> _saveDressUp() async {
    try {
      final userState = UserStateService();
      final user = userState.currentUser;

      if (user != null) {
        // Convert stickers to a simple list format
        final List<Map<String, dynamic>> stickersData =
            placedStickers
                .map(
                  (sticker) => {
                    'id': sticker.id,
                    'accessoryId': sticker.accessoryId,
                    'x': sticker.position.dx,
                    'y': sticker.position.dy,
                    'size': sticker.size,
                  },
                )
                .toList();

        // Save as a simple JSON array
        await SupabaseConfig.client
            .from('Users')
            .update({
              'dragon_dressup': {widget.dragonId: stickersData},
            })
            .eq('id', user.id);

        print(
          '✅ Saved ${stickersData.length} stickers for dragon ${widget.dragonId}',
        );
      }
    } catch (e) {
      print('❌ Error saving dragon dress-up: $e');
    }
  }

  Future<void> _loadDressUp() async {
    try {
      final userState = UserStateService();
      final user = userState.currentUser;

      if (user != null) {
        // Get current dragon_dressup data
        final userResponse =
            await SupabaseConfig.client
                .from('Users')
                .select('dragon_dressup')
                .eq('id', user.id)
                .single();

        final Map<String, dynamic>? dressUpData =
            userResponse['dragon_dressup'] != null
                ? Map<String, dynamic>.from(userResponse['dragon_dressup'])
                : null;

        if (dressUpData != null && dressUpData.containsKey(widget.dragonId)) {
          final List<dynamic> stickersList = dressUpData[widget.dragonId] ?? [];
          final List<StickerItem> restored = [];

          for (final stickerData in stickersList) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              stickerData,
            );
            final String accessoryId = data['accessoryId']?.toString() ?? '';

            // Find accessory image by ID
            final accessory = userAccessories.firstWhere(
              (acc) => acc['id'].toString() == accessoryId,
              orElse: () => {'image': '', 'name': ''},
            );

            restored.add(
              StickerItem(
                id:
                    data['id']?.toString() ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                imageUrl: accessory['image'] ?? '',
                name: accessory['name']?.toString() ?? accessoryId,
                accessoryId: accessoryId,
                position: Offset(
                  (data['x'] ?? 0).toDouble(),
                  (data['y'] ?? 0).toDouble(),
                ),
                size: (data['size'] ?? 48).toDouble(),
              ),
            );
          }

          setState(() {
            placedStickers = restored;
          });
          print(
            '✅ Loaded ${restored.length} stickers for dragon ${widget.dragonId}',
          );
        }
      }
    } catch (e) {
      print('❌ Error loading dragon dress-up: $e');
    }
  }

  // Add a method to load dress-up after accessories are loaded
  void _onAccessoriesLoaded() {
    _loadDressUp();
  }

  void setDetails(
    DragTargetDetails details,
    double dragonSize,
    ({double height, double width}) environmentSize,
  ) {
    final data = details.data;

    // The details.offset is the position where the user dropped the sticker
    // We want the sticker to appear exactly where they dropped it
    final double stickerSize = 48.0;

    // Use the drop position directly
    final double x = details.offset.dx;
    final double y = details.offset.dy;

    // Clamp to stay within bounds (accounting for sticker size)
    final double clampedX = x.clamp(0, environmentSize.width - stickerSize);
    final double clampedY = y.clamp(0, environmentSize.height - stickerSize);

    setState(() {
      final newSticker = StickerItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageUrl: data['image'],
        name: data['name'],
        accessoryId: data['id'].toString(),
        position: Offset(clampedX, clampedY),
        size: stickerSize,
      );
      placedStickers.add(newSticker);
    });

    _saveDressUp(); // Save after adding
  }

  void _showNameDialog(DragonProvider dragonProvider) {
    final TextEditingController nameController = TextEditingController(
      text: dragonProvider.getDragonById(widget.dragonId)?.name ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Dragon Name'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Dragon Name',
                      hintText: 'Enter a name for your dragon',
                      counterText: '${nameController.text.length}/10',
                      errorText:
                          nameController.text.length > 10
                              ? 'Name cannot be longer than 10 characters'
                              : null,
                    ),
                    autofocus: true,
                    maxLength: 10,
                    onChanged: (value) {
                      setState(() {}); // Update counter and error text
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed:
                      nameController.text.trim().isEmpty ||
                              nameController.text.length > 10
                          ? null // Disable button if name is empty or too long
                          : () async {
                            try {
                              await dragonProvider.updateDragonName(
                                widget.dragonId,
                                nameController.text,
                              );
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
