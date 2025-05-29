import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/accessories/toy_box_page.dart';
import 'package:safe_scales/dragons/dragon_page.dart';
import 'package:safe_scales/lesson/learn_page.dart';
import 'package:safe_scales/shop/shop_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/settings_drawer.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/quiz/post_quiz_screen.dart';
import 'package:safe_scales/themes/app_theme.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;

  const HomePage({
    super.key,
    required this.initialIndex,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.fontSize,
    required this.onFontSizeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedIndex;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = [
      HomeTab(
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        fontSize: widget.fontSize,
        onFontSizeChanged: widget.onFontSizeChanged,
      ),
      Center(child: DragonPage()),
      Center(child: ToyBoxPage()),
      Center(child: ShopPage()),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Learn';
      case 1:
        return 'Play';
      case 2:
        return 'Items';
      case 3:
        return 'Shop';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(_selectedIndex),
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontSize: 25 * AppTheme.fontSizeScale,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class HomeTab extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;

  const HomeTab({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.fontSize,
    required this.onFontSizeChanged,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Theme.of(context).colorScheme.secondary;
    final Color cardBg = Theme.of(context).colorScheme.surface;
    final Color greyBg = Theme.of(context).colorScheme.surfaceDim;
    final Color settingsBg = Theme.of(context).colorScheme.surfaceContainer;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final double borderRadius = 24.0;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: SettingsDrawer(
        fontSize: widget.fontSize,
        onFontSizeChanged: widget.onFontSizeChanged,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        username: 'username',
        email: 'your-email@email.com',
        onTutorial: () {},
        onHelp: () {},
        onLogout: () {},
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Safe Scales',
                      style: GoogleFonts.poppins(
                        fontSize: 28 * AppTheme.fontSizeScale,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: primary,
                        size: 32 * AppTheme.fontSizeScale,
                      ),
                      onPressed: () {
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Next Activity Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Activity',
                            style: GoogleFonts.poppins(
                              fontSize: 22 * AppTheme.fontSizeScale,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SOCIAL MEDIA NORMS',
                            style: GoogleFonts.poppins(
                              fontSize: 14 * AppTheme.fontSizeScale,
                              color: primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Add test quiz buttons below the card
                const SizedBox(height: 18),
                Text(
                  'Test Quizzes',
                  style: GoogleFonts.poppins(
                    fontSize: 18 * AppTheme.fontSizeScale,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 110,
                      child: ElevatedButton(
                        onPressed: () {
                          final singleQ = Question.singleAnswer(
                            id: 'q1',
                            questionText: 'What color is the sky?',
                            options: ['Red', 'Blue', 'Green', 'Yellow'],
                            correctAnswerIndex: 1,
                            explanation: 'The Sky is blue',
                          );
                          final multipleQ = Question.multipleAnswer(
                            id: 'q3',
                            text:
                                "At your school, there is a security guard named Quinn. You have never met or talked to Quinn, but some of your school mates have.",
                            questionText: 'What social tag(s) apply to Quinn?',
                            options: [
                              'Acquaintance',
                              'Community Helper',
                              'Stranger',
                              'Work Peer',
                            ],
                            correctAnswerIndices: [1, 2],
                            explanation:
                                'Quinn serves the community, but don\'t know him',
                          );
                          final questionSet = QuestionSet(
                            id: "qset0",
                            title: "Test Question Set",
                            description: "This is a test",
                            activityType: ActivityType.preQuiz,
                            subject: "test subject",
                            questions: [singleQ, multipleQ],
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PreQuizScreen(questionSet: questionSet),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'PRE-QUIZ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: ElevatedButton(
                        onPressed: () {
                          final singleQ2 = Question.singleAnswer(
                            id: 'q2',
                            questionText: 'What season are oranges ripe?',
                            options: ['Spring', 'Summer', 'Fall', 'Winter'],
                            correctAnswerIndex: 3,
                            explanation: 'Oranges taste best during the winter',
                          );
                          final questionSet2 = QuestionSet(
                            id: "qset1",
                            title: "Test Post Quiz",
                            description: "This is a post-test",
                            activityType: ActivityType.postQuiz,
                            subject: "test subject",
                            questions: [singleQ2],
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PostQuizScreen(questionSet: questionSet2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'POST-QUIZ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Social Media Norms Progress
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SOCIAL MEDIA NORMS',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Semi-circular progress bar with egg
                      SizedBox(
                        height: 120,
                        width: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Semi-circular progress (placeholder)
                            CustomPaint(
                              size: const Size(180, 90),
                              painter: _SemiCirclePainter(color: secondary),
                            ),
                            // Egg image placeholder
                            Positioned(
                              top: 40,
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.green[700],
                                child: Icon(
                                  Icons.egg,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Settings Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: settingsBg,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: Center(
                    child: Text(
                      'SETTINGS',
                      style: GoogleFonts.poppins(
                        fontSize: 22 * AppTheme.fontSizeScale,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
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
