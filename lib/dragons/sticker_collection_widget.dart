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

    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Drag accessories onto your dragon',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _isLoadingAccessories
              ? const Center(child: CircularProgressIndicator())
              : userAccessories.isEmpty
              ? Center(
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 48,
                  color: colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No accessories yet.\nVisit the shop to buy some!',
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
                      color: Colors.grey.withOpacity(0.3),
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
                        color: colorScheme.primary.withOpacity(
                          0.3,
                        ),
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
          const SizedBox(height: 18),
          Text(
            'Long press a sticker to remove it',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}