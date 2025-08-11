import 'package:flutter/material.dart';

class StickerCollectionWidget extends StatelessWidget {
  const StickerCollectionWidget({
    super.key,
    required bool isLoadingAccessories,
    required this.userAccessories,
  }) : _isLoadingAccessories = isLoadingAccessories;

  final bool _isLoadingAccessories;
  final List<Map<String, dynamic>> userAccessories;

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
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
            'Drag stickers onto your dragon',
            style: theme.textTheme.bodyMedium
          ),
          const SizedBox(height: 15),
          _isLoadingAccessories
              ? const Center(child: CircularProgressIndicator())
              : userAccessories.isEmpty
              ? Center(
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 48,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 15),
                Text(
                  'No stickers yet.\nVisit the shop to buy some!',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
              userAccessories.map((accessory) {
                return Draggable<Map<String, dynamic>>(
                  data: {
                    'image': accessory['image'],
                    'name': accessory['name'],
                  },
                  feedback: Material(
                    color: Colors.transparent,
                    child: Image.network(
                      accessory['image'],
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
                      accessory['image'],
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
                        color: colorScheme.primary.withValues(alpha: 0.3,),
                        width: 2,
                      ),
                    ),
                    child: Image.network(
                      accessory['image'],
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Long press a sticker to remove it',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 10),

        ],
      ),
    );
  }
}