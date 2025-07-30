import 'package:flutter/material.dart';
import 'package:safe_scales/ui/widgets/toy_box_item_card.dart';
import 'package:safe_scales/services/user_state_service.dart';

import '../../services/dragon_service.dart';
import '../../services/quiz_service.dart';

class ToyBoxPage extends StatefulWidget {
  const ToyBoxPage({super.key});

  @override
  State<ToyBoxPage> createState() => _ToyBoxPageState();
}

class _ToyBoxPageState extends State<ToyBoxPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedTab = 0; // 0 = Accessories, 1 = Environments
  List<Map<String, dynamic>> userAccessories = [];
  List<Map<String, dynamic>> userEnvironments = [];
  bool isLoadingItems = true;
  bool isLoadingEnvironments = true;

  @override
  void initState() {
    super.initState();
    // _loadUserItems();
    _loadUserAccessories();
  }

  Future<void> _loadUserAccessories() async {
    try {
      setState(() => isLoadingItems = true);

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
            isLoadingItems = false;
          });
          // _onAccessoriesLoaded();
        } else {
          print('⚠️ No acquired accessories found');
          setState(() => isLoadingItems = false);
        }
      } else {
        print('⚠️ No user found');
        setState(() => isLoadingItems = false);
      }
    } catch (e) {
      print('❌ Error loading accessories: $e');
      setState(() => isLoadingItems = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color selected = primary;
    final Color unselected = Colors.blue[100]!;
    final Color selectedText = Colors.white;
    final Color unselectedText = primary;

    ThemeData theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'This is your current collection of\nitems and environments',
                style: theme.textTheme.labelMedium?.copyWith(
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              // Toggle Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedTab == 0 ? selected : unselected,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'ACCESSORIES',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: selectedTab == 0
                                  ? selectedText
                                  : unselectedText,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedTab == 1 ? selected : unselected,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'ENVIRONMENTS',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: selectedTab == 1
                                    ? selectedText
                                    : unselectedText,
                                letterSpacing: 1.1,
                              )
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Items Grid
              Expanded(
                child:
                    isLoadingItems
                        ? const Center(child: CircularProgressIndicator())
                        : selectedTab == 0
                        ? userAccessories.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 64,
                                    color: primary.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No accessories yet.\nVisit the shop to buy some!',
                                    style: theme.textTheme.labelLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                            : GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 24,
                              crossAxisSpacing: 24,
                              childAspectRatio: 0.95,
                              children: [
                                for (var accessory in userAccessories)
                                  ToyBoxItemCard(
                                    image:
                                        accessory['image_url'] ??
                                        accessory['imageUrl'] ??
                                        accessory['image'],
                                    name: accessory['name'],
                                    onTap: () {  },
                                  ),
                              ],
                            )
                        : userEnvironments.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.landscape_outlined,
                                size: 64,
                                color: primary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No environments yet.\nVisit the shop to buy some!',
                                style: theme.textTheme.labelLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                        : GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          childAspectRatio: 0.95,
                          children: [
                            for (var environment in userEnvironments)
                              ToyBoxItemCard(
                                image:
                                    environment['image_url'] ??
                                    environment['imageUrl'] ??
                                    environment['image'],
                                name: environment['name'],
                                onTap: () {  },
                              ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class _ToyBoxItemCard extends StatelessWidget {
//   final String? image;
//   final String name;
//
//   const _ToyBoxItemCard({this.image, required this.name});
//
//   @override
//   Widget build(BuildContext context) {
//
//     ThemeData theme = Theme.of(context);
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.black12, width: 1.2),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child:
//                 image != null
//                     ? Image.network(
//                       image!,
//                       width: 60,
//                       height: 60,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           width: 60,
//                           height: 60,
//                           color: Colors.grey[300],
//                           child: Icon(
//                             Icons.shopping_bag,
//                             size: 32,
//                             color: Colors.grey[600],
//                           ),
//                         );
//                       },
//                     )
//                     : Container(
//                       width: 60,
//                       height: 60,
//                       color: Colors.grey[300],
//                       child: Icon(
//                         Icons.shopping_bag,
//                         size: 32,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             name,
//             style: theme.textTheme.bodySmall,
//             textAlign: TextAlign.center,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
// }
