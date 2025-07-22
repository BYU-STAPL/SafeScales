import 'package:flutter/material.dart';
import 'package:safe_scales/extensions/string_extensions.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/class_service.dart';
import 'package:safe_scales/ui/widgets/lesson_card.dart';
import 'package:safe_scales/state_management/dragon_state_manager.dart';

import '../widgets/continue_learning_widget.dart';
import 'lesson/lesson_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final QuizService _quizService = QuizService();
  final _userState = UserStateService();
  final _dragonStateManager = DragonStateManager();
  late final ClassService _classService;

  // Class-based variables
  Map<String, dynamic>? _currentClass;
  List<Map<String, dynamic>> _modules = [];
  Map<String, double> _moduleProgress = {};

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

      // Initialize dragon state manager and load user dragons
      await _dragonStateManager.initialize();
      await _dragonStateManager.loadUserDragons();

      if (mounted) {
        setState(() {
          _currentClass = classData;
          _modules = modules;
          _moduleProgress = moduleProgress;
          _isLoading = false;
        });

        // Update dragon phases based on current progress
        await _updateDragonPhases();
      }
    } catch (e) {
      print('❌ Error loading class data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Update dragon phases based on module progress
  Future<void> _updateDragonPhases() async {
    try {
      final user = _userState.currentUser;
      if (user == null) return;

      // Get current dragons data from database
      final response = await _quizService.supabase
          .from('Users')
          .select('dragons')
          .eq('id', user.id)
          .single();

      Map<String, dynamic> dragons = {};
      if (response['dragons'] != null) {
        dragons = Map<String, dynamic>.from(response['dragons']);
      }

      bool hasChanges = false;

      // Update phases for each module
      for (var module in _modules) {
        final moduleId = module['id'] as String;
        final progress = _moduleProgress[moduleId] ?? 0.0;

        // Find the dragon for this module
        final dragon = _dragonStateManager.getDragonByModuleId(moduleId);
        if (dragon == null) continue;

        // Calculate phases based on progress
        List<String> phases = ['egg']; // Always start with egg

        if (progress >= 30) {
          phases.add('baby'); // Add baby phase
        }
        if (progress >= 50) {
          phases.add('teen'); // Add teen phase
        }
        if (progress >= 80) {
          phases.add('adult'); // Add final phase
        }

        // Check if phases have changed
        final currentPhases = dragons[dragon.id] as List<dynamic>?;
        if (currentPhases == null ||
            !_areListsEqual(currentPhases.cast<String>(), phases)) {
          dragons[dragon.id] = phases;
          hasChanges = true;
        }
      }

      // Save updated dragons data if there are changes
      if (hasChanges) {
        await _quizService.supabase
            .from('Users')
            .update({'dragons': dragons})
            .eq('id', user.id);

        // Reload dragon state to reflect changes
        await _dragonStateManager.loadUserDragons();

        print('✅ Successfully updated dragon phases');
      }
    } catch (e) {
      print('❌ Error updating dragon phases: $e');
    }
  }

  /// Helper method to compare two lists
  bool _areListsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                          builder: (context) => LessonPage(moduleId: targetModule!['id']),
                        ),
                      );
                    },
                    child: ContinueLearningWidget(modules: _modules, moduleProgress: _moduleProgress),
                  ),
                const SizedBox(height: 30),


                // Lesson Heading
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lessons'.toTitleCase(),
                      style: theme.textTheme.headlineSmall,
                    ),
                    Builder(
                      builder: (context) {
                        // Count completed modules (100% progress)
                        final completedCount = _modules
                            .where((module) => (_moduleProgress[module['id']] ?? 0.0) >= 100)
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


                // Show loading or lesson List
                if (_isLoading || _dragonStateManager.isLoading)
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
                        _currentClass == null ? 'No class assigned' : 'No modules available',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  )
                else
                // Dynamic modules list
                  ..._modules.asMap().entries.map((entry) {

                    final index = entry.key;
                    final module = entry.value;
                    final moduleId = module['id'] as String;
                    final title = module['title'] ?? 'Module ${index + 1}';
                    final actualProgress = _moduleProgress[moduleId] ?? 0.0;

                    // Calculate unlock status
                    bool shouldBeUnlocked = false;
                    String? newUnlockRequirement;

                    if (index == 0) {
                      shouldBeUnlocked = true;
                    } else if (index > 0) {
                      final previousModule = _modules[index - 1];
                      final previousProgress = _moduleProgress[previousModule['id']] ?? 0.0;
                      shouldBeUnlocked = previousProgress.round() >= 100;
                      if (!shouldBeUnlocked) {
                        newUnlockRequirement =
                        'Complete ${previousModule['title'] ?? 'previous module'} (${previousProgress.toStringAsFixed(0)}%)';
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: LessonCard(
                        moduleId: moduleId,
                        title: title,
                        description: 'Learn about $title',
                        actualProgress: actualProgress,
                        shouldBeUnlocked: shouldBeUnlocked,
                        newUnlockRequirement: newUnlockRequirement,
                        unlockRequirement: index > 0
                            ? 'Complete ${_modules[index - 1]['title'] ?? 'previous module'}'
                            : null,
                        onTapCard: () {
                          if (shouldBeUnlocked) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LessonPage(moduleId: moduleId),
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


}

