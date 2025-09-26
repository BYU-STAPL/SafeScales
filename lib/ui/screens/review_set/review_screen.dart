import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/extensions/string_extensions.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/ui/screens/review_set/review_results_screen.dart';

import '../../../providers/shop_provider.dart';
import '../../widgets/progress_bar.dart';
import '../../../models/question.dart';
import '../../widgets/question_widget.dart';
import '../../widgets/shop_item_card.dart';

class ReviewScreen extends StatefulWidget {
  final QuestionSet questionSet;
  String? image;
  final bool needToShowShop;

  ReviewScreen({
    super.key, required this.questionSet, this.image, required this.needToShowShop,
  });

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int currentQuestionIndex = 0;
  List<List<int>> userAnswers = [];
  bool isStarted = false;

  bool isCurrentQuestionCorrect = false;
  List<List<List<int>>> attempts = [];

  bool isResponseLocked = false;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    userAnswers = List.generate(widget.questionSet.questions.length, (_) => []);
    attempts = List.generate(widget.questionSet.questions.length, (_) => []);

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

  void _startReview() {
    setState(() {
      isStarted = true;
    });
  }

  void _finishReview() async {

    if (!mounted) return;

    // if (widget.isComingFromShopRoute) {
      // Show results screen and then return to previous screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ReviewResultsScreen(
                image: widget.image,
                needToShowShop: widget.needToShowShop,
          ),
        ),
      );
    // }
    // else {
      // Show the item selection dialog then the results
      // _openShopPopUp();
    // }

    if (!mounted) return;

    // Return to previous screen with completion status
    Navigator.pop(context, true);
  }

  // Future<void> _openShopPopUp() async {
  //   //TODO: Not working need to think more about this
  //   // TODO: Maybe the results screen should show a shop if no image is given
  //
  //   print("DEBUG: Open shop popup");
  //
  //   final shopProvider = Provider.of<ShopProvider>(context, listen: false);
  //
  //   final items = shopProvider.availableItems;
  //
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("Pick a Reward"),
  //         content: Expanded(
  //           child: GridView.count(
  //             crossAxisCount: 2,
  //             mainAxisSpacing: 20,
  //             crossAxisSpacing: 20,
  //             childAspectRatio: 0.95,
  //             children: [
  //               for (int i = 0; i < items.length; i++)
  //                 ShopItemCard(
  //                   image: items[i].imageUrl,
  //                   name: items[i].name,
  //                   cost: items[i].cost.toString() ?? '1',
  //                   isSelected: false, //selectedIndex == i,
  //                   highlight: Theme.of(context).colorScheme.green.withValues(alpha: 0.25),
  //                   onTap: () {
  //                     // setState(() {
  //                     //   selectedIndex = i;
  //                     // });
  //                   },
  //                 ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(); // Close dialog
  //             },
  //             child: const Text("Cancel"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //
  //               // TODO: Add handle purchase logic like in shop
  //
  //
  //               // Set widget.image to the item
  //
  //               Navigator.of(context).pop(); // Close dialog
  //             },
  //             child: const Text("Save Choice"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  bool _isAnswerCorrect(int questionIndex) {
    final question = widget.questionSet.questions[questionIndex];
    final userAnswer = userAnswers[questionIndex];

    if (userAnswer.length != question.correctAnswerIndices.length) return false;

    final sortedUser = List<int>.from(userAnswer)..sort();
    final sortedCorrect = List<int>.from(question.correctAnswerIndices)..sort();

    for (int i = 0; i < sortedUser.length; i++) {
      if (sortedUser[i] != sortedCorrect[i]) return false;
    }
    return true;
  }

  void _checkQuestion() {
    setState(() {
      attempts[currentQuestionIndex].add(userAnswers[currentQuestionIndex]);
    });

    if (_isAnswerCorrect(currentQuestionIndex)) {
      setState(() {
        isCurrentQuestionCorrect = true;
        // showAnswerMessage = true; // Currently using snack-bar function: showAnswerCheckMessage
        isResponseLocked = true;
      });
    }
    else {
      isCurrentQuestionCorrect = false;
      setState(() {
        isCurrentQuestionCorrect = false;
        // showAnswerMessage = true;
        isResponseLocked = false;
      });
    }

    showAnswerCheckMessage();

  }


  void _nextQuestion() {
    if (currentQuestionIndex < widget.questionSet.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        isCurrentQuestionCorrect = false;
        // showAnswerMessage = false;
        isResponseLocked = false;
      });
    } else {
      _finishReview();
    }
  }

  Container _buildNavigationBar() {

    ThemeData theme = Theme.of(context);

    //Decide what button to show and what function
    String forwardButtonText = 'Next';

    if (!isCurrentQuestionCorrect) {
      // Show check if not correct
      forwardButtonText = 'Check';

    }
    else if (currentQuestionIndex == widget.questionSet.questions.length - 1) {
      // Answer is correct, check if at end of review set
      forwardButtonText = 'Complete';
    }
    forwardButtonText.toTitleCase();


    //Decide what button function if user has an answer selected
    Function() onForwardTap;

    if (!isCurrentQuestionCorrect) {
      // Check Question if not correct
      onForwardTap = _checkQuestion;
    }
    else {
      onForwardTap = _nextQuestion;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Spacer(),

          TextButton.icon(
            iconAlignment: IconAlignment.end,
            onPressed: userAnswers[currentQuestionIndex].isNotEmpty ? onForwardTap : null,
            label: Text(
                forwardButtonText
            ),
            icon: Icon(Icons.arrow_forward_ios_rounded),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    AppBar appBar = AppBar(centerTitle: true, title: Text('Review Set'));

    if (!isStarted) {
      return Scaffold(
        appBar: appBar,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.questionSet.title,
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: 15),

              Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: theme.colorScheme.secondary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${widget.questionSet.questions.length} questions',
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.secondary,
                          ),
                          SizedBox(width: 8),
                          Expanded(child: Text(widget.questionSet.description)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _startReview();
                  },
                  child: Text(
                    'Start'.toUpperCase(),
                    style: TextStyle(
                      fontSize: theme.textTheme.bodyLarge?.fontSize,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      );
    }

    final progress = (currentQuestionIndex + 1) / widget.questionSet.questions.length;


    return Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          return Scaffold(
            appBar: appBar,
            body: Column(
              children: [

                ProgressBar(
                  progress: progress,
                  currentSlideIndex: currentQuestionIndex,
                  slideLength: widget.questionSet.questions.length,
                  slideName: 'questions',
                ),

                // showAnswerMessage ? _buildAnswerCheckCard() : SizedBox.shrink(),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: QuestionWidget(
                      question: widget.questionSet.questions[currentQuestionIndex],
                      selectedAnswers: userAnswers[currentQuestionIndex],
                      onAnswerChanged: (answers) {
                        setState(() {
                          userAnswers[currentQuestionIndex] = answers;
                        });
                      },
                      showCorrectAnswer: widget.questionSet.showCorrectAnswers,
                      showExplanation: widget.questionSet.showExplanations,
                      isResponseLocked: isResponseLocked,
                    ),
                  ),
                ),

                _buildNavigationBar(),

                SizedBox(height: 20),
              ],
            ),
          );
        }
    );


  }

  void showAnswerCheckMessage() {

    ThemeData theme = Theme.of(context);

    // Secondary Color is green, so correct -> green
    Color color = isCurrentQuestionCorrect ? theme.colorScheme.secondary : theme.colorScheme.error;
    Color bgColor = isCurrentQuestionCorrect ? theme.colorScheme.secondaryContainer : theme.colorScheme.errorContainer;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCurrentQuestionCorrect ? Icons.check_circle : Icons.error,
              color: color,
            ),
            SizedBox(width: 10),
            Text(
              isCurrentQuestionCorrect ? 'Correct!' : 'Incorrect, try again.',
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: bgColor,
        // behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Might keep and add explanation here???
  // Card _buildAnswerCheckCard() {
  //   ThemeData theme = Theme.of(context);
  //
  //   Color color = isCurrentQuestionCorrect ? theme.colorScheme.green : theme.colorScheme.red;
  //   Color bgColor = isCurrentQuestionCorrect ? theme.colorScheme.paleGreen : theme.colorScheme.paleRed;
  //
  //   return Card(
  //         color: bgColor,
  //         shadowColor: Colors.transparent,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           side: BorderSide(
  //             color: color,
  //             width: 2.0,
  //           ),
  //         ),
  //         margin: EdgeInsets.only(left: 30, right: 30, top: 30),
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
  //           child: Row(
  //             children: [
  //               Icon(FontAwesomeIcons.solidCircleCheck, color: color,),
  //               SizedBox(width: 15), // Add spacing between icon and text
  //               Expanded(
  //                   child: Text(
  //                       isCurrentQuestionCorrect ? 'Correct!' : 'Incorrect, try again.',
  //                     style: theme.textTheme.labelLarge?.copyWith(
  //                       color: color,
  //                     ),
  //                   )
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  // }

}