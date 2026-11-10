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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Give your dragon a name',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You can also name your dragon later in the Dragons tab',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            maxLength:
                Provider.of<DragonProvider>(
                  context,
                  listen: false,
                ).maxNameLength,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Type a name...',
              counterText: '',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHigh,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey Complete'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(30, 18, 30, 18),
                child: Column(
                  children: [
                    Text(
                      'Meet your new dragon!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Consumer<DragonProvider>(
                      builder: (context, dragonProvider, child) {
                        final dragon = dragonProvider.getDragonByModuleId(
                          widget.moduleId,
                        );
                        return DragonImageWidget(
                          moduleId: widget.moduleId,
                          phase:
                              dragon == null
                                  ? null
                                  : dragonProvider.getUserPreferredPhase(
                                    dragon.id,
                                  ),
                          size: 200,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildNameCard(theme),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 8, 30, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _playWithDragon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('PLAY WITH DRAGON'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: theme.colorScheme.outline,
                          endIndent: 14,
                        ),
                      ),
                      Text(
                        'OR',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: theme.colorScheme.outline,
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('GO TO LESSON'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
