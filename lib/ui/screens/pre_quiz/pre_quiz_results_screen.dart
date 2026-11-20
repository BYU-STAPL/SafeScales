import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/providers/dragon_decoration_provider.dart';
import 'package:safe_scales/providers/dragon_provider.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/ui/screens/dragon_decoration/dragon_decoration_screen.dart';
import 'package:safe_scales/ui/widgets/dragon_image_widget.dart';

class PreQuizResultScreen extends StatefulWidget {
  final String moduleId;
  final QuestionSet questionSet;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final List<List<int>> userAnswers;

  const PreQuizResultScreen({
    super.key,
    required this.moduleId,
    required this.questionSet,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.userAnswers,
  });

  @override
  State<PreQuizResultScreen> createState() => _PreQuizResultScreenState();
}

class _PreQuizResultScreenState extends State<PreQuizResultScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<bool> _saveDragonName(DragonProvider dragonProvider) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return true;

    final dragon = dragonProvider.getDragonByModuleId(widget.moduleId);
    if (dragon == null) {
      _showMessage('Could not find this lesson dragon to save its name.');
      return false;
    }

    await dragonProvider.updateDragonName(dragon.id, name);
    if (!mounted) return false;

    final error = dragonProvider.error;
    if (error != null) {
      _showMessage(error);
      return false;
    }
    return true;
  }

  Future<void> _playWithDragon() async {
    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
    if (!await _saveDragonName(dragonProvider) || !mounted) return;

    await dragonProvider.updateDragonPhases(widget.moduleId);
    if (!mounted) return;

    final dragon = dragonProvider.getDragonByModuleId(widget.moduleId);
    if (dragon == null) {
      _showMessage('Could not find this lesson dragon.');
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder:
            (context) => MultiProvider(
              providers: [
                ChangeNotifierProvider<DragonDecorationProvider>(
                  create: (_) => DragonDecorationProvider(),
                ),
              ],
              child: DragonDressUpPage(
                dragonId: dragon.id,
                currentPhase: dragonProvider.getUserPreferredPhase(dragon.id),
              ),
            ),
      ),
    );
  }

  Future<void> _goToLesson() async {
    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
    if (!await _saveDragonName(dragonProvider) || !mounted) return;
    Navigator.pop(context, true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildNameCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Give your dragon a name',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can also name your dragon later in the Dragons Tab',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.35,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            maxLength:
                Provider.of<DragonProvider>(
                  context,
                  listen: false,
                ).maxNameLength,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Type a name...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              counterText: '',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Meet your new dragon!',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        Consumer<DragonProvider>(
          builder: (context, dragonProvider, child) {
            final dragon = dragonProvider.getDragonByModuleId(widget.moduleId);
            return DragonImageWidget(
              moduleId: widget.moduleId,
              phase:
                  dragon == null
                      ? null
                      : dragonProvider.getUserPreferredPhase(dragon.id),
              size: 200,
            );
          },
        ),
        const SizedBox(height: 20),
        _buildNameCard(theme),
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    final buttonRadius = BorderRadius.circular(12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _playWithDragon,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: buttonRadius),
            ),
            child: Text(
              'PLAY WITH DRAGON',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                endIndent: 14,
              ),
            ),
            Text(
              'OR',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                indent: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _goToLesson,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: buttonRadius),
            ),
            child: Text(
              'GO TO LESSON',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Survey Complete'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(child: _buildHeroContent(theme)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildActions(theme),
            ],
          ),
        ),
      ),
    );
  }
}
