import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Creates a MarkdownStyleSheet that matches our app theme
MarkdownStyleSheet createMarkdownTheme(ThemeData theme) {
  final colorScheme = theme.colorScheme;

  return MarkdownStyleSheet(
    // Text styles
    p: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
    h1: theme.textTheme.headlineLarge?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.bold,
    ),
    h2: theme.textTheme.headlineMedium?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.bold,
    ),
    h3: theme.textTheme.headlineSmall?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.bold,
    ),
    h4: theme.textTheme.titleLarge?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.bold,
    ),
    h5: theme.textTheme.titleMedium?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.bold,
    ),
    h6: theme.textTheme.titleSmall?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.bold,
    ),
    em: TextStyle(fontStyle: FontStyle.italic, color: colorScheme.onSurface),
    strong: TextStyle(
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    ),
    code: TextStyle(
      fontFamily: 'monospace',
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
      fontSize: theme.textTheme.bodyMedium?.fontSize,
      color: colorScheme.primary,
    ),
    blockquote: theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontStyle: FontStyle.italic,
    ),

    // Block styles
    blockSpacing: 24.0,
    listIndent: 24.0,
    listBullet: theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.primary,
    ),
    listBulletPadding: const EdgeInsets.only(right: 8),
    blockquotePadding: const EdgeInsets.all(16),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(
          color: colorScheme.primary.withOpacity(0.5),
          width: 4.0,
        ),
      ),
    ),
    codeblockPadding: const EdgeInsets.all(16),
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
    tableHead: TextStyle(
      fontWeight: FontWeight.bold,
      color: colorScheme.primary,
    ),
    tableBorder: TableBorder.all(color: colorScheme.outlineVariant, width: 1.0),
    tableColumnWidth: const IntrinsicColumnWidth(),
    tableCellsPadding: const EdgeInsets.all(8.0),
    tableCellsDecoration: BoxDecoration(
      color: colorScheme.surface,
      border: Border.all(color: colorScheme.outlineVariant, width: 1.0),
    ),

    // Link styles
    a: TextStyle(
      color: colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: colorScheme.primary.withOpacity(0.4),
    ),
  );
}


