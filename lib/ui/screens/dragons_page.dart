import 'package:flutter/material.dart';
import 'package:safe_scales/ui/widgets/dragon_id_card.dart';
import 'package:safe_scales/states/dragon_state_manager.dart';
import '../../models/dragon.dart';
import '../widgets/dragon_image_widget.dart';
import 'dragon_decoration/dragon_decoration_screen.dart';

class DragonsPage extends StatefulWidget {
  const DragonsPage({super.key});

  @override
  State<DragonsPage> createState() => _DragonsPageState();
}

class _DragonsPageState extends State<DragonsPage> {
  late final DragonStateManager _dragonStateManager;

  @override
  void initState() {
    super.initState();
    _dragonStateManager = DragonStateManager();
    _loadDragons();
  }

  Future<void> _loadDragons() async {
    await _dragonStateManager.initialize();
    await _dragonStateManager.loadUserDragons();
    setState(() {});
  }

  // Refresh method
  Future<void> _refreshDragons() async {
    await _dragonStateManager.loadUserDragons();
    setState(() {});
  }

  // Navigation to dress up page
  void navigateToDressUp(String dragonId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DragonDressUpPage(
          dragonId: dragonId,
          onEnvironmentChanged: _dragonStateManager.saveEnvironmentSelection,
          onDragonUpdated: (_) => _refreshDragons(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color cardBg = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: cardBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDragons,
          child: _dragonStateManager.isLoading
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
                  if (_dragonStateManager.userDragons.isEmpty)
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
                    ..._buildDragonCards(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDragonCards() {
    // final dragons = _dragonStateManager.getAllDragonsForDisplay();

    final dragons = _dragonStateManager.getAllDragons();

    return dragons.map((dragon) {

      if (dragon == null) return const SizedBox.shrink();

      // Is dragon unlocked for play
      final isUnlocked = _dragonStateManager.isPlayUnlocked(dragon.id);


      // TODO: Eventually use preferred phase for setting up the id card image
      Widget dragonImageWidget = DragonImageWidget(dragonId: dragon.id, size: 180);

      return DragonIdCard(
        dragonImage: dragonImageWidget,
        species: dragon.speciesName,
        name: 'Jack',
        favoriteItem: dragon.favoriteItem,
        favoriteEnvironment: dragon.preferredEnvironment,
        isPlayUnlocked: isUnlocked,
        onTapPlayButton: () {
          navigateToDressUp(dragon.id);
        },
        // TODO: Add backend to change dragon name
        // onNameChanged: (newName) {
        //   setState(() {
        //     dragonName = newName;
        //   });
        // },
      );
    }).toList();
  }
}