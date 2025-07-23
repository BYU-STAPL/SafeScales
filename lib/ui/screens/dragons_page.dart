import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/ui/widgets/dragon_id_card.dart';
import '../../models/dragon.dart';
import '../../state_management/dragon_provider.dart';
import '../widgets/dragon_image_widget.dart';
import 'dragon_decoration/dragon_decoration_screen.dart';

class DragonsPage extends StatefulWidget {
  const DragonsPage({super.key});

  @override
  State<DragonsPage> createState() => _DragonsPageState();
}

class _DragonsPageState extends State<DragonsPage> {
  // late final DragonStateManager _dragonStateManager;

  @override
  void initState() {
    super.initState();
    // _dragonStateManager = DragonStateManager();

    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
    dragonProvider.loadUserDragons();

    // _loadDragons();
  }

  // Future<void> _loadDragons() async {
  //   // await _dragonStateManager.initialize();
  //   // await _dragonStateManager.loadUserDragons();
  //   final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
  //   dragonProvider.loadUserDragons();
  //   setState(() {});
  // }

  // Refresh method
  Future<void> _refreshDragons() async {
    // await _dragonStateManager.loadUserDragons();
    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
    dragonProvider.loadUserDragons();
    setState(() {});
  }

  // Navigation to dress up page
  void navigateToDressUp(String dragonId) {
    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
    dragonProvider.loadUserDragons();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DragonDressUpPage(
          dragonId: dragonId,
          currentPhase: dragonProvider.getUserPreferredPhase(dragonId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color cardBg = theme.colorScheme.surface;

    return Consumer<DragonProvider>(
        builder: (context, dragonProvider, child) {
          return Scaffold(
            backgroundColor: cardBg,
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refreshDragons,
                child: dragonProvider.isLoading
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
                        if (dragonProvider.dragons.isEmpty)
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
    );

  }

  List<Widget> _buildDragonCards() {

    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);

    final dragons = dragonProvider.getAllDragons();

    return dragons.map((dragon) {

      if (dragon == null) return const SizedBox.shrink();

      // Is dragon unlocked for play
      final isUnlocked = dragonProvider.isPlayUnlocked(dragon.id);


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