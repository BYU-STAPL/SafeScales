import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/extensions/string_extensions.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/dragon_service.dart';
import 'package:safe_scales/services/class_service.dart';

import 'lesson/lesson_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final QuizService _quizService = QuizService();
  final _userState = UserStateService();
  final _dragonService = DragonService(QuizService().supabase);
  late final ClassService _classService;

  // Class-based variables
  Map<String, dynamic>? _currentClass;
  List<Map<String, dynamic>> _modules = [];
  Map<String, double> _moduleProgress = {};
  List<dynamic>? _classAssets;
  final Map<String, Map<String, dynamic>> _moduleDragons = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _classService = ClassService(_quizService.supabase);
    _loadClassData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this page
    _loadClassData();
  }

  Future<void> _loadClassData() async {
    try {
      final user = _userState.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _currentClass = null;
          _modules = [];
        });
        return;
      }

      // Get user's class
      final classData = await _classService.getUserClass(user.id);

      if (classData.isEmpty) {
        setState(() {
          _isLoading = false;
          _currentClass = null;
          _modules = [];
        });
        return;
      }

      // Get class modules
      final modules = await _classService.getClassModules(classData['id']);

      // Get module progress
      final moduleIds = modules.map((m) => m['id'] as String).toList();
      final moduleProgress = await _quizService.getModuleProgress(
        userId: user.id,
        moduleIds: moduleIds,
      );

      // Get class assets (dragons)
      final assets = await _classService.getClassAssets(classData['id']);
      _classAssets = assets;

      if (mounted) {
        setState(() {
          _currentClass = classData;
          _modules = modules;
          _moduleProgress = moduleProgress;
          _isLoading = false;
        });

        await _loadDragonImages();
      }
    } catch (e) {
      print('Error loading class data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDragonImages() async {
    try {
      // Use dragons from class assets if available
      if (_classAssets != null) {
        List<dynamic> assetsList;
        if (_classAssets is List) {
          assetsList = _classAssets as List;
        } else if (_classAssets is Map) {
          // If it's a Map, try to get the assets list from it
          assetsList = (_classAssets as Map)['assets'] as List? ?? [];
        } else {
          assetsList = [];
        }

        // Find dragon assets
        final dragonAssets =
            assetsList
                .where((asset) => asset is Map && asset['type'] == 'dragon')
                .toList();

        // Assign dragons to modules
        for (var i = 0; i < _modules.length && i < dragonAssets.length; i++) {
          final module = _modules[i];
          final dragon = dragonAssets[i];

          if (dragon['stages'] != null) {
            _moduleDragons[module['id']] = {
              'egg': dragon['stages']['egg'] ?? 'assets/images/other/egg.png',
              'baby':
                  dragon['stages']['baby'] ?? 'assets/images/other/young.png',
              'teen':
                  dragon['stages']['teen'] ?? 'assets/images/other/teen.png',
              'final':
                  dragon['stages']['adult'] ?? 'assets/images/other/adult.png',
              'id': dragon['id'],
              'name': dragon['name'] ?? 'Dragon',
              'moduleId': dragon['moduleId'] ?? module['id'],
            };
          }
        }
      } else {
        // Fallback to old dragon loading system
        await _dragonService.initialize();

        for (var i = 0; i < _modules.length; i++) {
          final dragonData = await _dragonService.getDragonImagesForModule(i);
          if (mounted) {
            setState(() {
              _moduleDragons[_modules[i]['id']] = dragonData;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading dragon images: $e');
    }
  }

  // Get icon based on module progress
  Widget _getDragonPhaseIcon(String moduleId) {
    final progress = _moduleProgress[moduleId] ?? 0.0;
    final dragonData = _moduleDragons[moduleId];

    String imageUrl = dragonData?['egg'] ?? 'assets/images/other/egg.png';
    List<String> phases = ['egg']; // Always start with egg

    // Add phases based on progress, ensuring all previous phases are included
    if (progress >= 30) {
      phases.add('baby'); // Add baby phase
    }
    if (progress >= 50) {
      phases.add('teen'); // Add teen phase
    }
    if (progress >= 80) {
      phases.add('adult'); // Add adult phase
    }

    // Save dragon phases if we have a valid dragon ID
    if (dragonData != null && dragonData['id'] != null) {
      final user = _userState.currentUser;
      if (user != null) {
        _dragonService
            .saveDragonPhases(user.id, dragonData['id'].toString(), phases)
            .catchError((e) {
              print('Error saving dragon phases: $e');
            });
      }
    }

    // Set the image URL based on the highest achieved phase
    if (progress >= 80) {
      imageUrl = dragonData?['adult'] ?? 'assets/images/other/adult.png';
    } else if (progress >= 50) {
      imageUrl = dragonData?['teen'] ?? 'assets/images/other/teen.png';
    } else if (progress >= 30) {
      imageUrl = dragonData?['baby'] ?? 'assets/images/other/young.png';
    }

    // Check if the image URL is a network URL or a local asset
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 64,
        height: 64,
        errorBuilder: (context, error, stackTrace) {
          // Error loading dragon image
          return Image.asset(
            'assets/images/other/egg.png',
            width: 64,
            height: 64,
          );
        },
      );
    } else {
      return Image.asset(imageUrl, width: 64, height: 64);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final cardBg = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final mutedTextColor = theme.colorScheme.onSurfaceVariant;
    final lockedBg = theme.colorScheme.surfaceVariant;
    const borderRadius = 16.0;

    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Header
                if (_currentClass != null) ...[
                  Text(
                    _currentClass!['name'] ?? 'Class',
                    style: theme.textTheme.headlineLarge,
                  ),
                  if (_currentClass!['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _currentClass!['description'],
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],

                // Continue Learning Card
                if (_modules.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      // Find the latest incomplete module
                      Map<String, dynamic>? targetModule;
                      for (var module in _modules) {
                        final progress = _moduleProgress[module['id']] ?? 0.0;
                        if (progress < 100) {
                          targetModule = module;
                          break;
                        }
                      }

                      // If all modules are complete, go to the last module
                      targetModule ??= _modules.last;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  LessonPage(moduleId: targetModule!['id']),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary.withOpacity(0.9), primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.3),
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
                                'Continue Learning'..toTitleCase(),
                                // Note: Copy with for some reason can't change font weight, but everything else it can
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
                                    final progress =
                                        _moduleProgress[module['id']] ?? 0.0;
                                    if (progress < 100) {
                                      targetModule = module;
                                      break;
                                    }
                                  }
                                  targetModule ??= _modules.last;

                                  return Text(
                                    (targetModule['title'] ?? 'Module')
                                        .toUpperCase(),
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
                                    final moduleProgress =
                                        _moduleProgress[module['id']] ?? 0.0;
                                    if (moduleProgress < 100) {
                                      targetModule = module;
                                      progress = moduleProgress;
                                      break;
                                    }
                                  }
                                  if (targetModule == null &&
                                      _modules.isNotEmpty) {
                                    targetModule = _modules.last;
                                    progress =
                                        _moduleProgress[targetModule['id']] ??
                                        0.0;
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
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 24 * AppTheme.fontSizeScale,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                // Modules Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Modules'.toTitleCase(),
                      style: theme.textTheme.headlineSmall,
                    ),
                    Builder(
                      builder: (context) {
                        // Count completed modules (100% progress)
                        final completedCount =
                            _modules
                                .where(
                                  (module) =>
                                      (_moduleProgress[module['id']] ?? 0.0) >=
                                      100,
                                )
                                .length;

                        return Text(
                          '${completedCount}/${_modules.length} Completed'.toTitleCase(),
                          style: theme.textTheme.labelMedium,
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Show loading or modules
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_modules.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _currentClass == null
                            ? 'No class assigned'
                            : 'No modules available',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  )
                else
                  // Dynamic modules list
                  ..._modules.asMap().entries.map((entry) {
                    final index = entry.key;
                    final module = entry.value;
                    final isUnlocked =
                        index == 0 ||
                        (_moduleProgress[_modules[index - 1]['id']] ?? 0) >=
                            100;
                    final progress = _moduleProgress[module['id']] ?? 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: _buildModuleCard(
                        context: context,
                        module: module,
                        moduleId: module['id'],
                        title: module['title'] ?? 'Module ${index + 1}',
                        isUnlocked: isUnlocked,
                        progress: progress,
                        dragonIcon: _getDragonPhaseIcon(module['id']),
                        iconColor: primary,
                        unlockRequirement:
                            index > 0
                                ? 'Complete ${_modules[index - 1]['title'] ?? 'previous module'}'
                                : null,
                        onTap: () {
                          if (isUnlocked) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        LessonPage(moduleId: module['id']),
                              ),
                            ).then((_) {
                              // Reload data when returning from the lesson page
                              _loadClassData();
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required Map<String, dynamic> module,
    required String moduleId,
    required String title,
    required bool isUnlocked,
    required double progress,
    required Widget dragonIcon,
    required Color iconColor,
    required VoidCallback onTap,
    String? unlockRequirement,
  }) {
    // Get actual progress for this module
    final actualProgress = _moduleProgress[moduleId] ?? 0.0;

    // Check if this module should be unlocked
    final int currentIndex = _modules.indexOf(module);
    bool shouldBeUnlocked = false;
    String? newUnlockRequirement;

    // Handle settings card specially
    if (moduleId == 'settings') {
      shouldBeUnlocked = false;
    } else if (currentIndex == 0) {
      // First module is always unlocked
      shouldBeUnlocked = true;
    } else if (currentIndex > 0) {
      // Check if previous module is completed
      final previousModule = _modules[currentIndex - 1];
      final previousProgress = _moduleProgress[previousModule['id']] ?? 0.0;
      shouldBeUnlocked = previousProgress >= 100;
      if (!shouldBeUnlocked) {
        newUnlockRequirement =
            'Complete ${previousModule['title'] ?? 'previous module'} (${previousProgress.toStringAsFixed(0)}%)';
      }
    }

    ThemeData theme = Theme.of(context);

    final Color primary = theme.colorScheme.primary;
    final Color secondary = theme.colorScheme.secondary;
    final Color tertiary = theme.colorScheme.tertiary;
    final Color cardBg = theme.colorScheme.surfaceContainerLowest;
    final Color lockedBg = theme.colorScheme.surfaceContainerHigh;
    final Color textColor = theme.colorScheme.onSurface;
    final Color mutedTextColor = theme.colorScheme.onSurfaceVariant;
    final double borderRadius = 24.0;

    // Get quiz info for this module from module data
    final hasPreQuiz = module['pre_quiz'] != null;
    final hasPostQuiz = module['post_quiz'] != null;
    final description =
        moduleId == 'settings'
            ? 'Configure your app settings'
            : 'Learn about $title';

    return GestureDetector(
      onTap: shouldBeUnlocked ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(borderRadius),
          border:
              shouldBeUnlocked
                  ? null
                  : Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
          boxShadow:
              shouldBeUnlocked
                  ? [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          children: [
            Text(
              title.toTitleCase(),
              style: theme.textTheme.headlineSmall,
            ),
            if (!shouldBeUnlocked &&
                (newUnlockRequirement != null ||
                    unlockRequirement != null)) ...[
              const SizedBox(height: 4),
              Text(
                newUnlockRequirement ?? unlockRequirement ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (shouldBeUnlocked && moduleId != 'settings') ...[
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
              // const SizedBox(height: 8),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     if (hasPreQuiz)
              //       Container(
              //         padding: const EdgeInsets.symmetric(
              //           horizontal: 8,
              //           vertical: 4,
              //         ),
              //         decoration: BoxDecoration(
              //           color: primary.withValues(alpha: 0.1),
              //           borderRadius: BorderRadius.circular(12),
              //         ),
              //         child: Row(
              //           mainAxisSize: MainAxisSize.min,
              //           children: [
              //             Icon(Icons.quiz, size: 16, color: primary),
              //             const SizedBox(width: 4),
              //             Text(
              //               'Pre-Quiz',
              //               style: GoogleFonts.poppins(
              //                 fontSize: 12 * AppTheme.fontSizeScale,
              //                 color: primary,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     if (hasPreQuiz && hasPostQuiz) const SizedBox(width: 8),
              //     if (hasPostQuiz)
              //       Container(
              //         padding: const EdgeInsets.symmetric(
              //           horizontal: 8,
              //           vertical: 4,
              //         ),
              //         decoration: BoxDecoration(
              //           color: primary.withValues(alpha: 0.1),
              //           borderRadius: BorderRadius.circular(12),
              //         ),
              //         child: Row(
              //           mainAxisSize: MainAxisSize.min,
              //           children: [
              //             Icon(Icons.assignment, size: 16, color: primary),
              //             const SizedBox(width: 4),
              //             Text(
              //               'Post-Quiz',
              //               style: GoogleFonts.poppins(
              //                 fontSize: 12 * AppTheme.fontSizeScale,
              //                 color: primary,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //   ],
              // ),
            ],
            const SizedBox(height: 16),
            // Semi-circular progress bar with icon
            SizedBox(
              height: 100,
              width: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Semi-circular progress
                  if (shouldBeUnlocked && moduleId != 'settings')
                    CustomPaint(
                      size: const Size(160, 80),
                      painter: _SemiCircleProgressPainter(
                        color: secondary,
                        progress: actualProgress / 100,
                      ),
                    ),
                  // Icon in circle
                  shouldBeUnlocked && moduleId != 'settings'
                      ? Positioned(top: 35, child: dragonIcon)
                      : Positioned(
                        top: 10,
                        child: Image.asset(
                          'assets/images/other/lock.png',
                          width: 96,
                          height: 96,
                          color: mutedTextColor.withOpacity(0.5),
                        ),
                      ),
                ],
              ),
            ),
            if (shouldBeUnlocked && moduleId != 'settings') ...[
              Text(
                '${actualProgress.toStringAsFixed(0)}% Complete',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: secondary,
                )
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Custom painter for semi-circular progress bar
class _SemiCirclePainter extends CustomPainter {
  final Color color;
  _SemiCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = 16
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    canvas.drawArc(rect, 3.14, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for semi-circular progress bar with progress
class _SemiCircleProgressPainter extends CustomPainter {
  final Color color;
  final double progress;

  _SemiCircleProgressPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Background arc
    final Paint backgroundPaint =
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Progress arc
    final Paint progressPaint =
        Paint()
          ..color = color.withValues(alpha: 0.75)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    // Draw background arc (full semi-circle)
    canvas.drawArc(rect, 3.14159, 3.14159, false, backgroundPaint);

    // Draw progress arc (partial semi-circle based on progress)
    if (progress > 0) {
      canvas.drawArc(rect, 3.14159, 3.14159 * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SemiCircleProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
