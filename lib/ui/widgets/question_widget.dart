import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_scales/models/question.dart';

import '../../themes/app_theme.dart';
import '../../services/notes_service.dart';
import 'styled_markdown.dart';

class QuestionWidget extends StatefulWidget {
  final Question question;
  final List<int> selectedAnswers;
  final Function(List<int>) onAnswerChanged;
  final bool showCorrectAnswer;
  final bool showExplanation;
  final bool isResponseLocked;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.selectedAnswers,
    required this.onAnswerChanged,
    required this.showCorrectAnswer,
    required this.isResponseLocked,
    this.showExplanation = false,
  });

  @override
  _QuestionWidgetState createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  final double optionPadding = 15;
  final double optionMargin = 10;

  /// Font scale for quiz question and options (reduced from base for better fit)
  static const double _quizFontScale = 0.88;
  late ScrollController _scrollController;
  final NotesService _notesService = NotesService();
  String? _savedNote;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadNote();
  }

  Future<void> _loadNote() async {
    try {
      final note = await _notesService.getNote(widget.question.id);
      if (mounted) {
        setState(() {
          _savedNote = note;
        });
      }
    } catch (e) {
      debugPrint('Error loading note: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset scroll position when question changes
    if (oldWidget.question != widget.question) {
      // Use post-frame callback to ensure scroll reset happens after widget rebuilds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Reset main scroll controller if it has clients
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        }
      });
      _loadNote(); // Reload note for new question
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy_explanation':
        _copyToClipboard(widget.question.explanation);
        break;
      case 'save_note':
        _showSaveNoteDialog();
        break;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSaveNoteDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => _SaveNoteDialog(questionId: widget.question.id),
    );
    
    // Reload note after dialog closes
    if (result == true || result == null) {
      _loadNote();
    }
  }

  Widget _buildSavedNoteSection() {
    ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.note,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your Note:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  size: 18,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                ),
                onPressed: _showSaveNoteDialog,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _savedNote!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    Question question = widget.question;
    
    final hasImageInText = StyledMarkdown.containsImage(question.text ?? '');
    final hasImageInQuestion = StyledMarkdown.containsImage(question.questionText);
    final hasImage = hasImageInText || hasImageInQuestion;

    final instructionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontStyle: FontStyle.italic,
      color: theme.colorScheme.outline,
      fontSize: (theme.textTheme.bodySmall?.fontSize ?? 15) * _quizFontScale,
    );
    Text instructionText = Text(
      'Choose one option:',
      style: instructionStyle,
    );

    if (question.isMultipleAnswer) {
      instructionText = Text(
        'Select all that apply:',
        style: instructionStyle,
      );
    }

    // Different layout when images are present
    if (hasImage) {
      return SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (question.text != null) ...[
              // Extra Text exists with image
              Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: StyledMarkdown(
                  data: question.text!,
                  fontSizeScale: AppTheme.fontSizeScale * _quizFontScale,
                ),
              ),
            ],

            // Question with image - no spacer, better spacing
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: StyledMarkdown(
                      data: question.questionText,
                      fontSizeScale: AppTheme.fontSizeScale * _quizFontScale,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.note_add,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: _showSaveNoteDialog,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            instructionText,

            buildOptions(),

            // Show saved note if exists
            if (_savedNote != null && _savedNote!.isNotEmpty)
              _buildSavedNoteSection(),

            // Show explanation after user answers (when response is locked or we have answers)
            if (widget.showExplanation &&
                question.explanation.isNotEmpty &&
                (widget.isResponseLocked || widget.selectedAnswers.isNotEmpty))
              _buildExplanationSection(),
          ],
        ),
      );
    }

    // Original layout when no images
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question.text != null) ...[
            // Extra Text exists, show it first
            Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: StyledMarkdown(
                data: question.text!,
                fontSizeScale: AppTheme.fontSizeScale,
              ),
            ),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StyledMarkdown(
                  data: question.questionText,
                  fontSizeScale: AppTheme.fontSizeScale * _quizFontScale,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.note_add,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
                onPressed: _showSaveNoteDialog,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),

          SizedBox(height: 20),

          instructionText,

          buildOptions(),

          // Show saved note if exists
          if (_savedNote != null && _savedNote!.isNotEmpty)
            _buildSavedNoteSection(),

          // Show explanation after user answers (when response is locked or we have answers)
          if (widget.showExplanation &&
              question.explanation.isNotEmpty &&
              (widget.isResponseLocked || widget.selectedAnswers.isNotEmpty))
            _buildExplanationSection(),
        ],
      ),
    );
    //   ),
    // );
  }

  GestureDetector buildOption(
    List<int> selectedAnswers,
    Question question,
    bool isSelected,
    int index,
    String option,
  ) {
    ThemeData theme = Theme.of(context);

    return GestureDetector(
      onTap:
          widget.isResponseLocked
              ? null
              : () {
                List<int> newAnswers = List.from(selectedAnswers);

                if (question.isMultipleAnswer) {
                  if (isSelected) {
                    newAnswers.remove(index);
                  } else {
                    newAnswers.add(index);
                  }
                } else {
                  newAnswers = [index];
                }

                widget.onAnswerChanged(newAnswers);
              },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: optionMargin),
        padding: EdgeInsets.all(optionPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color:
              isSelected
                  ? theme.colorScheme.primaryContainer
                  : widget.isResponseLocked
                  ? theme.colorScheme.surfaceDim
                  : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
                question.isMultipleAnswer
                    ? (isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank_rounded)
                    : (isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked),
                color:
                    isSelected || !widget.isResponseLocked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            SizedBox(width: 12),
            Expanded(
              child: StyledMarkdown(
                data: option,
                fontSizeScale: AppTheme.fontSizeScale * _quizFontScale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOptions() {
    double fontScale = AppTheme.fontSizeScale;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 10 * fontScale,
        horizontal: 0,
      ),
      child: Column(
        children: List.generate(
          widget.question.options.length,
          (index) {
            final option = widget.question.options[index];
            final isSelected = widget.selectedAnswers.contains(index);
            return buildOption(
              widget.selectedAnswers,
              widget.question,
              isSelected,
              index,
              option,
            );
          },
        ),
      ),
    );
  }

  Widget _buildExplanationSection() {
    ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Explanation:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  size: 20,
                ),
                onSelected: (value) {
                  _handleMenuAction(value);
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'copy_explanation',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 18),
                        SizedBox(width: 8),
                        Text('Copy Explanation'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'save_note',
                    child: Row(
                      children: [
                        Icon(Icons.note_add, size: 18),
                        SizedBox(width: 8),
                        Text('Save Note'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          StyledMarkdown(
            data: widget.question.explanation,
            fontSizeScale: AppTheme.fontSizeScale,
          ),
        ],
      ),
    );
  }
}

class _SaveNoteDialog extends StatefulWidget {
  final String questionId;

  const _SaveNoteDialog({required this.questionId});

  @override
  State<_SaveNoteDialog> createState() => _SaveNoteDialogState();
}

class _SaveNoteDialogState extends State<_SaveNoteDialog> {
  final TextEditingController _noteController = TextEditingController();
  final NotesService _notesService = NotesService();
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingNote();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingNote() async {
    try {
      final existingNote = await _notesService.getNote(widget.questionId);
      if (existingNote != null && mounted) {
        _noteController.text = existingNote;
      }
    } catch (e) {
      debugPrint('Error loading note: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    if (_isLoading) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    return AlertDialog(
      title: Text('Save Note'),
      content: TextField(
        controller: _noteController,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Enter your note about this question...',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        if (_noteController.text.trim().isNotEmpty)
          TextButton(
            onPressed: _isSaving ? null : _deleteNote,
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: _isSaving ? null : _saveNote,
          child: _isSaving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveNote() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final noteText = _noteController.text.trim();
      if (noteText.isEmpty) {
        // If note is empty, delete it
        await _notesService.deleteNote(widget.questionId);
      } else {
        await _notesService.saveNote(widget.questionId, noteText);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(noteText.isEmpty ? 'Note deleted' : 'Note saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteNote() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _notesService.deleteNote(widget.questionId);
      
      if (mounted) {
        _noteController.clear();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting note: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
