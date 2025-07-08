import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/services/class_service.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/lesson/lesson_page.dart';

import '../main_navigation.dart';

class PostQuizActionsScreen extends StatefulWidget {
  const PostQuizActionsScreen({
    super.key,
    required this.passingScore,
    required this.score,
  });

  final int passingScore;
  final int score;

  @override
  State<PostQuizActionsScreen> createState() => _PostQuizActionsScreenState();
}

class _PostQuizActionsScreenState extends State<PostQuizActionsScreen> {
  final ClassService _classService = ClassService(QuizService().supabase);
  final UserStateService _userState = UserStateService();
  final QuizService _quizService = QuizService();

  Map<String, dynamic>? _currentClass;
  List<Map<String, dynamic>> _modules = [];
  Map<String, double> _moduleProgress = {};
  String? _nextModuleId;

  @override
  void initState() {
    super.initState();
    _loadClassAndModuleData();
  }

  Future<void> _loadClassAndModuleData() async {
    try {
      final user = _userState.currentUser;
      if (user == null) return;

      // Get current class
      final classResponse = await _classService.getUserClass(user.id);
      if (classResponse.isNotEmpty) {
        setState(() {
          _currentClass = classResponse;
        });

        // Get modules for this class
        final classId = classResponse['id'];
        if (classId != null) {
          final modules = await _classService.getClassModules(classId);
          setState(() {
            _modules = modules;
          });

          // Get module progress
          final moduleIds = modules.map((m) => m['id'] as String).toList();
          final progress = await _quizService.getModuleProgress(
            userId: user.id,
            moduleIds: moduleIds,
          );
          setState(() {
            _moduleProgress = progress;
          });

          // Find next incomplete module
          _findNextModule();
        }
      }
    } catch (e) {
      print('Error loading class and module data: $e');
    }
  }

  void _findNextModule() {
    for (var module in _modules) {
      final progress = _moduleProgress[module['id']] ?? 0.0;
      if (progress < 100) {
        setState(() {
          _nextModuleId = module['id'];
        });
        return;
      }
    }
    // If all modules are complete, set to last module
    if (_modules.isNotEmpty) {
      setState(() {
        _nextModuleId = _modules.last['id'];
      });
    }
  }

  void _navigateToNextModule() {
    if (_nextModuleId != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LessonPage(moduleId: _nextModuleId!),
        ),
        (route) => false, // Remove all previous routes
      );
    } else {
      // Fallback to home page if no next module found
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigation(initialIndex: 0),
        ),
        (route) => false,
      );
    }
  }

  Widget _buildDragonAction(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(height: 30),

        Text(
          'Your dragon is fully grown!',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        SizedBox(height: 30),

        // TODO: Replace later with dragon
        Image.asset("assets/images/other/QuestionMark.png"),

        SizedBox(height: 30),

        Text(
          'Now you can play with your dragon by going to the dragon screen',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),

        TextButton.icon(
          onPressed: () {
            // Go to Dragon Page
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        MainNavigation(initialIndex: 1), // Index of desired tab
              ),
              (route) => false, // Remove all previous routes
            );
          },
          icon: FaIcon(FontAwesomeIcons.dragon),
          label: Text(
            'Dragon',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),

        SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSuggestedAction(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(height: 30),

        Container(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Quiz Score'),
                Text(
                  '${widget.score}%',
                  style: TextStyle(
                    fontSize: 40 * AppTheme.fontSizeScale,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.orange,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 30),

        Text("Suggested Action", style: theme.textTheme.headlineMedium),

        SizedBox(height: 20),

        //TODO: Implement these buttons
        widget.score >= 50
            ? ElevatedButton(
              onPressed: null,
              child: Text("Retake Quiz".toUpperCase()),
            )
            : ElevatedButton(
              onPressed: null,
              child: Text("Re-read".toUpperCase()),
            ),

        SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Results')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            children: [
              // Show dragon action if passed, suggested action if failed
              widget.score >= widget.passingScore
                  ? _buildDragonAction(context)
                  : _buildSuggestedAction(context),

              Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.score >= widget.passingScore &&
                        _nextModuleId != null) {
                      // If passed and there's a next module, navigate to it
                      _navigateToNextModule();
                    } else {
                      // Otherwise return to lesson page
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text(
                    widget.score >= widget.passingScore && _nextModuleId != null
                        ? 'Continue to Next Module'.toUpperCase()
                        : 'Return to lesson'.toUpperCase(),
                    style: TextStyle(
                      fontSize: theme.textTheme.bodyMedium?.fontSize,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
