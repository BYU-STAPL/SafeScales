// --- Dragon Dress Up Page ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/providers/dragon_decoration_provider.dart';
import 'package:safe_scales/ui/widgets/dragon_image_widget.dart';
import 'package:safe_scales/ui/widgets/sticker_collection_widget.dart';
import 'package:safe_scales/models/sticker_item_model.dart';
import '../../../providers/dragon_provider.dart';

class DragonDressUpPage extends StatefulWidget {
  final String dragonId;
  final String currentPhase;

  const DragonDressUpPage({
    super.key,
    required this.dragonId,
    required this.currentPhase,
  });

  @override
  _DragonDressUpPageState createState() => _DragonDressUpPageState();
}

class _DragonDressUpPageState extends State<DragonDressUpPage> {
  String selectedPhase = '';

  @override
  void initState() {
    super.initState();
    selectedPhase = widget.currentPhase;

    // Use addPostFrameCallback to ensure initialization happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final dragonDecorationProvider = Provider.of<DragonDecorationProvider>(
      context,
      listen: false,
    );

    try {
      // Initialize the decoration provider if not already done
      if (!dragonDecorationProvider.isInitialized) {
        await dragonDecorationProvider.initialize(widget.dragonId);
      }

      await _loadCurrentPhase();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  Future<void> _loadCurrentPhase() async {
    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
    await dragonProvider.initialize();

    final phase = await dragonProvider.getUserPreferredPhase(widget.dragonId);

    try {
      final availablePhases =
          dragonProvider.unlockedDragonPhases[widget.dragonId];
      if (availablePhases != null && availablePhases.contains(phase)) {
        setState(() => selectedPhase = phase);
      }
    } catch (e) {
      debugPrint('Error loading current phase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double dragonSize = MediaQuery.of(context).size.width * 0.75;

    final environmentSize = (
      width: dragonSize * 1.25,
      height: dragonSize * 1.8,
    );

    final stickerEnvironmentSize = (
      width: environmentSize.width - 10,
      height: environmentSize.height - 10,
    );

    return Consumer2<DragonDecorationProvider, DragonProvider>(
      builder: (context, dragonDecorationProvider, dragonProvider, child) {
        // Show loading indicator if still initializing
        if (dragonDecorationProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Play'),
              centerTitle: true,
              backgroundColor: colorScheme.surface,
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show error if there's an error
        if (dragonDecorationProvider.error != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Play'),
              centerTitle: true,
              backgroundColor: colorScheme.surface,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: colorScheme.error),
                  SizedBox(height: 16),
                  Text(
                    'Error: ${dragonDecorationProvider.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => dragonDecorationProvider.refresh(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

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
                  const SizedBox(width: 15),
                  const Icon(Icons.edit, size: 25),
                ],
              ),
            ),
            centerTitle: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 35),
                onSelected: (value) {
                  if (value == 'phase') _showPhaseDialog();
                  if (value == 'env') _showEnvironmentDialog();
                  if (value == 'clear') _clearAllStickers();
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
              // Hint info
              Container(
                // padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Tap an item to move and resize it',
                      style: theme.textTheme.labelSmall,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Long press an item to remove it',
                      style: theme.textTheme.labelSmall,
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
                      if (dragonDecorationProvider.getCurrentEnvironment() !=
                          null)
                        Container(
                          width: environmentSize.width,
                          height: environmentSize.height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            image: DecorationImage(
                              image: NetworkImage(
                                dragonDecorationProvider
                                    .getCurrentEnvironment()!
                                    .imageUrl,
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
                          return GestureDetector(
                            onTap: () {
                              // Deselect any currently selected sticker when tapping background
                              dragonDecorationProvider.selectSticker(null);
                            },
                            child: Container(
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
                                    // Placed stickers from provider
                                    ...dragonDecorationProvider.placedStickers
                                        .map((sticker) {
                                          final isSelected =
                                              dragonDecorationProvider
                                                  .selectedStickerId ==
                                              sticker.id;

                                          return _buildSticker(
                                            sticker,
                                            isSelected,
                                            stickerEnvironmentSize,
                                            dragonDecorationProvider,
                                          );
                                        }),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        onAcceptWithDetails: (details) {
                          _handleStickerDrop(
                            details,
                            dragonSize,
                            environmentSize,
                            dragonDecorationProvider,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Accessory picker
              StickerCollectionWidget(
                isLoadingAccessories:
                    dragonDecorationProvider.isLoadingAccessories,
                userAccessories: dragonDecorationProvider.userItems,
              ),
            ],
          ),
          backgroundColor: colorScheme.surface,
        );
      },
    );
  }

  String _getEnvironmentDisplayName(DragonDecorationProvider provider) {
    if (provider.isLoadingEnvironments) {
      return 'Loading...';
    }

    if (provider.isNoEnvironmentSelected) {
      return 'None';
    }

    final currentEnv = provider.getCurrentEnvironment();
    return currentEnv?.name ?? 'None';
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

    if (choice != null && choice < availablePhases.length) {
      setState(() => selectedPhase = availablePhases[choice]);
      // Note: For now, we're just updating the UI.
      // When you implement user preference saving, you would call:
      await dragonProvider.updateUserPreferredPhase(
        widget.dragonId,
        availablePhases[choice],
      );
    }
  }

  void _showEnvironmentDialog() async {
    final decorationProvider = Provider.of<DragonDecorationProvider>(
      context,
      listen: false,
    );

    if (decorationProvider.isLoadingEnvironments) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Loading environments...')));
      return;
    }

    int? choice = await showDialog<int>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Select Environment'),
            children: _buildEnvironmentList(decorationProvider),
          ),
    );

    if (choice != null) {
      decorationProvider.selectEnvironment(choice, choice == -1);

      // Save environment selection
      if (choice != -1 && choice < decorationProvider.userEnvironments.length) {
        final environmentId = decorationProvider.userEnvironments[choice].id;
        await decorationProvider.saveEnvironmentSelection(
          widget.dragonId,
          environmentId,
        );
      } else {
        await decorationProvider.saveEnvironmentSelection(widget.dragonId, "");
      }
    }
  }

  List<Widget> _buildEnvironmentList(
    DragonDecorationProvider decorationProvider,
  ) {
    List<Widget> envOptions = [
      SimpleDialogOption(
        onPressed: () => Navigator.pop(context, -1),
        child: Text('None'),
      ),
    ];

    envOptions.addAll(
      List.generate(
        decorationProvider.userEnvironments.length,
        (i) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, i),
          child: Text(decorationProvider.userEnvironments[i].name),
        ),
      ),
    );

    return envOptions;
  }

  Positioned _buildSticker(
    StickerItem sticker,
    bool isSelected,
    ({double width, double height}) stickerEnvironmentSize,
    DragonDecorationProvider provider,
  ) {
    ThemeData theme = Theme.of(context);

    return Positioned(
      left: sticker.position.dx,
      top: sticker.position.dy,
      child: GestureDetector(
        onTap: () {
          // Only select the sticker, don't toggle
          provider.selectSticker(sticker.id);
        },
        onLongPress: () => _removeSticker(sticker.id, provider),
        child: Stack(
          children: [
            GestureDetector(
              onPanUpdate: (details) {
                if (isSelected) {
                  final newPosition = Offset(
                    sticker.position.dx + details.delta.dx,
                    sticker.position.dy + details.delta.dy,
                  );
                  provider.updateStickerPosition(
                    stickerId: sticker.id,
                    newPosition: newPosition,
                    containerSize: Size(
                      stickerEnvironmentSize.width,
                      stickerEnvironmentSize.height,
                    ),
                  );
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
                    provider.updateStickerSize(sticker.id, newSize);
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

  void _removeSticker(String id, DragonDecorationProvider provider) {
    provider.removeSticker(id);
  }

  void _clearAllStickers() {
    final provider = Provider.of<DragonDecorationProvider>(
      context,
      listen: false,
    );
    provider.clearAllStickers();
  }

  void _handleStickerDrop(
    DragTargetDetails details,
    double dragonSize,
    ({double height, double width}) environmentSize,
    DragonDecorationProvider provider,
  ) {
    final data = details.data;

    // Calculate the drop position using the provider's utility method
    final dropPosition = provider.calculateDropPosition(
      screenOffset: details.offset,
      dragonSize: Size(dragonSize, dragonSize),
      environmentSize: Size(environmentSize.width, environmentSize.height),
      screenSize: MediaQuery.of(context).size,
      dragonPosition: Offset(
        (MediaQuery.of(context).size.width - environmentSize.width) / 2,
        0, // This would need to be calculated based on your layout
      ),
      stickerSize: 48.0,
    );

    // Create an Item object from the drag data
    final item = Item(
      id: data['id'].toString(),
      type: ItemType.item,
      name: data['name'],
      imageUrl: data['image'],
      cost: 0,
      // Add other required properties based on your Item model
    );

    // Add the sticker using the provider
    provider.addSticker(item: item, position: dropPosition, size: 48.0);
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
                      // labelText: 'Dragon Name',
                      hintText: 'Enter Your Dragon\'s Name',
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
