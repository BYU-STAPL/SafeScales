// --- Dragon Dress Up Page ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  final GlobalKey _habitatKey = GlobalKey();

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double dragonSize = screenWidth * 0.75;

    // Ensure environment size doesn't exceed screen bounds
    final environmentWidth = (dragonSize * 1.25).clamp(0.0, screenWidth * 0.95);
    final environmentHeight = (dragonSize * 1.8).clamp(0.0, screenHeight * 0.6);

    final environmentSize = (
      width: environmentWidth,
      height: environmentHeight,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      dragonProvider.getDragonById(widget.dragonId)?.name ??
                          'Unnamed Dragon',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
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
                  if (value == 'clear') {
                    _clearAllStickers();
                  } else if (value == 'select') {
                    _showPlacedItemsSheet(dragonDecorationProvider);
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'select',
                        child: Text('Select item...'),
                      ),
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
              // Hint info with hints button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Text(
                            'Tap an item to move and resize it',
                            style: theme.textTheme.labelSmall,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Use buttons to resize or change layer',
                            style: theme.textTheme.labelSmall,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Long press an item to remove it',
                            style: theme.textTheme.labelSmall,
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.help_outline, size: 28),
                      tooltip: 'Decoration tips',
                      onPressed: _showHintsDialog,
                    ),
                  ],
                ),
              ),

              // Prominent selection buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showPhaseDialog(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                theme.brightness == Brightness.light
                                    ? colorScheme.primary.withValues(alpha: 0.2)
                                    : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  theme.brightness == Brightness.light
                                      ? colorScheme.primary.withValues(
                                        alpha: 0.6,
                                      )
                                      : colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.dragon,
                                size: 20,
                                color:
                                    theme.brightness == Brightness.light
                                        ? colorScheme.primary
                                        : colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Dragon Phase',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.brightness == Brightness.light
                                            ? colorScheme.primary
                                            : colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showEnvironmentDialog(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                dragonDecorationProvider
                                            .getCurrentEnvironment() !=
                                        null
                                    ? (theme.brightness == Brightness.light
                                        ? colorScheme.primary.withValues(
                                          alpha: 0.2,
                                        )
                                        : colorScheme.primaryContainer)
                                    : (theme.brightness == Brightness.light
                                        ? _lightModeUnselectedSurface(
                                          colorScheme,
                                        )
                                        : colorScheme.surfaceContainerHighest),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  dragonDecorationProvider
                                              .getCurrentEnvironment() !=
                                          null
                                      ? (theme.brightness == Brightness.light
                                          ? colorScheme.primary.withValues(
                                            alpha: 0.6,
                                          )
                                          : colorScheme.primary.withValues(
                                            alpha: 0.3,
                                          ))
                                      : colorScheme.outline.withValues(
                                        alpha: 0.3,
                                      ),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.landscape,
                                size: 20,
                                color:
                                    dragonDecorationProvider
                                                .getCurrentEnvironment() !=
                                            null
                                        ? (theme.brightness == Brightness.light
                                            ? colorScheme.primary
                                            : colorScheme.onPrimaryContainer)
                                        : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _getEnvironmentDisplayName(
                                    dragonDecorationProvider,
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        dragonDecorationProvider
                                                    .getCurrentEnvironment() !=
                                                null
                                            ? (theme.brightness ==
                                                    Brightness.light
                                                ? colorScheme.primary
                                                : colorScheme
                                                    .onPrimaryContainer)
                                            : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dragon area with drop zone - wrapped in SizedBox for habitat-local coordinates
              Expanded(
                child: Center(
                  child: SizedBox(
                    key: _habitatKey,
                    width: environmentSize.width,
                    height: environmentSize.height,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Environment background
                        if (dragonDecorationProvider.getCurrentEnvironment() !=
                            null)
                          Positioned.fill(
                            child: Container(
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
                          ),

                        // Stickers behind the dragon
                        ...dragonDecorationProvider.placedStickers
                            .where((sticker) => sticker.isBehindDragon)
                            .map((sticker) {
                              final isSelected =
                                  dragonDecorationProvider.selectedStickerId ==
                                  sticker.id;

                              return _buildSticker(
                                sticker,
                                isSelected,
                                environmentSize,
                                dragonDecorationProvider,
                              );
                            }),

                        // Drop zone for dragon
                        // Wrapped in IgnorePointer when not dragging to allow stickers behind to receive touches
                        DragTarget<Map<String, dynamic>>(
                          hitTestBehavior: HitTestBehavior.translucent,
                          builder: (context, candidateData, rejectedData) {
                            return IgnorePointer(
                              ignoring: candidateData.isEmpty,
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

                        // Dragon Image - wrapped in IgnorePointer so stickers behind can be interacted with
                        IgnorePointer(
                          child: DragonImageWidget(
                            dragonId: widget.dragonId,
                            size: dragonSize * 0.75,
                            phase: selectedPhase,
                          ),
                        ),

                        // Stickers in front of the dragon
                        ...dragonDecorationProvider.placedStickers
                            .where((sticker) => !sticker.isBehindDragon)
                            .map((sticker) {
                              final isSelected =
                                  dragonDecorationProvider.selectedStickerId ==
                                  sticker.id;

                              return _buildSticker(
                                sticker,
                                isSelected,
                                environmentSize,
                                dragonDecorationProvider,
                              );
                            }),
                      ],
                    ),
                  ),
                ),
              ),

              // Whitespace between dragon habitat and item collection
              const SizedBox(height: 24),

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

  Color _lightModeUnselectedSurface(ColorScheme colorScheme) =>
      colorScheme.surfaceContainerHigh;

  void _showPhaseDialog() async {
    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final unlockedPhases = dragonProvider.unlockedDragonPhases[widget.dragonId];
    if (unlockedPhases == null) {
      return;
    }

    // Get all phases from the dragon
    final dragon = dragonProvider.getDragonById(widget.dragonId);
    if (dragon == null) {
      return;
    }

    final allPhases = dragon.phaseOrder;
    if (allPhases.isEmpty) {
      return;
    }

    final isLight = theme.brightness == Brightness.light;

    int? choice = await showDialog<int>(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: colorScheme.surface,
            child: Container(
              constraints: BoxConstraints(maxWidth: 400, maxHeight: 500),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.dragon,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Dragon Phase',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (ctx) {
                      final unselectedBg =
                          isLight
                              ? _lightModeUnselectedSurface(colorScheme)
                              : colorScheme.surfaceContainerHighest;
                      const cellSpacing = 12.0;

                      Widget buildPhaseCell(int i) {
                        if (i >= allPhases.length) {
                          return const SizedBox.shrink();
                        }
                        final phase = allPhases[i];
                        final isUnlocked = dragonProvider.hasPhase(
                          widget.dragonId,
                          phase,
                        );
                        final isSelected = phase == selectedPhase;
                        final isLocked = !isUnlocked;
                        final imageUrl = dragon.getImageForPhase(phase);
                        const fallback = 'assets/images/other/QuestionMark.png';
                        Widget imageWidget = Image.asset(
                          fallback,
                          fit: BoxFit.contain,
                        );
                        if (imageUrl.isNotEmpty) {
                          if (imageUrl.startsWith('http')) {
                            imageWidget = Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (_, __, ___) => Image.asset(
                                    fallback,
                                    fit: BoxFit.contain,
                                  ),
                            );
                          } else {
                            imageWidget = Image.asset(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (_, __, ___) => Image.asset(
                                    fallback,
                                    fit: BoxFit.contain,
                                  ),
                            );
                          }
                        }
                        return Container(
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? colorScheme.primaryContainer
                                    : isLocked
                                    ? unselectedBg.withValues(alpha: 0.5)
                                    : unselectedBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? colorScheme.primary
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap:
                                  isLocked ? null : () => Navigator.pop(ctx, i),
                              borderRadius: BorderRadius.circular(16),
                              child: Semantics(
                                label: dragonProvider.getPhaseDisplayName(
                                  phase,
                                ),
                                child: Opacity(
                                  opacity: isLocked ? 0.6 : 1.0,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: imageWidget,
                                      ),
                                      if (isLocked)
                                        Icon(
                                          Icons.lock,
                                          color: colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                          size: 28,
                                        ),
                                      if (isSelected && !isLocked)
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Icon(
                                            Icons.check_circle,
                                            color: colorScheme.primary,
                                            size: 24,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: buildPhaseCell(0),
                                ),
                              ),
                              const SizedBox(width: cellSpacing),
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: buildPhaseCell(1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: cellSpacing),
                          Row(
                            children: [
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: buildPhaseCell(2),
                                ),
                              ),
                              const SizedBox(width: cellSpacing),
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: buildPhaseCell(3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
    );

    if (choice != null && choice < allPhases.length) {
      final selectedPhaseValue = allPhases[choice];
      // Only allow selection if the phase is unlocked
      if (dragonProvider.hasPhase(widget.dragonId, selectedPhaseValue)) {
        setState(() => selectedPhase = selectedPhaseValue);
        await dragonProvider.updateUserPreferredPhase(
          widget.dragonId,
          selectedPhaseValue,
        );
      }
    }
  }

  void _showEnvironmentDialog() async {
    final decorationProvider = Provider.of<DragonDecorationProvider>(
      context,
      listen: false,
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (decorationProvider.isLoadingEnvironments) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Loading habitats...')));
      return;
    }

    final currentEnv = decorationProvider.getCurrentEnvironment();
    final currentEnvId = currentEnv?.id ?? '';

    final isLight = theme.brightness == Brightness.light;
    final unselectedBg =
        isLight
            ? _lightModeUnselectedSurface(colorScheme)
            : colorScheme.surfaceContainerHighest;

    int? choice = await showDialog<int>(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: colorScheme.surface,
            child: Container(
              constraints: BoxConstraints(maxWidth: 400, maxHeight: 500),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.landscape,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Habitat',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // None option
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color:
                                  decorationProvider.isNoEnvironmentSelected
                                      ? colorScheme.primaryContainer
                                      : unselectedBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    decorationProvider.isNoEnvironmentSelected
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context, -1),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      if (decorationProvider
                                          .isNoEnvironmentSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: colorScheme.primary,
                                          size: 24,
                                        )
                                      else
                                        Icon(
                                          Icons.circle_outlined,
                                          color: colorScheme.onSurfaceVariant,
                                          size: 24,
                                        ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'None',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color:
                                                decorationProvider
                                                        .isNoEnvironmentSelected
                                                    ? colorScheme
                                                        .onPrimaryContainer
                                                    : colorScheme.onSurface,
                                            fontWeight:
                                                decorationProvider
                                                        .isNoEnvironmentSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Environment options
                          ...List.generate(
                            decorationProvider.userEnvironments.length,
                            (i) {
                              final env =
                                  decorationProvider.userEnvironments[i];
                              final isSelected = env.id == currentEnvId;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? colorScheme.primaryContainer
                                          : unselectedBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? colorScheme.primary
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context, i),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      child: Row(
                                        children: [
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle,
                                              color: colorScheme.primary,
                                              size: 24,
                                            )
                                          else
                                            Icon(
                                              Icons.circle_outlined,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              size: 24,
                                            ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              env.name,
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    color:
                                                        isSelected
                                                            ? colorScheme
                                                                .onPrimaryContainer
                                                            : colorScheme
                                                                .onSurface,
                                                    fontWeight:
                                                        isSelected
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  Positioned _buildSticker(
    StickerItem sticker,
    bool isSelected,
    ({double width, double height}) environmentSize,
    DragonDecorationProvider provider,
  ) {
    ThemeData theme = Theme.of(context);
    final containerSize = Size(environmentSize.width, environmentSize.height);

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
                    containerSize: containerSize,
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
            if (isSelected) ...[
              // Resize handle (bottom-right)
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.open_with,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
              // Layer toggle button (top-left)
              Positioned(
                left: -8,
                top: -8,
                child: GestureDetector(
                  onTap: () {
                    provider.toggleStickerLayer(sticker.id);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      sticker.isBehindDragon
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
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

  void _showHintsDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.85;

    showDialog<void>(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: colorScheme.surface,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400, maxHeight: maxDialogHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tips',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildHintBullet(
                      'Tap an item to select it, then move and resize it.',
                    ),
                    _buildHintBullet(
                      'Use the arrow button to change layers (in front or behind your dragon).',
                    ),
                    _buildHintBullet(
                      'Long press an item on the habitat to remove it.',
                    ),
                    _buildHintBullet(
                      'Tap and hold an item in the tray, then drag it onto your dragon.',
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text('Got it!'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildHintBullet(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlacedItemsSheet(DragonDecorationProvider provider) {
    if (provider.placedStickers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No items placed yet. Drag items from the tray below.'),
        ),
      );
      return;
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select an item',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.placedStickers.length,
                  itemBuilder: (context, index) {
                    final sticker = provider.placedStickers[index];
                    final isSelected = provider.selectedStickerId == sticker.id;
                    return ListTile(
                      leading: Image.network(
                        sticker.imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) => Icon(Icons.image_not_supported),
                      ),
                      title: Text(sticker.name),
                      subtitle: Text(
                        sticker.isBehindDragon ? 'Behind dragon' : 'In front',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing:
                          isSelected
                              ? Icon(Icons.check, color: colorScheme.primary)
                              : null,
                      onTap: () {
                        provider.selectSticker(sticker.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleStickerDrop(
    DragTargetDetails details,
    double dragonSize,
    ({double height, double width}) environmentSize,
    DragonDecorationProvider provider,
  ) {
    final data = details.data;
    const stickerSize = 48.0;

    // Convert screen drop position to habitat-local coordinates
    Offset dropPosition = Offset.zero;
    final renderBox =
        _habitatKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final localOffset = renderBox.globalToLocal(details.offset);
      dropPosition = provider.calculateDropPosition(
        screenOffset: localOffset,
        dragonSize: Size(dragonSize, dragonSize),
        environmentSize: Size(environmentSize.width, environmentSize.height),
        screenSize: MediaQuery.of(context).size,
        dragonPosition: Offset.zero,
        stickerSize: stickerSize,
      );
    } else {
      // Fallback: center of habitat, constrained
      dropPosition = provider.calculateDropPosition(
        screenOffset: Offset(
          environmentSize.width / 2 - stickerSize / 2,
          environmentSize.height / 2 - stickerSize / 2,
        ),
        dragonSize: Size(dragonSize, dragonSize),
        environmentSize: Size(environmentSize.width, environmentSize.height),
        screenSize: MediaQuery.of(context).size,
        dragonPosition: Offset.zero,
        stickerSize: stickerSize,
      );
    }

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
    provider.addSticker(item: item, position: dropPosition, size: stickerSize);
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
