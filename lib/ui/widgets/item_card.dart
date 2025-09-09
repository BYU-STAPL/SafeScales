import 'package:flutter/material.dart';
import 'package:safe_scales/extensions/string_extensions.dart';

import '../../themes/app_theme.dart';

class ItemCard extends StatelessWidget {
  final String? image;
  final String name;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    this.image,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                      width: 75 * AppTheme.fontSizeScale,
                      height: 75 * AppTheme.fontSizeScale,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60 * AppTheme.fontSizeScale,
                          height: 60 * AppTheme.fontSizeScale,
                          color: theme.colorScheme.surface,
                          child: Icon(
                            Icons.shopping_bag,
                            size: 32 * AppTheme.fontSizeScale,
                            color: theme.colorScheme.onSurface,
                          ),
                        );
                      },
                    )
                        : Container(
                      width: 60 * AppTheme.fontSizeScale,
                      height: 60 * AppTheme.fontSizeScale,
                      color: theme.colorScheme.surface,
                      child: Icon(
                        Icons.shopping_bag,
                        size: 32 * AppTheme.fontSizeScale,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                name.toTitleCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 15 * AppTheme.fontSizeScale,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}