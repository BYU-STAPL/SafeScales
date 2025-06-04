import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/settings_drawer.dart';
import 'package:safe_scales/services/shop_service.dart';
import 'package:safe_scales/services/user_state_service.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ShopService _shopService = ShopService();
  final UserStateService _userState = UserStateService();
  int selectedTab = 0; // 0 = Accessories, 1 = Environments
  int? selectedIndex; // Track selected item index
  int? selectedLessonIndex; // Track selected lesson in popup
  bool showLessonDialog = false;
  List<Map<String, dynamic>> accessories = [];
  List<Map<String, dynamic>> environments = [];
  bool isLoading = true;
  List<int> acquiredAccessories = [];
  List<String> acquiredEnvironments = [];

  // Placeholder completed lessons
  final List<String> completedLessons = [
    'Lesson 1: Internet Safety',
    'Lesson 2: Social Media Norms',
    'Lesson 3: Passwords',
    'Lesson 4: Digital Footprint',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final accessoriesData = await _shopService.getAccessories();
      final environmentsData = await _shopService.getEnvironments();

      // Load user's acquired items
      final userId = _userState.currentUser?.id;
      if (userId != null) {
        acquiredAccessories = await _shopService.getUserAcquiredAccessories(
          userId,
        );
        acquiredEnvironments = await _shopService.getUserAcquiredEnvironments(
          userId,
        );
      }

      setState(() {
        accessories = accessoriesData;
        environments = environmentsData;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading shop items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handlePurchase() async {
    if (selectedIndex == null) return;

    final userId = _userState.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to purchase items')),
      );
      return;
    }

    if (selectedTab == 0) {
      // Handle accessory purchase
      final accessoryId = accessories[selectedIndex!]['id'] as int;

      // Check if user already owns this accessory
      if (acquiredAccessories.contains(accessoryId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already own this item')),
        );
        return;
      }

      final success = await _shopService.purchaseAccessory(userId, accessoryId);

      if (success) {
        setState(() {
          acquiredAccessories.add(accessoryId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item purchased successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to purchase item')),
        );
      }
    } else {
      // Handle environment purchase
      final environmentId = environments[selectedIndex!]['id'] as String;

      // Check if user already owns this environment
      if (acquiredEnvironments.contains(environmentId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already own this environment')),
        );
        return;
      }

      final success = await _shopService.purchaseEnvironment(
        userId,
        environmentId,
      );

      if (success) {
        setState(() {
          acquiredEnvironments.add(environmentId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Environment purchased successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to purchase environment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color selected = primary;
    final Color unselected = Colors.blue[100]!;
    final Color selectedText = Colors.white;
    final Color unselectedText = primary;
    final Color highlight = Colors.green[300]!;

    final items = selectedTab == 0 ? accessories : environments;

    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    'Buy new accessories and environments for your dragons! Earn coins by playing and reviewing.',
                    style: GoogleFonts.poppins(
                      fontSize: 16 * AppTheme.fontSizeScale,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Toggle Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => setState(() {
                                selectedTab = 0;
                                selectedIndex = null;
                              }),
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
                                style: GoogleFonts.poppins(
                                  fontSize: 15 * AppTheme.fontSizeScale,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      selectedTab == 0
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
                          onTap:
                              () => setState(() {
                                selectedTab = 1;
                                selectedIndex = null;
                              }),
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
                                style: GoogleFonts.poppins(
                                  fontSize: 15 * AppTheme.fontSizeScale,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      selectedTab == 1
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
                  // Shop Items Grid
                  Expanded(
                    child:
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 24,
                              crossAxisSpacing: 24,
                              childAspectRatio: 0.95,
                              children: [
                                for (int i = 0; i < items.length; i++)
                                  _ShopItemCard(
                                    image:
                                        items[i]['image_url'] ??
                                        items[i]['image'],
                                    name: items[i]['name'],
                                    cost: items[i]['cost']?.toString() ?? '0',
                                    isSelected: selectedIndex == i,
                                    isOwned:
                                        selectedTab == 0
                                            ? acquiredAccessories.contains(
                                              items[i]['id'],
                                            )
                                            : acquiredEnvironments.contains(
                                              items[i]['id'],
                                            ),
                                    highlight: highlight,
                                    onTap: () {
                                      setState(() {
                                        selectedIndex = i;
                                      });
                                    },
                                  ),
                              ],
                            ),
                  ),
                  if (selectedIndex != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: _handlePurchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 14,
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 16 * AppTheme.fontSizeScale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('PURCHASE'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showLessonDialog)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => showLessonDialog = false),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a completed lesson',
                          style: GoogleFonts.poppins(
                            fontSize: 18 * AppTheme.fontSizeScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...List.generate(completedLessons.length, (idx) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLessonIndex = idx;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    selectedLessonIndex == idx
                                        ? primary.withOpacity(0.12)
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      selectedLessonIndex == idx
                                          ? primary
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                completedLessons[idx],
                                style: GoogleFonts.poppins(
                                  fontSize: 15 * AppTheme.fontSizeScale,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed:
                                  () =>
                                      setState(() => showLessonDialog = false),
                              child: Text(
                                'CANCEL',
                                style: TextStyle(
                                  fontSize: 14 * AppTheme.fontSizeScale,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed:
                                  selectedLessonIndex != null
                                      ? () {
                                        // TODO: Handle lesson selection logic
                                        setState(
                                          () => showLessonDialog = false,
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Selected: ${completedLessons[selectedLessonIndex!]}',
                                            ),
                                          ),
                                        );
                                      }
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 14 * AppTheme.fontSizeScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('SELECT'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final String? image;
  final String name;
  final String cost;
  final bool isSelected;
  final bool isOwned;
  final Color highlight;
  final VoidCallback onTap;

  const _ShopItemCard({
    this.image,
    required this.name,
    required this.cost,
    required this.isSelected,
    required this.isOwned,
    required this.highlight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? highlight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOwned ? Colors.green : Colors.black12,
              width: isOwned ? 2 : 1.2,
            ),
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
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                        image != null
                            ? Image.network(
                              image!,
                              width: 60 * AppTheme.fontSizeScale,
                              height: 60 * AppTheme.fontSizeScale,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60 * AppTheme.fontSizeScale,
                                  height: 60 * AppTheme.fontSizeScale,
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.shopping_bag,
                                    size: 32 * AppTheme.fontSizeScale,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            )
                            : Container(
                              width: 60 * AppTheme.fontSizeScale,
                              height: 60 * AppTheme.fontSizeScale,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.shopping_bag,
                                size: 32 * AppTheme.fontSizeScale,
                                color: Colors.grey[600],
                              ),
                            ),
                  ),
                  if (isOwned)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 16 * AppTheme.fontSizeScale,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 15 * AppTheme.fontSizeScale,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                isOwned ? 'OWNED' : '$cost coins',
                style: GoogleFonts.poppins(
                  fontSize: 13 * AppTheme.fontSizeScale,
                  color: isOwned ? Colors.green : Colors.grey[600],
                  fontWeight: isOwned ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
