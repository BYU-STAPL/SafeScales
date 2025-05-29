import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/settings_drawer.dart';

class MyDragonsPage extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;

  const MyDragonsPage({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.fontSize,
    required this.onFontSizeChanged,
  });

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

    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: SettingsDrawer(
        fontSize: fontSize,
        onFontSizeChanged: onFontSizeChanged,
        isDarkMode: isDarkMode,
        onDarkModeChanged: onDarkModeChanged,
        username: 'username',
        email: 'your-email@email.com',
        onTutorial: () {},
        onHelp: () {},
        onLogout: () {},
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Dragons',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.menu, color: primary, size: 28),
                          onPressed: () {
                            _scaffoldKey.currentState?.openEndDrawer();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Dragon Card (Unlocked)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 28),
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: cardShadow,
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Egg image placeholder with gradient border
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primary.withOpacity(0.25),
                                  Colors.green.withOpacity(0.18),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primary.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.egg,
                                size: 48,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Name',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Fitzwilliam',
                                              style: GoogleFonts.poppins(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.edit,
                                            size: 16,
                                            color: primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Species',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Bokaris',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Divider(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        thickness: 1,
                        height: 1,
                      ),
                      const SizedBox(height: 18),
                      _DragonInfoRow(label: 'Length', value: '2 feet'),
                      _DragonInfoRow(label: 'Weight', value: '25 pounds'),
                      _DragonInfoRow(
                        label: 'Preferred Environment',
                        value: 'Waterfalls',
                      ),
                      _DragonInfoRow(
                        label: 'Favorite Item',
                        value: 'Ice Cream',
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DragonDressUpPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('PLAY'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Dragon Card (Locked)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 28),
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: lockedBg,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(color: Colors.grey[300]!, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Lock image placeholder
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.lock,
                                size: 48,
                                color: Colors.blueGrey[300],
                              ),
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Name',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '__________________',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Species',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withOpacity(0.7),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '__________________',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Divider(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        thickness: 1,
                        height: 1,
                      ),
                      const SizedBox(height: 18),
                      _DragonInfoRow(
                        label: 'Length',
                        value: '______',
                        valueColor: Colors.black26,
                      ),
                      _DragonInfoRow(
                        label: 'Weight',
                        value: '______',
                        valueColor: Colors.black26,
                      ),
                      _DragonInfoRow(
                        label: 'Preferred Environment',
                        value: '______________',
                        valueColor: Colors.black26,
                      ),
                      _DragonInfoRow(
                        label: 'Favorite Item',
                        value: '____________________',
                        valueColor: Colors.black26,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DragonInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DragonInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Dragon Dress Up Page ---
class DragonDressUpPage extends StatefulWidget {
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

  final List<String> dragonPhases = ['Egg', 'Baby', 'Adult'];
  final List<String> environments = ['Forest', 'Mountain', 'Beach'];

  void _showPhaseDialog() async {
    int? choice = await showDialog<int>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Select Dragon Phase'),
            children: List.generate(
              dragonPhases.length,
              (i) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, i),
                child: Text(dragonPhases[i]),
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
                  'Phase: ${dragonPhases[selectedPhase]}',
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
                                  'https://raw.githubusercontent.com/itsnporg/pixel-art-dragons/main/green-dragon.png',
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
      backgroundColor: colorScheme.background,
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
