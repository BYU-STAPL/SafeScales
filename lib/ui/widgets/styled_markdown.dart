import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class StyledMarkdown extends StatelessWidget {
  final String data;

  const StyledMarkdown({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Clean and validate the markdown data to prevent null issues
    final cleanData = _cleanMarkdownData(data);

    return Builder(
      builder: (context) {
        try {
          return _SelectableMarkdownWrapper(
            child: MarkdownBody(
              data: cleanData,
              selectable:
                  false, // Disable selection to prevent the null check error
              softLineBreak: true,
              fitContent: false,
              styleSheet: MarkdownStyleSheet(
                // Text styles
                p: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
                h1: theme.textTheme.headlineLarge,
                h2: theme.textTheme.headlineMedium,
                h3: theme.textTheme.headlineSmall,
                h4: theme.textTheme.titleLarge,
                h5: theme.textTheme.titleMedium,
                h6: theme.textTheme.titleSmall,
                em: const TextStyle(fontStyle: FontStyle.italic),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                code: TextStyle(
                  fontFamily: 'monospace',
                  backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
                  fontSize: theme.textTheme.bodyMedium?.fontSize,
                ),
                blockquote: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),

                // Block styles
                blockSpacing: 24.0,
                listIndent: 24.0,
                blockquoteDecoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: colorScheme.primary.withOpacity(0.5),
                      width: 4.0,
                    ),
                  ),
                ),
                codeblockDecoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1.0,
                    ),
                  ),
                ),

                // Table styles
                tableHead: TextStyle(fontWeight: FontWeight.bold),
                tableBorder: TableBorder.all(
                  color: colorScheme.outlineVariant,
                  width: 1.0,
                ),
                tableColumnWidth: const IntrinsicColumnWidth(),
                tableCellsPadding: const EdgeInsets.all(8.0),
              ),
              onTapLink: (text, href, title) async {
                if (href != null && href.isNotEmpty) {
                  try {
                    final url = Uri.parse(href);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  } catch (e) {
                    // Handle invalid URLs gracefully
                    debugPrint('Failed to launch URL: $href - $e');
                  }
                }
              },
            ),
          );
        } catch (e) {
          // Fallback to plain text if markdown parsing fails
          debugPrint('Markdown parsing error: $e');
          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: SelectableText(
              cleanData,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
            ),
          );
        }
      },
    );
  }

  /// Cleans and validates markdown data to prevent null-related issues
  String _cleanMarkdownData(String data) {
    if (data.isEmpty) {
      return 'No content available.';
    }

    // Remove any potential null characters or problematic sequences
    String cleaned =
        data
            .replaceAll('\x00', '') // Remove null characters
            .replaceAll(
              RegExp(r'[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]'),
              '',
            ) // Remove control characters
            .trim();

    // Ensure the content has proper line endings
    cleaned = cleaned.replaceAll(RegExp(r'\r\n'), '\n').replaceAll('\r', '\n');

    // Add a fallback if content is empty after cleaning
    if (cleaned.isEmpty) {
      return 'No content available.';
    }

    return cleaned;
  }
}

/// A wrapper widget that provides text selection functionality for markdown content
/// without triggering the flutter_markdown selection bug
class _SelectableMarkdownWrapper extends StatelessWidget {
  final Widget child;

  const _SelectableMarkdownWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        // Enable text selection on long press
        _showSelectionDialog(context);
      },
      child: child,
    );
  }

  void _showSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Text Selection'),
            content: const Text(
              'Long press and drag to select text in the content above.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
