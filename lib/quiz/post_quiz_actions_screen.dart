import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/themes/app_theme.dart';

import '../main_navigation.dart';

class PostQuizActionsScreen extends StatelessWidget {
  const PostQuizActionsScreen({
    super.key,
    required this.passingScore,
    required this.score,
  });

  final int passingScore;
  final int score;

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
          onPressed: (){
            // Go to Dragon Page
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MainNavigation(initialIndex: 1), // Index of desired tab
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
                  '$score%',
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

        Text(
          "Suggested Action",
          style: theme.textTheme.headlineMedium,
        ),

        SizedBox(height: 20),

        //TODO: Implement these buttons
        score >= 50 ? ElevatedButton(
            onPressed: null,
            child: Text("Retake Quiz".toUpperCase())
        )
            : ElevatedButton(
            onPressed: null,
            child: Text("Re-read".toUpperCase())
        ),

        SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Results'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            children: [

              // TODO: Implement Retake Button then enter back in
              score >= passingScore ? _buildDragonAction(context) : _buildSuggestedAction(context),

              Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop back to SocialMediaNormsPage with completion status

                    // Return true to indicate should return to lesson
                    Navigator.pop(context, true);
                  },
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
          )
        ),
      ),
    );
  }

}