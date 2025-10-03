import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/ui/widgets/item_card.dart';
import 'package:safe_scales/providers/item_provider.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedTab = 0; // 0 = Accessories, 1 = Environments

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure initialization happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    try {
      // Only initialize if not already initialized
      // Since AppDependencies already calls initialize(), we might not need this
      if (!itemProvider.isLoading) {
        await itemProvider.initialize();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Initialization error: $e');
    }

    await itemProvider.loadUserItems();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color selected = primary;
    final Color unselected = Colors.blue[100]!;
    final Color selectedText = Colors.white;
    final Color unselectedText = primary;

    ThemeData theme = Theme.of(context);

    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        // Move the items logic inside the consumer so it rebuilds when provider changes
        final items = selectedTab == 0
            ? itemProvider.items
            : itemProvider.environments;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'This is your current collection of\nitems and environments',
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      // Refresh button
                      IconButton(
                        onPressed: itemProvider.isLoading
                            ? null
                            : () => itemProvider.refresh(),
                        icon: itemProvider.isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.refresh),
                        tooltip: 'Refresh items',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                                'ITEMS (${itemProvider.items.length})',
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
                                'ENVIRONMENTS (${itemProvider.environments.length})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: selectedTab == 1
                                      ? selectedText
                                      : unselectedText,
                                  letterSpacing: 1.1,
                                ),
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
                    child: _buildItemsGrid(context, items, itemProvider),
                  ),

                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsGrid(BuildContext context, List items, ItemProvider itemProvider) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final ThemeData theme = Theme.of(context);

    // Handle error state
    if (itemProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading items',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              itemProvider.error!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => itemProvider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Handle empty state
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selectedTab == 0
                  ? Icons.shopping_bag_outlined
                  : Icons.landscape_outlined,
              size: 64,
              color: primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              selectedTab == 0 ? 'No accessories yet' : 'No environments yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              selectedTab == 0
                  ? 'Complete reviews set from the shop page to earn items and environments'
                  : 'Complete lessons and quizzes to\nunlock beautiful environments!',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (selectedTab == 1)
              ElevatedButton(
                onPressed: () {
                  // Navigate to lessons or shop
                  // Navigator.pushNamed(context, '/lessons');
                },
                child: const Text('Start Learning'),
              ),
          ],
        ),
      );
    }

    // Show items grid
    return RefreshIndicator(
      onRefresh: itemProvider.refresh,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 0.95,
        children: [
          for (var item in items)
            ItemCard(
              image: item.imageUrl,
              name: item.name,
              onTap: () {
                // Handle item tap
                _showItemDetails(context, item, selectedTab == 0 ? 'accessory' : 'environment');
              },
            ),
        ],
      ),
    );
  }

  /// Show item details in a bottom sheet or dialog
  void _showItemDetails(BuildContext context, dynamic item, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        width: double.infinity, // Add this - simpler alternative
        padding: const EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface, //Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Item image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl,
                width: 300,
                height: 300,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            // Item name
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Item type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                type.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // TODO: Actions button Not needed right now, maybe later?
            // Action buttons
            // Row(
            //   children: [
            //     Expanded(
            //       child: OutlinedButton(
            //         onPressed: () => Navigator.pop(context),
            //         child: const Text('Close'),
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: ElevatedButton(
            //         onPressed: () {
            //           // Handle equip/use action
            //           Navigator.pop(context);
            //           ScaffoldMessenger.of(context).showSnackBar(
            //             SnackBar(content: Text('${item.name} equipped!')),
            //           );
            //         },
            //         child: Text(type == 'accessory' ? 'Equip' : 'Set Active'),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}