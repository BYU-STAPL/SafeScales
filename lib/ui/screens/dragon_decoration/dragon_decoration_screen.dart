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

        _onAccessoriesLoaded();

      }
      else {
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
      print('❌ Error: $e');
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
            title: Text('Play'),
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
                        child: Text('Clear All Items'),
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Environment background
                      if (userEnvironmentImages.isNotEmpty &&
                          selectedEnvironment < userEnvironmentImages.length)
                        Container(
                          width: environmentSize.width,
                          height: environmentSize.height,
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
                      DragonImageWidget(
                        dragonId: widget.dragonId,
                        size: dragonSize * 0.75,
                        phase: selectedPhase,
                      ),

                      // Drop zone for dragon
                      DragTarget<Map<String, dynamic>>(
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            width: environmentSize.width,
                            height: environmentSize.height,
                            decoration: BoxDecoration(
                              color:
                                  candidateData.isNotEmpty
                                      ? colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      )
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
                          setDetails(details, dragonSize, environmentSize);
                        },
                      ),
                    ],
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

  void _showPhaseDialog() async {
    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);

    final availablePhases =
        dragonProvider.unlockedDragonPhases[widget.dragonId];
    if (availablePhases == null) {
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

      // Allow stickers to move in the expanded area
      // Subtract an extra for padding
      final clampedX = newPosition.dx.clamp(0, containerSize.width).toDouble();

      final clampedY = newPosition.dy.clamp(0, containerSize.height).toDouble();

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
        // Get current dragon_dressup data, merge and update
        final userResponse =
            await SupabaseConfig.client
                .from('Users')
                .select('dragon_dressup')
                .eq('id', user.id)
                .single();

        final Map<String, dynamic> dressUpData =
            userResponse['dragon_dressup'] != null
                ? Map<String, dynamic>.from(userResponse['dragon_dressup'])
                : <String, dynamic>{};

        // Build this dragon's accessories map: { accessoryId: { position: {x,y}, size } }
        final Map<String, dynamic> accessoriesForDragon = {};
        for (final sticker in placedStickers) {
          accessoriesForDragon[sticker.accessoryId] = {
            'position': {'x': sticker.position.dx, 'y': sticker.position.dy},
            'size': sticker.size,
          };
        }

        dressUpData[widget.dragonId] = accessoriesForDragon;

        await SupabaseConfig.client
            .from('Users')
            .update({'dragon_dressup': dressUpData})
            .eq('id', user.id);

        setState(() {});
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
          final Map<String, dynamic> dragonMap = Map<String, dynamic>.from(
            dressUpData[widget.dragonId],
          );

          final List<StickerItem> restored = [];

          dragonMap.forEach((accId, data) {
            final Map<String, dynamic> d = Map<String, dynamic>.from(data);
            final Map<String, dynamic> pos = Map<String, dynamic>.from(
              d['position'] ?? {},
            );

            // Find accessory image by ID
            final accessory = userAccessories.firstWhere(
              (acc) => acc['id'].toString() == accId.toString(),
              orElse: () => {'image': '', 'name': ''},
            );

            restored.add(
              StickerItem(
                id: 'acc_$accId',
                imageUrl: accessory['image'] ?? '',
                name: accessory['name']?.toString() ?? accId.toString(),
                accessoryId: accId.toString(),
                position: Offset(
                  (pos['x'] ?? 0).toDouble(),
                  (pos['y'] ?? 0).toDouble(),
                ),
                size: (d['size'] ?? 48).toDouble(),
              ),
            );
          });

          setState(() {
            placedStickers = restored;
          });
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

    // Find the dragon container's position
    final dragonBox = context.findRenderObject() as RenderBox;
    final dragonPosition = dragonBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    // Calculate position relative to drag target container (which is now larger)
    final dragTargetLeft = (screenSize.width - environmentSize.width) / 2;
    final dragTargetTop =
        dragonPosition.dy +
        (dragonBox.size.height - environmentSize.height) / 2;

    // Calculate position relative to the actual dragon area within the drag target
    final dragonOffsetX = (environmentSize.width - dragonSize) / 2;
    final dragonOffsetY = (environmentSize.height - dragonSize) / 2;

    final relativeX =
        details.offset.dx -
        dragTargetLeft -
        dragonOffsetX -
        24; // Adjust for icon size
    final relativeY = details.offset.dy - dragTargetTop - dragonOffsetY - 24;

    // Allow stickers to be placed in the expanded area
    final expandedBoundsX =
        environmentSize.width - 48; // Account for sticker size
    final expandedBoundsY =
        environmentSize.height - 48; // Account for sticker size

    final clampedX =
        relativeX
            .clamp(-dragonOffsetX, expandedBoundsX - dragonOffsetX)
            .toDouble();
    final clampedY =
        relativeY
            .clamp(-dragonOffsetY, expandedBoundsY - dragonOffsetY)
            .toDouble();

    setState(() {
      final newSticker = StickerItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageUrl: data['image'],
        name: data['name'],
        accessoryId: data['id'].toString(),
        position: Offset(clampedX, clampedY),
      );
      placedStickers.add(newSticker);
    });

    _saveDressUp(); // Save after adding
  }
}
