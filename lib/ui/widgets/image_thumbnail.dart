import 'package:flutter/material.dart';

/// A widget that displays an image as a small thumbnail that can be expanded
/// when clicked. Similar to the ImageThumbnail component used in the instructor editor.
class ImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final String? altText;
  final double thumbnailSize;
  final BoxFit fit;

  const ImageThumbnail({
    super.key,
    required this.imageUrl,
    this.altText,
    this.thumbnailSize = 280,
    this.fit = BoxFit.contain,
  });

  void _showExpandedImage(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierColor: theme.colorScheme.shadow.withOpacity(0.87),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Expanded image with zoom/pan capability
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: theme.colorScheme.onSurface,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Image failed to load',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurface,
                    size: 32,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
                    padding: EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: GestureDetector(
        onTap: () => _showExpandedImage(context),
        child: Container(
          width: thumbnailSize,
          height: thumbnailSize,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.15),
                blurRadius: 8,
                offset: Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: thumbnailSize,
                height: thumbnailSize,
                alignment: Alignment.center,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: thumbnailSize,
                    height: thumbnailSize,
                    color: theme.colorScheme.surfaceVariant,
                    child: Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: thumbnailSize,
                    height: thumbnailSize,
                    color: theme.colorScheme.surfaceVariant,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 32,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Image failed to load',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
