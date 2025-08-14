import 'package:flutter/material.dart';
import 'package:safe_scales/ui/widgets/dragon_image_widget.dart';

class ReadingResultScreen extends StatelessWidget {
  const ReadingResultScreen({super.key, required this.modeuleId});

  final String modeuleId;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reading Complete'),
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
                'Great job completing the reading!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 30),

              Text(
                'Your new dragon is now a teenage dragon!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),

              SizedBox(height: 30),

              DragonImageWidget(
                moduleId: modeuleId,
                phase: 'stage2',
                size: 300,
              ),

              SizedBox(height: 30),

              Text(
                'Complete the Post-Quiz with a passing score for your dragon to become a full adult.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),

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
                    'Return to lesson'.toUpperCase(),
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
