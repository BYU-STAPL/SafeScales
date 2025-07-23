import 'package:flutter/material.dart';
import 'package:safe_scales/services/class_service.dart';
import 'package:safe_scales/services/quiz_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/state_management/dragon_state_manager.dart';
import 'package:safe_scales/ui/screens/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/models/question.dart';
import 'package:safe_scales/ui/screens/post_quiz/post_quiz_screen.dart';
import 'package:safe_scales/ui/screens/review_set/review_screen.dart';

// ##################################################
/*
This page for develop purposes only to test different screens and other widgets
This will be removed after development
 */
// ##################################################


class DevTestingPage extends StatefulWidget {
  const DevTestingPage({
    super.key,
  });

  @override
  State<DevTestingPage> createState() => _DevTestingPageState();
}

class _DevTestingPageState extends State<DevTestingPage> {
  final QuizService _quizService = QuizService();
  final _userState = UserStateService();
  final _dragonStateManager = DragonStateManager();
  late final ClassService _classService;

  // Class-based variables
  Map<String, dynamic>? _currentClass;
  List<Map<String, dynamic>> _modules = [];
  List<String> _moduleIds = [];

  Map<String, double> _moduleProgress = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _classService = ClassService(_quizService.supabase);
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
          _moduleIds = moduleIds;
        });

        // Update dragon phases based on current progress
        // await _updateDragonPhases();
      }
    } catch (e) {
      print('❌ Error loading class data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    print(_moduleIds);

    Question singleQ = Question.singleAnswer(
      id: 'q1',
      questionText: 'What color is the sky?',
      options: ['Red', 'Blue', 'Green', 'Yellow'],
      correctAnswerIndex: 1,
      explanation: 'The Sky is blue', // Blue is at index 1
    );

    Question singleQ2 = Question.singleAnswer(
      id: 'q2',
      questionText: 'What season are oranges ripe?',
      options: ['Spring', 'Summer', 'Fall', 'Winter', "Year-round"],
      correctAnswerIndex: 3,
      explanation: 'Oranges taste best during the winter',
    );

    Question multipleQ = Question.multipleAnswer(
      id: 'q3',
      text: "At your school, there is a security guard named Quinn. You have never met or talked to Quinn, but some of your school mates have."
          "At your school, there is a security guard named Quinn. At your school, there is a security guard named Quinn."
          "At your school, there is a security guard named Quinn. At your school, there is a security guard named Quinn. "
          "At your school, there is a security guard named Quinn. At your school, there is a security guard named Quinn.",
      questionText: 'What social tag(s) apply to Quinn?',
      options: ['Acquaintance', 'Community Helper', 'Stranger', 'Work Peer', 'In-Person Friend', 'Family'],
      correctAnswerIndices: [1, 2,],
      explanation: 'Quinn serves the community, but don\'t know him', // Apple, Banana, Orange
    );

    QuestionSet questionSet = QuestionSet(
      id: "qset0",
      title: "Test Question Set",
      description: "This is a test",
      activityType: ActivityType.preQuiz,
      subject: "test subject",
      questions: [singleQ, multipleQ],
    );

    QuestionSet questionSet2 = QuestionSet(
      id: "qset2",
      title: "Test Post Quiz",
      description: "This is a post-test",
      activityType: ActivityType.postQuiz,
      subject: "test subject",
      questions: [singleQ, singleQ2, multipleQ,],
    );

    QuestionSet questionSet3 = QuestionSet(
      id: "qset3",
      title: "Review",
      description: "This is a review set",
      activityType: ActivityType.review,
      subject: "review subject",
      questions: [multipleQ,],
    );


    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 50),

            ElevatedButton(
              onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PreQuizScreen(moduleId: _moduleIds[0], questionSet: questionSet)
                    ),
                  );
                },
              child: Text("Testing Pre-quiz"),
            ),

            SizedBox(height: 50),

            ElevatedButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PostQuizScreen(moduleId: _moduleIds[0], questionSet: questionSet2)
                  ),
                );
              },
              child: Text("Testing Post-quiz"),
            ),

            SizedBox(height: 50),


            ElevatedButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ReviewScreen(questionSet: questionSet3)
                  ),
                );
              },
              child: Text("Testing Review set"),
            ),
          ],
        ),
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}