import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/providers/shop_provider.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/ui/screens/review_set/review_screen.dart';

import '../../models/lesson.dart';
import '../../models/sticker_item_model.dart';
import '../../providers/course_provider.dart';
import '../widgets/shop_item_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isItemsTabSelected = true;

  int? selectedIndex; // Track selected item index
  String? selectedLessonIndex; // Track selected lesson in popup

  bool showLessonDialog = false;
  bool isLoading = true;
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

    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    try {
      // Only initialize if not already initialized
      // Since AppDependencies already calls initialize(), we might not need this
      if (!shopProvider.isLoading) {
        await shopProvider.initialize();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  Future<void> _handlePurchase() async {
    if (selectedIndex == null) return;

    // Show completed modules popup first
    setState(() {
      showLessonDialog = true;
      selectedLessonIndex = null;
    });
  }

  Future<void> _completePurchase() async {
    if (selectedIndex == null || selectedLessonIndex == null) return;

    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    try {
      // Hide module selection dialog before starting the revision quiz
      setState(() {
        showLessonDialog = false;
      });

      // Start the revision quiz for the selected module
      final bool passedReviewSet = await _startReviewSet(
        selectedLessonIndex!,
      );

      if (!mounted) return;

      if (!passedReviewSet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 2),
            content: Text('Review set not completed. Purchase cancelled.'),
          ),
        );
        setState(() {
          selectedLessonIndex = null;
        });
        return;
      }

      // Proceed with the purchase using the provider
      final PurchaseResult result = await shopProvider.purchaseItemByIndex(
        selectedIndex!,
        !isItemsTabSelected,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );

        // Reset selected index since the item is no longer available
        setState(() {
          selectedIndex = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }

      setState(() {
        selectedLessonIndex = null;
      });
    } catch (e) {
      debugPrint('Error during purchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );

      setState(() {
        selectedLessonIndex = null;
      });
    }
  }

  Future<bool> _startReviewSet(String lessonId) async {
    try {
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);

      // Get the review question set for the lesson using the course provider/service
      final questionSet = await courseProvider.getReviewQuestionSetForLesson(lessonId);

      bool result = false;
      Item? selectedItem = shopProvider.getItemByIndex(selectedIndex!, !isItemsTabSelected);

      if (questionSet == null || questionSet.questions.isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 2),
            content: Text(
              'The Teacher has not created a review set for this lesson',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          ),
        );

        return false;

      } else {
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewScreen(
              questionSet: questionSet,
              image: selectedItem?.imageUrl,
              needToShowShop: false,
            ),
          ),
        );
      }

      // ReviewScreen returns true on completion
      return result == true;

    } catch (e) {
      debugPrint('Error starting review set: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load review set')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final Color primary = theme.colorScheme.primary;
    final Color selected = primary;
    final Color unselected = theme.colorScheme.lightBlue.withValues(alpha: 0.5,);
    final Color selectedText = Colors.white;
    final Color unselectedText = primary;
    final Color highlight = theme.colorScheme.green.withValues(alpha: 0.25);

    return Consumer2<ShopProvider, CourseProvider>(
      builder: (context, shopProvider, courseProvider, child) {

        final items = isItemsTabSelected ?  shopProvider.availableItems : shopProvider.availableEnvironments;

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
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          // Subtitle
                          Expanded(
                            child: Text(
                              'Earn new items and environments for your dragons by completing review sets from finished lessons.',
                              style: theme.textTheme.labelMedium,
                            ),
                          ),

                          // Refresh button
                          Consumer<ShopProvider>(
                            builder: (context, shopProvider, child) {
                              return IconButton(
                                onPressed: shopProvider.isLoading
                                    ? null
                                    : () => shopProvider.refresh(),
                                icon: shopProvider.isLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : const Icon(Icons.refresh),
                                tooltip: 'Refresh items',
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Toggle Buttons
                      _buildToggleButtons(context, shopProvider),

                      const SizedBox(height: 24),

                      // Shop Items Grid
                      _buildShop(items),

                      if (selectedIndex != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: _handlePurchase,
                              child: Text(
                                'PURCHASE'.toUpperCase(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
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
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
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
                              'Select a lesson to review',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontSize: 18 * AppTheme.fontSizeScale,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.5,
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                children:
                                  courseProvider.getAllCompletedLessons().map((lesson) {
                                    return _buildLessonCardForReview(lesson);
                                  }).toList(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed:
                                      () =>
                                      setState(() => showLessonDialog = false),
                                  child: Text(
                                    'CANCEL'.toUpperCase(),
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
                                    _completePurchase();
                                  }
                                      : null,
                                  child: Text('SELECT'.toUpperCase()),
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
      },
    );
  }

  Expanded _buildShop(List<Item> items,) {

    final Color highlight = Theme.of(context).colorScheme.green.withValues(alpha: 0.25);

    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.95,
        children: [
          for (int i = 0; i < items.length; i++)
            ShopItemCard(
              image: items[i].imageUrl,
              name: items[i].name,
              cost: items[i].cost.toString() ?? '1',
              highlight: highlight,
              onTap: () {
                setState(() {
                  selectedIndex = selectedIndex == i ? null : i;
                });
              },
              isSelected: selectedIndex == i,
            ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons(BuildContext context, ShopProvider shopProvider) {

    ThemeData theme = Theme.of(context);
    final Color selected = theme.colorScheme.primary;
    final Color unselected = theme.colorScheme.lightBlue.withValues(alpha: 0.5,);
    final Color selectedText = Colors.white;
    final Color unselectedText = theme.colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap:
                () => setState(() {
              isItemsTabSelected = true;
              selectedIndex = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isItemsTabSelected ? selected : unselected,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'ITEMS (${shopProvider.availableItems.length})'.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                    isItemsTabSelected ? selectedText : unselectedText,
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
              isItemsTabSelected = false;
              selectedIndex = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !isItemsTabSelected ? selected : unselected,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'ENVIRONMENTS (${shopProvider.availableEnvironments.length})'.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                    !isItemsTabSelected ? selectedText : unselectedText,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Row _buildToggleButtons(Color selected, Color unselected, ShopProvider shopProvider, ThemeData theme, Color selectedText, Color unselectedText) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: GestureDetector(
  //           onTap:
  //               () => setState(() {
  //             selectedTab = 0;
  //             selectedIndex = null;
  //           }),
  //           child: AnimatedContainer(
  //             duration: const Duration(milliseconds: 200),
  //             padding: const EdgeInsets.symmetric(vertical: 10),
  //             decoration: BoxDecoration(
  //               color: selectedTab == 0 ? selected : unselected,
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: Center(
  //               child: Text(
  //                 'ITEMS (${shopProvider.availableItems.length})'.toUpperCase(),
  //                 style: theme.textTheme.bodySmall?.copyWith(
  //                   color:
  //                   selectedTab == 0
  //                       ? selectedText
  //                       : unselectedText,
  //                   letterSpacing: 1.1,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: GestureDetector(
  //           onTap:
  //               () => setState(() {
  //             selectedTab = 1;
  //             selectedIndex = null;
  //           }),
  //           child: AnimatedContainer(
  //             duration: const Duration(milliseconds: 200),
  //             padding: const EdgeInsets.symmetric(vertical: 10),
  //             decoration: BoxDecoration(
  //               color: selectedTab == 1 ? selected : unselected,
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: Center(
  //               child: Text(
  //                 'ENVIRONMENTS (${shopProvider.availableEnvironments.length})'.toUpperCase(),
  //                 style: theme.textTheme.bodySmall?.copyWith(
  //                   color:
  //                   selectedTab == 1
  //                       ? selectedText
  //                       : unselectedText,
  //                   letterSpacing: 1.1,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  GestureDetector _buildLessonCardForReview(Lesson lesson) {

    ThemeData theme = Theme.of(context);
    Color selectionColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLessonIndex = lesson.lessonId;
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
              selectedLessonIndex == lesson.lessonId
                  ? selectionColor.withValues(
                    alpha: 0.12,
                  )
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                selectedLessonIndex == lesson.lessonId
                    ? selectionColor
                    : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              lesson.title,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

