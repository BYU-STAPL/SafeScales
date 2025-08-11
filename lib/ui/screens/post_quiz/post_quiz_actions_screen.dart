import 'package:flutter/material.dart';
import 'package:safe_scales/themes/app_theme.dart';
import '../../widgets/dragon_image_widget.dart';

// Define action types for better type safety
enum QuizAction {
  retake,
  reread,
  returnToLesson,
  goToDragon,
}

class PostQuizActionsScreen extends StatefulWidget {
  const PostQuizActionsScreen({
    super.key,
    required this.moduleId,
    required this.passingScore,
    required this.score,
    required this.handleAction,
  });

  final String moduleId;
  final int passingScore;
  final int score;
  final Future<void> Function(QuizAction action) handleAction;

  @override
  State<PostQuizActionsScreen> createState() => _PostQuizActionsScreenState();
}

class _PostQuizActionsScreenState extends State<PostQuizActionsScreen> {

  @override
  void initState() {
    super.initState();
  }

  //TODO: Adjust so new screens can return to the suggested action
  // Simple action handlers that just return the action type
  void _handleRetakeQuiz() {
    // Navigator.pop(context, QuizAction.retake);
    widget.handleAction(QuizAction.retake);
  }

  void _handleReReadLesson() {
    widget.handleAction(QuizAction.reread);
  }

  void _handleReturnToLesson() {
    widget.handleAction(QuizAction.returnToLesson);
  }

  void _handleGoToDragon() {
    widget.handleAction(QuizAction.goToDragon);
  }

  Widget _buildDragonAction(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'Your dragon is fully grown!',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        SizedBox(height: 30),

        DragonImageWidget(moduleId: widget.moduleId, size: 300, phase: 'final',),

        SizedBox(height: 30),
        Text(
          'Now you can play with your dragon by going to the dragon screen',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),

        SizedBox(height: 30),

        // TODO: Need to update quiz progress here if this button is clicked and user doesn't return to lesson
        // SizedBox(
        //   width: double.infinity,
        //   child: ElevatedButton.icon(
        //     onPressed: _handleGoToDragon,
        //     icon: FaIcon(FontAwesomeIcons.dragon),
        //     label: Text("GO TO DRAGON".toUpperCase()),
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: theme.colorScheme.primary,
        //       foregroundColor: theme.colorScheme.onPrimary,
        //       padding: EdgeInsets.symmetric(vertical: 12),
        //     ),
        //   ),
        // ),

        SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSuggestedAction(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(height: 30),
        Padding(
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
        SizedBox(height: 30),
        Text("Suggested Action", style: theme.textTheme.headlineMedium),
        SizedBox(height: 30),

        // Action buttons that delegate to parent
        widget.score >= 50
            ? Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleRetakeQuiz,
                icon: Icon(Icons.refresh),
                label: Text("Retake Quiz".toUpperCase()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            SizedBox(height: 30),

            Text('OR'.toUpperCase()),

            SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleReReadLesson,
                icon: Icon(Icons.menu_book),
                label: Text("Re-read Lesson".toUpperCase()),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2), width: 2),
                  backgroundColor: theme.colorScheme.surface, // optional: contrast background
                  foregroundColor: theme.colorScheme.primary, // optional: text/icon color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12,),
                ),
              ),
            ),



          ],
        )
            : SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleReReadLesson,
            icon: Icon(Icons.menu_book),
            label: Text("Re-read Lesson".toUpperCase()),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
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
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 25),
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
                  onPressed: _handleReturnToLesson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                  child: Text(
                    'Return to lesson'.toUpperCase(),
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