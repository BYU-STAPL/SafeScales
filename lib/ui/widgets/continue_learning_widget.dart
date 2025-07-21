import 'package:flutter/material.dart';
import 'package:safe_scales/extensions/string_extensions.dart';

class ContinueLearningWidget extends StatelessWidget {
  const ContinueLearningWidget({
    super.key,
    required List<Map<String, dynamic>> modules,
    required Map<String, double> moduleProgress,
  }) : _modules = modules, _moduleProgress = moduleProgress;

  final List<Map<String, dynamic>> _modules;
  final Map<String, double> _moduleProgress;

  @override
  Widget build(BuildContext context) {

    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor.withValues(alpha: 0.9), theme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Continue Learning'.toTitleCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  // Find the target module
                  Map<String, dynamic>? targetModule;
                  for (var module in _modules) {
                    final progress = _moduleProgress[module['id']] ?? 0.0;
                    if (progress < 100) {
                      targetModule = module;
                      break;
                    }
                  }
                  targetModule ??= _modules.last;

                  return Text(
                    (targetModule['title'] ?? 'Module').toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 1.2,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  // Find the target module and its progress
                  Map<String, dynamic>? targetModule;
                  double progress = 0;
                  for (var module in _modules) {
                    final moduleProgress = _moduleProgress[module['id']] ?? 0.0;
                    if (moduleProgress < 100) {
                      targetModule = module;
                      progress = moduleProgress;
                      break;
                    }
                  }
                  if (targetModule == null && _modules.isNotEmpty) {
                    targetModule = _modules.last;
                    progress = _moduleProgress[targetModule['id']] ?? 0.0;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${progress.toStringAsFixed(0)}% Complete'.toTitleCase(),
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                    ),
                  );
                },
              ),
            ],
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    );
  }
}