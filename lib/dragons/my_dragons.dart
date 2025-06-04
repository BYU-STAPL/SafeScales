import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/settings_drawer.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/dragon_service.dart';
import 'package:safe_scales/services/quiz_service.dart';

class MyDragonsPage extends StatefulWidget {
  const MyDragonsPage({super.key});

  @override
  State<MyDragonsPage> createState() => _MyDragonsPageState();
}

class _MyDragonsPageState extends State<MyDragonsPage> {
  final _userState = UserStateService();
  late final DragonService _dragonService;
  Map<String, List<String>> _userDragons = {};
  Map<String, Map<String, dynamic>> _dragonDetails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dragonService = DragonService(QuizService().supabase);
    _loadUserDragons();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color cardBg = Theme.of(context).colorScheme.surface;
    final Color cardShadow = Theme.of(
      context,
    ).colorScheme.shadow.withOpacity(0.07);
    final Color lockedBg = Theme.of(context).colorScheme.surfaceDim;
    final double borderRadius = 28.0;
    final double cardPadding = 24.0;

    return Scaffold(
      backgroundColor: cardBg,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page title
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'My Dragons',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_userDragons.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.egg_outlined,
                                    size: 64,
                                    color: primary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No dragons yet.\nComplete topics to unlock dragons!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
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

                            if (phases.contains('final')) {
                              currentPhase = 'final';
                              imageUrl = dragonData['final_stage_image'];
                            } else if (phases.contains('stage2')) {
                              currentPhase = 'stage2';
                              imageUrl = dragonData['stage2_image'];
                            } else if (phases.contains('stage1')) {
                              currentPhase = 'stage1';
                              imageUrl = dragonData['stage1_image'];
                            }

                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 28),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Dragon image section
                                  Stack(
                                    children: [
                                      // Main image container
                                      Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                          gradient: LinearGradient(
                                            colors: [
                                              primary.withOpacity(0.1),
                                              primary.withOpacity(0.05),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                        child: Center(
                                          child:
                                              imageUrl.startsWith('http')
                                                  ? Image.network(
                                                    imageUrl,
                                                    height: 180,
                                                    fit: BoxFit.contain,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Icon(
                                                          Icons.pets,
                                                          size: 80,
                                                          color: primary,
                                                        ),
                                                  )
                                                  : Image.asset(
                                                    imageUrl,
                                                    height: 180,
                                                    fit: BoxFit.contain,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Icon(
                                                          Icons.pets,
                                                          size: 80,
                                                          color: primary,
                                                        ),
                                                  ),
                                        ),
                                      ),
                                      // Phase badge
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primary,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getPhaseIcon(currentPhase),
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                currentPhase.toUpperCase(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Content section
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Stats in a single row
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildStatItem(
                                                context,
                                                'Length',
                                                '${dragonData['length']} ft',
                                                Icons.straighten,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildStatItem(
                                                context,
                                                'Weight',
                                                '${dragonData['weight']} lbs',
                                                Icons.monitor_weight,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildStatItem(
                                                context,
                                                'Environment',
                                                dragonData['preferred_environment'] ??
                                                    'Unknown',
                                                Icons.landscape,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Play button
                                        ElevatedButton(
                                          onPressed: () {
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
                                                        ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primary,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            textStyle: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.play_arrow_rounded,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text('PLAY WITH DRAGON'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
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
        return Icons.pets;
      case 'stage2':
        return Icons.auto_awesome;
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
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
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
          _userDragons = dragonsMap.map((key, value) {
            // Convert the phases list from List<dynamic> to List<String>
            final phases =
                (value as List<dynamic>)
                    .map((phase) => phase.toString())
                    .toList();
            return MapEntry(key, phases);
          });

          // Load details for each dragon
          for (var dragonId in _userDragons.keys) {
            final dragonData =
                await _dragonService.supabase
                    .from('dragons')
                    .select()
                    .eq('id', dragonId)
                    .single();

            _dragonDetails[dragonId] = dragonData;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('✗ Error loading user dragons: $e');
      setState(() => _isLoading = false);
    }
  }
}

// --- Dragon Dress Up Page ---
class DragonDressUpPage extends StatefulWidget {
  final String dragonId;
  final Map<String, dynamic> dragonData;
  final List<String> phases;

  const DragonDressUpPage({
    Key? key,
    required this.dragonId,
    required this.dragonData,
    required this.phases,
  }) : super(key: key);

  @override
  _DragonDressUpPageState createState() => _DragonDressUpPageState();
}

class _DragonDressUpPageState extends State<DragonDressUpPage> {
  int selectedPhase = 0;
  int selectedEnvironment = 0;

  // List to store placed stickers with their positions
  List<StickerItem> placedStickers = [];

  final List<IconData> accessories = [
    Icons.emoji_emotions, // Hat
    Icons.visibility, // Glasses
    Icons.icecream, // Ice Cream
    Icons.star, // Star
    Icons.cake, // Cake
    Icons.sports_soccer, // Ball
  ];

  final List<Color> accessoryColors = [
    Colors.amber, // Hat
    Colors.blueAccent, // Glasses
    Colors.pinkAccent, // Ice Cream
    Colors.deepPurple, // Star
    Colors.brown, // Cake
    Colors.green, // Ball
  ];

  final List<String> environments = ['Forest', 'Mountain', 'Beach'];

  // Get available phases based on the dragon data
  List<String> get availablePhases {
    List<String> phases = ['egg'];
    if (widget.phases.contains('stage1')) phases.add('stage1');
    if (widget.phases.contains('stage2')) phases.add('stage2');
    if (widget.phases.contains('final')) phases.add('final');
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
    if (choice != null) setState(() => selectedPhase = choice);
  }

  void _showEnvironmentDialog() async {
    int? choice = await showDialog<int>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Select Environment'),
            children: List.generate(
              environments.length,
              (i) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, i),
                child: Text(environments[i]),
              ),
            ),
          ),
    );
    if (choice != null) setState(() => selectedEnvironment = choice);
  }

  void _removeSticker(String id) {
    setState(() {
      placedStickers.removeWhere((sticker) => sticker.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  'Environment: ${environments[selectedEnvironment]}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.secondary,
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
                                  : colorScheme.surfaceVariant,
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
                                return Positioned(
                                  left: sticker.position.dx,
                                  top: sticker.position.dy,
                                  child: GestureDetector(
                                    onLongPress:
                                        () => _removeSticker(sticker.id),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        sticker.icon,
                                        size: 48,
                                        color: sticker.color,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 8,
                                            color: Colors.black26,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
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
                        placedStickers.add(
                          StickerItem(
                            id:
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            icon: data['icon'],
                            color: data['color'],
                            position: Offset(clampedX, clampedY),
                          ),
                        );
                      });
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(accessories.length, (index) {
                    return Draggable<Map<String, dynamic>>(
                      data: {
                        'icon': accessories[index],
                        'color': accessoryColors[index],
                      },
                      feedback: Material(
                        color: Colors.transparent,
                        child: Icon(
                          accessories[index],
                          size: 48,
                          color: accessoryColors[index].withOpacity(0.8),
                          shadows: [
                            Shadow(
                              blurRadius: 12,
                              color: Colors.black38,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                      ),
                      childWhenDragging: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          accessories[index],
                          size: 36,
                          color: Colors.grey,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accessoryColors[index].withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          accessories[index],
                          size: 36,
                          color: accessoryColors[index],
                        ),
                      ),
                    );
                  }),
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
  final IconData icon;
  final Color color;
  final Offset position;

  StickerItem({
    required this.id,
    required this.icon,
    required this.color,
    required this.position,
  });
}
