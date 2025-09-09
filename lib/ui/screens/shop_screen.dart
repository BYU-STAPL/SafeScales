import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/providers/shop_provider.dart';
import 'dart:convert';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/repositories/shop_repository.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/ui/screens/review_set/review_screen.dart';
import 'package:safe_scales/models/question.dart';

import '../../models/lesson.dart';
import '../../models/sticker_item_model.dart';
import '../../providers/course_provider.dart';
import '../widgets/shop_item_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  final ShopRepository _shopRepository = ShopRepository();
  final UserStateService _userState = UserStateService();


  int selectedTab = 0; // 0 = Accessories, 1 = Environments
  int? selectedIndex; // Track selected item index
  String? selectedLessonIndex; // Track selected lesson in popup


  bool showLessonDialog = false;
  List<Map<String, dynamic>> accessories = [];
  List<Map<String, dynamic>> environments = [];
  bool isLoading = true;
  List<String> acquiredAccessories = [];
  List<String> acquiredEnvironments = [];
  Map<String, Map<String, dynamic>> quizDetails = {};
  Map<String, Map<String, dynamic>> moduleDetails = {};

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // _loadItems();
    // _reloadUserProfile();

    // Use addPostFrameCallback to ensure initialization happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;

    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    try {
      // Only initialize if not already initialized
      // Since AppDependencies already calls initialize(), we might not need this
      if (!shopProvider.isLoading) {
        await shopProvider.initialize();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  Future<void> _handlePurchase() async {
    if (selectedIndex == null) return;

    // User can't see shop unless logged in
    // final userId = _userState.currentUser?.id;
    // if (userId == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please log in to purchase items')),
    //   );
    //   return;
    // }

    // Show completed modules popup first
    setState(() {
      showLessonDialog = true;
      selectedLessonIndex = null;
    });
  }

  // Future<void> _completePurchase() async {
  //   if (selectedIndex == null || selectedLessonIndex == null) return;
  //
  //   final userId = _userState.currentUser?.id;
  //   if (userId == null) return;
  //
  //   try {
  //     // Hide module selection dialog before starting the revision quiz
  //     setState(() {
  //       showLessonDialog = false;
  //     });
  //
  //     // Start the revision quiz for the selected module
  //     final bool passedRevision = await _startRevisionQuiz(
  //       selectedLessonIndex!,
  //     );
  //
  //     if (!mounted) return;
  //
  //     if (!passedRevision) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Review set not completed. Purchase cancelled.'),
  //         ),
  //       );
  //       setState(() {
  //         selectedLessonIndex = null;
  //       });
  //       return;
  //     }
  //
  //     // Proceed with the purchase after successful revision
  //     bool purchaseSuccess;
  //     if (selectedTab == 0) {
  //       purchaseSuccess = await _shopRepository.purchaseAccessory(
  //         userId,
  //         accessories[selectedIndex!]['id'].toString(),
  //       );
  //     } else {
  //       purchaseSuccess = await _shopRepository.purchaseEnvironment(
  //         userId,
  //         environments[selectedIndex!]['id'].toString(),
  //       );
  //     }
  //
  //     if (purchaseSuccess) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text('Purchase successful!')));
  //       // await _loadItems();
  //       // TODO: Create Refresh
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Failed to complete purchase')),
  //       );
  //     }
  //
  //     setState(() {
  //       selectedLessonIndex = null;
  //     });
  //   } catch (e) {
  //     print('❌Error during purchase: $e');
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
  //   }
  // }

  Future<void> _completePurchase() async {
    if (selectedIndex == null || selectedLessonIndex == null) return;

    final userId = _userState.currentUser?.id;
    if (userId == null) return;

    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    try {
      // Hide module selection dialog before starting the revision quiz
      setState(() {
        showLessonDialog = false;
      });

      // Start the revision quiz for the selected module
      final bool passedRevision = await _startRevisionQuiz(
        selectedLessonIndex!,
      );

      if (!mounted) return;

      if (!passedRevision) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review set not completed. Purchase cancelled.'),
          ),
        );
        setState(() {
          selectedLessonIndex = null;
        });
        return;
      }

      // Proceed with the purchase using the provider
      final PurchaseResult result = await shopProvider.purchaseItemByIndex(
        selectedIndex!,
        selectedTab == 1, // true for environments, false for items
      );

      if (!mounted) return;

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );

        // Reset selected index since the item is no longer available
        setState(() {
          selectedIndex = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }

      setState(() {
        selectedLessonIndex = null;
      });
    } catch (e) {
      debugPrint('Error during purchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );

      setState(() {
        selectedLessonIndex = null;
      });
    }
  }

  Future<bool> _startRevisionQuiz(String moduleId) async {
    try {
      final moduleResponse =
          await SupabaseConfig.client
              .from('modules')
              .select('id, title, revision_questions')
              .eq('id', moduleId)
              .single();

      final questionSet = _parseRevisionQuestionsToQuestionSet(moduleResponse);

      bool result = false;

      ShopProvider shopProvider = Provider.of<ShopProvider>(context, listen: false);
      Item? selectedItem = shopProvider.getItemByIndex(selectedIndex!, selectedTab == 1);

      if (questionSet.questions.isEmpty) {

        //TODO: Remove after testing
        QuestionSet testingSet = QuestionSet(
            id: "id",
            title: "test",
            description: "description...",
            activityType: ActivityType.review,
            subject: "subject",
            questions: [
              Question(id: "id", questionText: "Pick A", options: ['a', 'b'], correctAnswerIndices: [0], isMultipleAnswer: true, explanation: 'a is right'),
            ]
        );

        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewScreen(questionSet: testingSet, image: selectedItem?.imageUrl),
          ),
        );

        //TODO: Put back after testing
        /*
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'The Teacher has not created a review set for this lesson',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
            ),
            backgroundColor:
            Theme.of(context).colorScheme.inverseSurface,
          ),
        );
        */
      }
      else {
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewScreen(questionSet: questionSet),
          ),
        );
      }

      // ReviewScreen returns true on completion
      return result == true;
    } catch (e) {
      print('❌Error starting revision quiz: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load revision questions')),
      );
      return false;
    }
  }

  QuestionSet _parseRevisionQuestionsToQuestionSet(Map<String, dynamic> module,) {
    final String moduleId = module['id'].toString();
    final String title = (module['title'] ?? 'Module Review').toString();
    final String subject = 'General';

    dynamic revision = module['revision_questions'];
    if (revision is String) {
      try {
        revision =
            revision.isNotEmpty
                ? (revision == 'null' ? {} : jsonDecode(revision))
                : {};
      } catch (_) {
        revision = {};
      }
    }

    final List<dynamic> rawQuestions =
        (revision is Map<String, dynamic>)
            ? List<dynamic>.from(revision['questions'] ?? [])
            : (revision is List)
            ? revision
            : <dynamic>[];

    final List<Question> questions = [];
    for (int i = 0; i < rawQuestions.length; i++) {
      final q = rawQuestions[i] as Map<String, dynamic>;
      final String questionText = (q['question'] ?? '').toString();
      final List<String> options = List<String>.from(
        q['choices']?.map((c) => c.toString()) ?? [],
      );
      // answer could be a string index like "0" or an int
      final dynamic answerRaw = q['answer'];
      int correctIndex = 0;
      if (answerRaw is int) {
        correctIndex = answerRaw;
      } else if (answerRaw is String) {
        correctIndex = int.tryParse(answerRaw) ?? 0;
      }

      questions.add(
        Question.singleAnswer(
          id: 'q_$i',
          questionText: questionText,
          options: options,
          correctAnswerIndex: correctIndex,
          explanation: '',
        ),
      );
    }

    return QuestionSet(
      id: 'rev_$moduleId',
      title: '$title Review',
      description: 'Answer the review questions to unlock your item.',
      activityType: ActivityType.review,
      subject: subject,
      passingScore: 0,
      showResults: false,
      showCorrectAnswers: true,
      showExplanations: false,
      allowRetakes: true,
      questions: questions,
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final Color primary = Theme.of(context).colorScheme.primary;
    final Color selected = primary;
    final Color unselected = theme.colorScheme.lightBlue.withValues(alpha: 0.5,);
    final Color selectedText = Colors.white;
    final Color unselectedText = primary;
    final Color highlight = theme.colorScheme.green.withValues(alpha: 0.25);

    return Consumer2<ShopProvider, CourseProvider>(
      builder: (context, shopProvider, courseProvider, child) {

        final items = selectedTab == 0 ?  shopProvider.availableItems : shopProvider.availableEnvironments;

        return Stack(
          children: [
            Scaffold(
              key: _scaffoldKey,
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          // Subtitle
                          Expanded(
                            child: Text(
                              'Earn new items and environments for your dragons by completing review sets from finished lessons.',
                              style: theme.textTheme.labelMedium,
                            ),
                          ),

                          // Refresh button
                          Consumer<ShopProvider>(
                            builder: (context, shopProvider, child) {
                              return IconButton(
                                onPressed: shopProvider.isLoading
                                    ? null
                                    : () => shopProvider.refresh(),
                                icon: shopProvider.isLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : const Icon(Icons.refresh),
                                tooltip: 'Refresh items',
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      // Toggle Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  () => setState(() {
                                selectedTab = 0;
                                selectedIndex = null;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedTab == 0 ? selected : unselected,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'ITEMS (${shopProvider.availableItems.length})'.toUpperCase(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                      selectedTab == 0
                                          ? selectedText
                                          : unselectedText,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  () => setState(() {
                                selectedTab = 1;
                                selectedIndex = null;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedTab == 1 ? selected : unselected,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'ENVIRONMENTS (${shopProvider.availableEnvironments.length})'.toUpperCase(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                      selectedTab == 1
                                          ? selectedText
                                          : unselectedText,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Shop Items Grid
                      Expanded(
                        child:
                        // isLoading
                        //     ? const Center(child: CircularProgressIndicator()) :
                        GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          childAspectRatio: 0.95,
                          children: [
                            for (int i = 0; i < items.length; i++)
                              ShopItemCard(
                                image: items[i].imageUrl,
                                name: items[i].name,
                                cost: items[i].cost.toString() ?? '1',
                                isSelected: selectedIndex == i,
                                // isOwned:
                                // selectedTab == 0 ? acquiredAccessories.contains(items[i].id.toString(),)
                                //     : acquiredEnvironments.contains(items[i]['id'].toString(),),
                                highlight: highlight,
                                onTap: () {
                                  setState(() {
                                    selectedIndex = i;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      if (selectedIndex != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: _handlePurchase,
                              child: Text(
                                'PURCHASE'.toUpperCase(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (showLessonDialog)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => showLessonDialog = false),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select a lesson to review',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontSize: 18 * AppTheme.fontSizeScale,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.5,
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                children:
                                  courseProvider.getAllCompletedLessons().map((lesson) {
                                    return _buildLessonCardForReview(lesson);
                                  }).toList(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed:
                                      () =>
                                      setState(() => showLessonDialog = false),
                                  child: Text(
                                    'CANCEL'.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14 * AppTheme.fontSizeScale,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed:
                                  selectedLessonIndex != null
                                      ? () {
                                    _completePurchase();
                                  }
                                      : null,
                                  child: Text('SELECT'.toUpperCase()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );

  }

  GestureDetector _buildLessonCardForReview(Lesson lesson) {

    ThemeData theme = Theme.of(context);
    Color selectionColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLessonIndex = lesson.lessonId;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color:
              selectedLessonIndex == lesson.lessonId
                  ? selectionColor.withValues(
                    alpha: 0.12,
                  )
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                selectedLessonIndex == lesson.lessonId
                    ? selectionColor
                    : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              lesson.title,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

