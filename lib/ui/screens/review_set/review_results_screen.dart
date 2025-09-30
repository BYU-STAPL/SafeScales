import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/models/question.dart';

import '../../../models/sticker_item_model.dart';
import '../../../providers/shop_provider.dart';
import '../../../themes/app_theme.dart';
import '../../widgets/dragon_image_widget.dart';
import '../../widgets/shop_item_card.dart';

class ReviewResultsScreen extends StatefulWidget {
  String? image;
  final bool needToShowShop;

  ReviewResultsScreen({
    super.key, this.image, required this.needToShowShop,
  });

  @override
  _ReviewResultsScreen createState() => _ReviewResultsScreen();
}

class _ReviewResultsScreen extends State<ReviewResultsScreen> {

  bool isItemsTabSelected = true;
  int? selectedIndex; // Track selected item index

  @override
  Widget build(BuildContext context) {

    // Show shop if needed
    if (widget.needToShowShop) {
      return Consumer<ShopProvider>(
          builder: (context, shopProvider, child) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Quiz Complete'),
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
              body: _buildShopScreen(context, shopProvider),
            );
          });
    }
    else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz Complete'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: _buildRewardScreen(context),
      );
    }

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

  Widget _buildShop(BuildContext context, List<Item> items,) {

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
              isSelected: selectedIndex == i, // This must come after we set the value of selected index to null or i
            ),
        ],
      ),
    );
  }


  Widget _buildImageWidget(BuildContext context) {
    double size = 300;

    if (widget.image == null || widget.image == "") {
      return Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Text('No reward selected'),
              Icon(
                Icons.shopping_bag,
                size: 250,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          )
      );
    }

    Widget imageWidget = Image.asset(widget.image!, width: size, height: size);

    if (widget.image!.startsWith('http')) {
      imageWidget = Image.network(
        widget.image!,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/other/QuestionMark.png',
            width: size,
            height: size,
          );
        },
      );
    }

    return imageWidget;
  }


  Widget _buildShopScreen(BuildContext context, ShopProvider shopProvider) {

    ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 25),
        child: Column(
          children: [
            Text(
              'Great job completing the review!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 15),

            Text(
              'Pick a item or environment you\'d like to add to your collection',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),

            SizedBox(height: 15),

            _buildToggleButtons(context, shopProvider),

            SizedBox(height: 15),

            _buildShop(context, isItemsTabSelected ? shopProvider.availableItems: shopProvider.availableEnvironments),

            SizedBox(height: 15),

            // Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {

                  // Handle Purchasing the item

                  if (selectedIndex == null) {
                    Navigator.pop(context, true);
                    return; // include return to avoid popping twice, there's another pop statement after the if branch
                  }
                  else {
                    try {
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
                    }
                    catch (e) {
                      print('❌ Purchasing item from Review Results Screen failed: ${e}');
                    }
                  }

                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedIndex == null ? theme.colorScheme.primary : theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
                child: Text(
                    selectedIndex == null ? 'Skip'.toUpperCase() : 'Confirm Item'.toUpperCase(),
                  style: TextStyle(
                    fontSize: theme.textTheme.bodyMedium?.fontSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRewardScreen(BuildContext context) {

    ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 25),
        child: Column(
          children: [
            Text(
              'Great job completing the review!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 30),

            Text(
              'Here\'s your new item',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),

            SizedBox(height: 30),

            _buildImageWidget(context),

            SizedBox(height: 30),

            Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
                child: Text(
                  'Return'.toUpperCase(),
                  style: TextStyle(
                    fontSize: theme.textTheme.bodyMedium?.fontSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
