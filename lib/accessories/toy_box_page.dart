import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/settings_drawer.dart';
import 'package:safe_scales/services/shop_service.dart';
import 'package:safe_scales/services/user_state_service.dart';

class ToyBoxPage extends StatefulWidget {
  const ToyBoxPage({super.key});

  @override
  State<ToyBoxPage> createState() => _ToyBoxPageState();
}

class _ToyBoxPageState extends State<ToyBoxPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ShopService _shopService = ShopService();
  final UserStateService _userState = UserStateService();
  int selectedTab = 0; // 0 = Accessories, 1 = Environments
  List<Map<String, dynamic>> userAccessories = [];
  List<Map<String, dynamic>> userEnvironments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserItems();
  }

  Future<void> _loadUserItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = _userState.currentUser?.id;
      if (userId != null) {
        // Get user's acquired items
        final acquiredAccessories = await _shopService
            .getUserAcquiredAccessories(userId);
        final acquiredEnvironments = await _shopService
            .getUserAcquiredEnvironments(userId);

        // Get details for each acquired item
        final accessories = await _shopService.getAccessories();
        final environments = await _shopService.getEnvironments();

        userAccessories =
            accessories
                .where(
                  (accessory) =>
                      acquiredAccessories.contains(accessory['id'].toString()),
                )
                .toList();
        userEnvironments =
            environments
                .where(
                  (environment) => acquiredEnvironments.contains(
                    environment['id'].toString(),
                  ),
                )
                .toList();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading user items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Colors.blue[100]!;
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
                    isLoading
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
                                    color: primary.withOpacity(0.5),
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
                                  _ToyBoxItemCard(
                                    image:
                                        accessory['image_url'] ??
                                        accessory['imageUrl'] ??
                                        accessory['image'],
                                    name: accessory['name'],
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
                                color: primary.withOpacity(0.5),
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
                              _ToyBoxItemCard(
                                image:
                                    environment['image_url'] ??
                                    environment['imageUrl'] ??
                                    environment['image'],
                                name: environment['name'],
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

class _ToyBoxItemCard extends StatelessWidget {
  final String? image;
  final String name;

  const _ToyBoxItemCard({this.image, required this.name});

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child:
                image != null
                    ? Image.network(
                      image!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.shopping_bag,
                            size: 32,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    )
                    : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.shopping_bag,
                        size: 32,
                        color: Colors.grey[600],
                      ),
                    ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
