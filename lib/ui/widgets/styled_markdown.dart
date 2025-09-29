import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../themes/markdown_theme.dart';

class StyledMarkdown extends StatelessWidget {
  final String data;

  const StyledMarkdown({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MarkdownBody(
      data: data,
      selectable: true,
      softLineBreak: true,
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
            top: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
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
        if (href != null) {
          final url = Uri.parse(href);
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        }
      },
    );
  }
}
