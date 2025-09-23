import 'package:flutter/material.dart';

import '../../models/sticker_item_model.dart';

class StickerCollectionWidget extends StatelessWidget {
  const StickerCollectionWidget({
    super.key,
    required bool isLoadingAccessories,
    required this.userAccessories,
  }) : _isLoadingAccessories = isLoadingAccessories;

  final bool _isLoadingAccessories;
  final List<Item> userAccessories;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Long press items to drag them onto your dragon',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          _isLoadingAccessories
              ? const Center(child: CircularProgressIndicator())
              : userAccessories.isEmpty
              ? Center(
            child: Column(
              children: [
                // Icon(
                //   Icons.shopping_bag_outlined,
                //   size: 48,
                //   color: colorScheme.primary.withValues(alpha: 0.5),
                // ),
                const SizedBox(height: 5),
                Text(
                  'No items yet.\nVisit the shop to earn some!',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
              ],
            ),
          )
              : SizedBox(
            height: 85, // Set a fixed height for the grid
            child: GridView.builder(
              scrollDirection: Axis.vertical,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // 4 items per row
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1, // Square items
              ),
              itemCount: userAccessories.length,
              itemBuilder: (context, index) {
                final item = userAccessories[index];
                return
                  LongPressDraggable<Map<String, dynamic>>(
                    data: {
                      'id': item.id,
                      'image': item.imageUrl,
                      'name': item.name,
                    },
                    feedback: Material(
                      color: Colors.transparent,
                      child: Image.network(
                        item.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                    childWhenDragging: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.network(
                        item.imageUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Image.network(
                        item.imageUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
              },
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}