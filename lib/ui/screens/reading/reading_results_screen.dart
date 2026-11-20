import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/providers/dragon_decoration_provider.dart';
import 'package:safe_scales/providers/dragon_provider.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/ui/screens/dragon_decoration/dragon_decoration_screen.dart';
import 'package:safe_scales/ui/widgets/dragon_image_widget.dart';

class ReadingResultScreen extends StatefulWidget {
  const ReadingResultScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  State<ReadingResultScreen> createState() => _ReadingResultScreenState();
}

class _ReadingResultScreenState extends State<ReadingResultScreen> {
  bool _isNavigating = false;

  Future<void> _playWithDragon() async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    final dragonProvider = Provider.of<DragonProvider>(context, listen: false);
    await dragonProvider.updateDragonPhases(widget.moduleId);

    if (!mounted) return;

    final dragon = dragonProvider.getDragonByModuleId(widget.moduleId);
    if (dragon == null) {
      _isNavigating = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find this lesson dragon.')),
      );
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

    if (mounted) {
      _isNavigating = false;
    }
  }

  void _handleReturnToLesson() {
    // Prevent multiple taps - use sync flag only (no setState before pop)
    // setState before Navigator.pop can cause race conditions where the widget
    // is disposed during a scheduled rebuild, leading to inconsistent behavior
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    Navigator.pop(context, true);
  }

  Widget _buildHeroContent(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Your dragon grew!',
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
            onPressed: _isNavigating ? null : _playWithDragon,
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
            onPressed: _isNavigating ? null : _handleReturnToLesson,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: buttonRadius),
            ),
            child: Text(
              'RETURN TO LESSON',
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
        title: const Text('Reading Complete'),
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
