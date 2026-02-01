import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'image_thumbnail.dart';
import '../../services/tts_service.dart';

class ClickableTextScrubber extends StatelessWidget {
  final String markdownData;
  final String cleanText; // Text without markdown for TTS position mapping
  final int? currentWordStart;
  final int? currentWordEnd;
  final Set<int> wordsRead;
  final Function(int position) onWordTap;
  final double fontSizeScale;
  final TtsService ttsService;

  const ClickableTextScrubber({
    super.key,
    required this.markdownData,
    required this.cleanText,
    this.currentWordStart,
    this.currentWordEnd,
    required this.wordsRead,
    required this.onWordTap,
    this.fontSizeScale = 1.0,
    required this.ttsService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Clean and validate the markdown data
    final cleanData = _cleanMarkdownData(markdownData);

    // For now, use StyledMarkdown as a workaround for the _inlines.isEmpty assertion
    // TODO: Fix custom builder to properly handle inline elements
    // When highlighting is needed, we'll need to implement a different approach
    if (currentWordStart == null && wordsRead.isEmpty) {
      // No highlighting needed - use simple markdown rendering
      try {
        return MarkdownBody(
          data: cleanData,
          selectable: false,
          softLineBreak: true,
          fitContent: false,
          imageBuilder: (uri, title, alt) {
            return Center(
              child: ImageThumbnail(
                imageUrl: uri.toString(),
                altText: alt,
                thumbnailSize: 280,
              ),
            );
          },
          styleSheet: _getMarkdownStyleSheet(theme, colorScheme),
          onTapLink: (text, href, title) async {
            if (href != null && href.isNotEmpty) {
              try {
                final url = Uri.parse(href);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              } catch (e) {
                debugPrint('Failed to launch URL: $href - $e');
              }
            }
          },
        );
      } catch (e) {
        debugPrint('Markdown parsing error: $e');
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            cleanData,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
          ),
        );
      }
    }

    // When highlighting is needed, use custom builder (with workaround for inline elements)
    try {
      return MarkdownBody(
        data: cleanData,
        selectable: false,
        softLineBreak: true,
        fitContent: false,
        imageBuilder: (uri, title, alt) {
          return Center(
            child: ImageThumbnail(
              imageUrl: uri.toString(),
              altText: alt,
              thumbnailSize: 280,
            ),
          );
        },
        styleSheet: _getMarkdownStyleSheet(theme, colorScheme),
        onTapLink: (text, href, title) async {
          if (href != null && href.isNotEmpty) {
            try {
              final url = Uri.parse(href);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            } catch (e) {
              debugPrint('Failed to launch URL: $href - $e');
            }
          }
        },
        // Only use custom builder if we have active highlighting
        // Otherwise use default rendering to avoid assertion errors
        builders:
            (currentWordStart != null || wordsRead.isNotEmpty)
                ? {
                  // Custom paragraph builder with word-level highlighting and click handling
                  'p': _ClickableParagraphBuilder(
                    cleanText: cleanText,
                    currentWordStart: currentWordStart,
                    currentWordEnd: currentWordEnd,
                    wordsRead: wordsRead,
                    onWordTap: onWordTap,
                    theme: theme,
                    fontSizeScale: fontSizeScale,
                  ),
                }
                : const {},
      );
    } catch (e) {
      debugPrint('Markdown parsing error: $e');
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          cleanData,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
        ),
      );
    }
  }

  MarkdownStyleSheet _getMarkdownStyleSheet(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return MarkdownStyleSheet(
      // Text styles with font size scaling
      p: theme.textTheme.bodyMedium?.copyWith(
        height: 1.8,
        fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 18) * fontSizeScale,
      ),
      h1: theme.textTheme.headlineLarge?.copyWith(
        fontSize:
            (theme.textTheme.headlineLarge?.fontSize ?? 30) * fontSizeScale,
      ),
      h2: theme.textTheme.headlineMedium?.copyWith(
        fontSize:
            (theme.textTheme.headlineMedium?.fontSize ?? 25) * fontSizeScale,
      ),
      h3: theme.textTheme.headlineSmall?.copyWith(
        fontSize:
            (theme.textTheme.headlineSmall?.fontSize ?? 22) * fontSizeScale,
      ),
      h4: theme.textTheme.titleLarge?.copyWith(
        fontSize: (theme.textTheme.titleLarge?.fontSize ?? 20) * fontSizeScale,
      ),
      h5: theme.textTheme.titleMedium?.copyWith(
        fontSize: (theme.textTheme.titleMedium?.fontSize ?? 18) * fontSizeScale,
      ),
      h6: theme.textTheme.titleSmall?.copyWith(
        fontSize: (theme.textTheme.titleSmall?.fontSize ?? 16) * fontSizeScale,
      ),
      em: TextStyle(
        fontStyle: FontStyle.italic,
        fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 18) * fontSizeScale,
      ),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 18) * fontSizeScale,
      ),
      code: TextStyle(
        fontFamily: 'monospace',
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
        fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 18) * fontSizeScale,
      ),
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
        fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 18) * fontSizeScale,
      ),
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
      tableHead: TextStyle(fontWeight: FontWeight.bold),
      tableBorder: TableBorder.all(
        color: colorScheme.outlineVariant,
        width: 1.0,
      ),
      tableColumnWidth: const IntrinsicColumnWidth(),
      tableCellsPadding: const EdgeInsets.all(8.0),
    );
  }

  String _cleanMarkdownData(String data) {
    if (data.isEmpty) {
      return 'No content available.';
    }

    String cleaned =
        data
            .replaceAll('\x00', '')
            .replaceAll(RegExp(r'[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
            .trim();

    cleaned = cleaned.replaceAll(RegExp(r'\r\n'), '\n').replaceAll('\r', '\n');

    if (cleaned.isEmpty) {
      return 'No content available.';
    }

    return cleaned;
  }
}

/// Custom paragraph builder that creates clickable words with highlighting
class _ClickableParagraphBuilder extends MarkdownElementBuilder {
  final String cleanText;
  final int? currentWordStart;
  final int? currentWordEnd;
  final Set<int> wordsRead;
  final Function(int position) onWordTap;
  final ThemeData theme;
  final double fontSizeScale;

  _ClickableParagraphBuilder({
    required this.cleanText,
    this.currentWordStart,
    this.currentWordEnd,
    required this.wordsRead,
    required this.onWordTap,
    required this.theme,
    required this.fontSizeScale,
  });

  @override
  void visitElementBefore(md.Element element) {
    // Call parent to process any inline elements first
    // This helps ensure _inlines is cleared properly
    try {
      super.visitElementBefore(element);
    } catch (e) {
      // If parent call fails, continue anyway
      debugPrint('Error in visitElementBefore: $e');
    }
  }

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Only handle paragraph elements with no inline children
    // If the element has inline children (bold, italic, links, etc.),
    // use default processing to avoid assertion errors
    if (element.tag != 'p') {
      return super.visitElementAfter(element, preferredStyle);
    }

    // Check if paragraph has inline children - if so, use default processing
    final hasInlineChildren =
        element.children?.any((child) {
          if (child is md.Element) {
            final tag = child.tag;
            return tag == 'em' ||
                tag == 'strong' ||
                tag == 'a' ||
                tag == 'code';
          }
          return false;
        }) ??
        false;

    if (hasInlineChildren) {
      // Use default processing for paragraphs with inline elements
      return super.visitElementAfter(element, preferredStyle);
    }

    final text = element.textContent;
    if (text.isEmpty) {
      // Return null to use default processing
      return super.visitElementAfter(element, preferredStyle);
    }

    // Remove markdown formatting from paragraph text for position matching
    final cleanedParagraph = _cleanParagraphText(text);

    // Parse words and create clickable text spans
    final textSpans = <TextSpan>[];
    final words = <_WordInfo>[];
    int currentPosition = 0;
    int globalOffset = 0;

    // Match words (including punctuation attached to words)
    final wordPattern = RegExp(r'\S+');
    final matches = wordPattern.allMatches(cleanedParagraph);

    for (final match in matches) {
      final word = match.group(0)!;
      final wordStart = match.start;
      final wordEnd = match.end;

      // Add whitespace before word if needed
      if (wordStart > currentPosition) {
        final whitespace = cleanedParagraph.substring(
          currentPosition,
          wordStart,
        );
        textSpans.add(TextSpan(text: whitespace));
        globalOffset += whitespace.length;
      }

      // Find position in cleanText
      final wordPosition = _findWordPositionInCleanText(
        word,
        wordStart,
        cleanedParagraph,
      );

      // Determine word style based on reading state
      final style = _getWordStyle(wordPosition, wordEnd - wordStart);

      // Store word info for tap detection
      if (wordPosition != null) {
        words.add(
          _WordInfo(
            startOffset: globalOffset,
            endOffset: globalOffset + word.length,
            position: wordPosition,
          ),
        );
      }

      // Create text span for word
      textSpans.add(TextSpan(text: word, style: style));

      globalOffset += word.length;
      currentPosition = wordEnd;
    }

    // Add remaining whitespace
    if (currentPosition < cleanedParagraph.length) {
      final remaining = cleanedParagraph.substring(currentPosition);
      textSpans.add(TextSpan(text: remaining));
    }

    final textSpan = TextSpan(
      style:
          preferredStyle != null
              ? preferredStyle.copyWith(
                fontSize: (preferredStyle.fontSize ?? 18) * fontSizeScale,
                height: 1.8,
              )
              : TextStyle(fontSize: 18 * fontSizeScale, height: 1.8),
      children: textSpans,
    );

    return _ClickableRichText(
      textSpan: textSpan,
      onWordTap: onWordTap,
      words: words,
    );
  }

  /// Clean paragraph text to match TTS cleaning (similar to TtsService._enhanceTextForNaturalSpeech)
  String _cleanParagraphText(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // Bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // Italic
        .replaceAll(RegExp(r'`(.*?)`'), r'$1') // Code
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1') // Links
        .replaceAll(RegExp(r'\n'), ' ') // Newlines to spaces
        .replaceAll(RegExp(r'\s+'), ' '); // Multiple spaces to single
  }

  /// Find the position of a word in cleanText
  /// Returns the start position in cleanText, or null if not found
  int? _findWordPositionInCleanText(
    String word,
    int wordIndexInParagraph,
    String paragraph,
  ) {
    // Try to find the paragraph's position in cleanText
    // Then add the word's offset within the paragraph
    final cleanedParagraph = _cleanParagraphText(paragraph);

    // Find where this paragraph appears in cleanText
    int paragraphStart = -1;

    // Search for the first few words of the paragraph to locate it
    final firstWords = cleanedParagraph.split(' ').take(3).join(' ');
    if (firstWords.isNotEmpty && firstWords.length <= cleanText.length) {
      for (int i = 0; i <= cleanText.length - firstWords.length; i++) {
        final candidate = cleanText.substring(i, i + firstWords.length);
        if (candidate == firstWords) {
          paragraphStart = i;
          break; // Take first match
        }
      }
    }

    // If we found paragraph start, calculate word position
    if (paragraphStart != -1) {
      // Calculate word position within paragraph
      final wordsBefore = cleanedParagraph
          .substring(0, wordIndexInParagraph)
          .split(' ');
      int wordOffset = 0;
      for (final w in wordsBefore) {
        if (w.isNotEmpty) {
          wordOffset += w.length + 1; // +1 for space
        }
      }
      // Find the word in the paragraph starting from paragraphStart
      final paragraphInCleanText = cleanText
          .substring(paragraphStart)
          .substring(0, cleanedParagraph.length);
      final wordIndexInCleanParagraph = paragraphInCleanText.indexOf(
        word,
        wordOffset - word.length,
      );
      if (wordIndexInCleanParagraph != -1) {
        return paragraphStart + wordIndexInCleanParagraph;
      }
    }

    // Fallback: simple word search (may find wrong occurrence for common words)
    final index = cleanText.indexOf(word);
    return index != -1 ? index : null;
  }

  /// Get text style for a word based on reading state
  TextStyle _getWordStyle(int? wordStart, int wordLength) {
    final baseStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontSize:
              (theme.textTheme.bodyMedium?.fontSize ?? 18) * fontSizeScale,
        ) ??
        const TextStyle();

    if (wordStart == null) {
      return baseStyle;
    }

    final wordEnd = wordStart + wordLength;

    // Check if currently reading this word
    if (currentWordStart != null &&
        currentWordEnd != null &&
        wordStart <= currentWordEnd! &&
        wordEnd >= currentWordStart!) {
      // Currently reading - highlight with primary color and background
      return baseStyle.copyWith(
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.5,
        ),
        fontWeight: FontWeight.w600,
      );
    }

    // Check if word has been read
    bool isRead = false;
    for (int i = wordStart; i < wordEnd && i < cleanText.length; i++) {
      if (wordsRead.contains(i)) {
        isRead = true;
        break;
      }
    }

    if (isRead) {
      // Already read - muted color
      return baseStyle.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      );
    }

    // Not read yet - default color
    return baseStyle;
  }
}

/// Widget that wraps RichText and detects word taps
class _ClickableRichText extends StatelessWidget {
  final TextSpan textSpan;
  final Function(int position) onWordTap;
  final List<_WordInfo> words;

  const _ClickableRichText({
    required this.textSpan,
    required this.onWordTap,
    required this.words,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: (details) {
                textPainter.layout(maxWidth: constraints.maxWidth);
                final position = textPainter.getPositionForOffset(
                  details.localPosition,
                );

                // Find which word was tapped based on character offset
                for (final wordInfo in words) {
                  if (position.offset >= wordInfo.startOffset &&
                      position.offset <= wordInfo.endOffset) {
                    onWordTap(wordInfo.position);
                    break;
                  }
                }
              },
              child: RichText(text: textSpan),
            );
          },
        );
      },
    );
  }
}

/// Information about a word for tap detection
class _WordInfo {
  final int startOffset;
  final int endOffset;
  final int position;

  _WordInfo({
    required this.startOffset,
    required this.endOffset,
    required this.position,
  });
}
