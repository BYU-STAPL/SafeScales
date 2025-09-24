import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/providers/course_provider.dart';
import 'package:safe_scales/ui/widgets/dragon_id_card.dart';
import '../../providers/dragon_decoration_provider.dart';
import '../../providers/dragon_provider.dart';
import '../widgets/dragon_image_widget.dart';
import 'dragon_decoration/dragon_decoration_screen.dart';

class DragonsScreen extends StatefulWidget {
  const DragonsScreen({super.key});

  @override
  State<DragonsScreen> createState() => _DragonsScreenState();
}

class _DragonsScreenState extends State<DragonsScreen> {

  @override
  void initState() {
    super.initState();
  }

  // Refresh method
  Future<void> _refreshDragons() async {
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
        builder: (context) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<DragonDecorationProvider>(
                create: (_) => DragonDecorationProvider(),
              ),
              // DragonProvider is already above, no need to redeclare
            ],
            child: DragonDressUpPage(
              dragonId: dragonId,
              currentPhase: dragonProvider.getUserPreferredPhase(dragonId),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color cardBg = theme.colorScheme.surface;

    return Consumer2<DragonProvider, CourseProvider>(
        builder: (context, dragonProvider, courseProvider, child) {
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
                      horizontal: 25.0,
                      vertical: 10.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Subtitle
                        Text(
                          'These are your dragons from this course. Complete their associated lessons to play with them.',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 5),

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

                        SizedBox(height: 10,)
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

      final isUnlocked = dragonProvider.isPlayUnlocked(dragon.id);

      // TODO: Eventually use preferred phase for setting up the id card image
      Widget dragonImageWidget = DragonImageWidget(dragonId: dragon.id, size: 180);

      return DragonIdCard(
        dragonId: dragon.id,
        dragonImage: dragonImageWidget,
        species: dragon.speciesName,
        name: dragon.name,
        favoriteItem: dragon.favoriteItem,
        favoriteEnvironment: dragon.preferredEnvironment,
        isPlayUnlocked: isUnlocked,
        onTapPlayButton: () {
          navigateToDressUp(dragon.id);
        },
      );
    }).toList();
  }
}