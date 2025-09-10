import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:safe_scales/models/question.dart';

import '../../../themes/app_theme.dart';
import '../../widgets/dragon_image_widget.dart';

class ReviewResultsScreen extends StatelessWidget {
  final String? image;

  const ReviewResultsScreen({
    super.key,
    this.image,
  });

  Widget _buildImageWidget(BuildContext context) {
    double size = 300;

    if (image == null || image == "") {
      return Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.surface,
        child: Icon(
          Icons.shopping_bag,
          size: size,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    Widget imageWidget = Image.asset(image!, width: size, height: size);

    if (image!.startsWith('http')) {
      imageWidget = Image.network(
        image!,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/other/QuestionMark.png',
            width: size,
            height: size,
          );
        },
      );
    }

    return imageWidget;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Complete'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 25),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Great job completing the review!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 30),

              Text(
                'Here\'s your new item',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),

              SizedBox(height: 30),

              _buildImageWidget(context),

              SizedBox(height: 30),

              Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                  child: Text(
                    'Return to Shop'.toUpperCase(),
                    style: TextStyle(
                      fontSize: theme.textTheme.bodyMedium?.fontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
