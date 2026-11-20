import 'package:flutter/material.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/ui/widgets/dragon_image_widget.dart';

// Define action types for better type safety
enum QuizAction { retake, reread, returnToLesson, playWithDragon }

class PostQuizActionsScreen extends StatefulWidget {
  const PostQuizActionsScreen({
    super.key,
    required this.moduleId,
    required this.passingScore,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.handleAction,
  });

  final String moduleId;
  final int passingScore;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final Future<void> Function(QuizAction action) handleAction;

  @override
  State<PostQuizActionsScreen> createState() => _PostQuizActionsScreenState();
}

class _PostQuizActionsScreenState extends State<PostQuizActionsScreen> {
  void _handleRetakeQuiz() {
    widget.handleAction(QuizAction.retake);
  }

  void _handleReReadLesson() {
    widget.handleAction(QuizAction.reread);
  }

  void _handleReturnToLesson() {
    widget.handleAction(QuizAction.returnToLesson);
  }

  Widget _buildDividerWithOr(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            thickness: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.55),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'OR',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            thickness: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required ThemeData theme,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final Color bg = backgroundColor ?? theme.colorScheme.primary;
    final Color fg = foregroundColor ?? theme.colorScheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: bg,
          foregroundColor: fg,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: fg,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required ThemeData theme,
    required String label,
    required VoidCallback onPressed,
  }) {
    final Color fg = theme.colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: fg, width: 1.5),
          foregroundColor: fg,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: fg,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPassedView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 42),
        Text(
          'Your Dragon is full grown!',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 34),
        SizedBox(
          height: 300,
          child: DragonImageWidget(
            moduleId: widget.moduleId,
            size: 300,
            phase: 'final',
          ),
        ),
        const SizedBox(height: 28),
        _buildPrimaryButton(
          theme: theme,
          label: 'Play with Dragon',
          onPressed: () => widget.handleAction(QuizAction.playWithDragon),
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
        ),
        const SizedBox(height: 28),
        _buildDividerWithOr(theme),
        const SizedBox(height: 28),
        _buildSecondaryButton(
          theme: theme,
          label: 'Return to Lesson',
          onPressed: _handleReturnToLesson,
        ),
      ],
    );
  }

  Widget _buildFailedView(ThemeData theme) {
    final bool canRetake = widget.score >= 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Text(
          'Quiz Score',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.correctAnswers} out of ${widget.totalQuestions}',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Suggested Action',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 22),
        if (canRetake) ...[
          _buildPrimaryButton(
            theme: theme,
            label: 'Retake quiz',
            onPressed: _handleRetakeQuiz,
          ),
          const SizedBox(height: 18),
          _buildDividerWithOr(theme),
          const SizedBox(height: 18),
        ],
        _buildSecondaryButton(
          theme: theme,
          label: 'Re-read lesson',
          onPressed: _handleReReadLesson,
        ),
        const SizedBox(height: 24),
        _buildSecondaryButton(
          theme: theme,
          label: 'Return to lesson',
          onPressed: _handleReturnToLesson,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool passed = widget.score >= widget.passingScore;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(passed ? 'Quiz Complete' : 'Results'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 4, 30, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 28,
                ),
                child: IntrinsicHeight(
                  child:
                      passed
                          ? _buildPassedView(theme)
                          : _buildFailedView(theme),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
