import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/accessories/toy_box_page.dart';
import 'package:safe_scales/dragons/dragon_page.dart';
import 'package:safe_scales/lesson/learn_page.dart';
import 'package:safe_scales/shop/shop_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/settings_drawer.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/activities/social_media_norms_page.dart';

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
      Center(
        child: ToyBoxPage(
          isDarkMode: widget.isDarkMode,
          onDarkModeChanged: widget.onDarkModeChanged,
          fontSize: widget.fontSize,
          onFontSizeChanged: widget.onFontSizeChanged,
        ),
      ),
      Center(
        child: ShopPage(
          isDarkMode: widget.isDarkMode,
          onDarkModeChanged: widget.onDarkModeChanged,
          fontSize: widget.fontSize,
          onFontSizeChanged: widget.onFontSizeChanged,
        ),
      ),
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
                GestureDetector(
                  onTap: () {
                    // Navigate to the current/next activity
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SocialMediaNormsPage(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary.withOpacity(0.9), primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Continue Learning',
                              style: GoogleFonts.poppins(
                                fontSize: 22 * AppTheme.fontSizeScale,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SOCIAL MEDIA NORMS',
                              style: GoogleFonts.poppins(
                                fontSize: 14 * AppTheme.fontSizeScale,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '30% Complete',
                                style: GoogleFonts.poppins(
                                  fontSize: 12 * AppTheme.fontSizeScale,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 24 * AppTheme.fontSizeScale,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Activities Section - Updated with unlock order
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activities',
                      style: GoogleFonts.poppins(
                        fontSize: 20 * AppTheme.fontSizeScale,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '1/6 Completed',
                      style: GoogleFonts.poppins(
                        fontSize: 14 * AppTheme.fontSizeScale,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Social Media Norms Activity
                _buildActivityCard(
                  context: context,
                  title: 'SOCIAL MEDIA NORMS',
                  isUnlocked: true,
                  progress: 0.3,
                  icon: Icons.share,
                  iconColor: Colors.blue[700]!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SocialMediaNormsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Internet Safety Activity
                _buildActivityCard(
                  context: context,
                  title: 'INTERNET SAFETY',
                  isUnlocked: false,
                  progress: 0.0,
                  icon: Icons.security,
                  iconColor: Colors.green[700]!,
                  unlockRequirement: 'Complete Social Media Norms',
                  onTap: () {
                    // TODO: Navigate to Internet Safety activity
                  },
                ),
                const SizedBox(height: 16),
                // Digital Footprint Activity
                _buildActivityCard(
                  context: context,
                  title: 'DIGITAL FOOTPRINT',
                  isUnlocked: false,
                  progress: 0.0,
                  icon: Icons.fingerprint,
                  iconColor: Colors.purple[700]!,
                  unlockRequirement: 'Complete Internet Safety',
                  onTap: () {
                    // TODO: Navigate to Digital Footprint activity
                  },
                ),
                const SizedBox(height: 16),
                // Privacy & Passwords Activity
                _buildActivityCard(
                  context: context,
                  title: 'PRIVACY & PASSWORDS',
                  isUnlocked: false,
                  progress: 0.0,
                  icon: Icons.lock_outline,
                  iconColor: Colors.red[700]!,
                  unlockRequirement: 'Complete Digital Footprint',
                  onTap: () {
                    // TODO: Navigate to Privacy & Passwords activity
                  },
                ),
                const SizedBox(height: 16),
                // Cyberbullying Activity
                _buildActivityCard(
                  context: context,
                  title: 'CYBERBULLYING',
                  isUnlocked: false,
                  progress: 0.0,
                  icon: Icons.shield_outlined,
                  iconColor: Colors.teal[700]!,
                  unlockRequirement: 'Complete Privacy & Passwords',
                  onTap: () {
                    // TODO: Navigate to Cyberbullying activity
                  },
                ),
                const SizedBox(height: 16),
                // Settings Activity - Unlocks last
                _buildActivityCard(
                  context: context,
                  title: 'SETTINGS',
                  isUnlocked: false,
                  progress: 0.0,
                  icon: Icons.settings,
                  iconColor: Colors.orange[700]!,
                  unlockRequirement: 'Complete all activities',
                  onTap: () {
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required BuildContext context,
    required String title,
    required bool isUnlocked,
    required double progress,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    String? unlockRequirement,
  }) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Theme.of(context).colorScheme.secondary;
    final Color cardBg = Theme.of(context).colorScheme.surface;
    final Color lockedBg =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color mutedTextColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final double borderRadius = 24.0;

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: isUnlocked ? cardBg : lockedBg,
          borderRadius: BorderRadius.circular(borderRadius),
          border:
              isUnlocked
                  ? null
                  : Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
          boxShadow:
              isUnlocked
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20 * AppTheme.fontSizeScale,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? textColor : mutedTextColor,
                letterSpacing: 0.8,
              ),
            ),
            if (!isUnlocked && unlockRequirement != null) ...[
              const SizedBox(height: 4),
              Text(
                unlockRequirement,
                style: GoogleFonts.poppins(
                  fontSize: 12 * AppTheme.fontSizeScale,
                  color: mutedTextColor.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Semi-circular progress bar with icon
            SizedBox(
              height: 100,
              width: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Semi-circular progress
                  if (isUnlocked)
                    CustomPaint(
                      size: const Size(160, 80),
                      painter: _SemiCircleProgressPainter(
                        color: secondary,
                        progress: progress,
                      ),
                    ),
                  // Icon in circle
                  Positioned(
                    top: 35,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          isUnlocked ? iconColor : Colors.grey[400],
                      child: Icon(
                        isUnlocked ? icon : Icons.lock,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isUnlocked) ...[
              Text(
                '${(progress * 100).round()}% Complete',
                style: GoogleFonts.poppins(
                  fontSize: 13 * AppTheme.fontSizeScale,
                  color: primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
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

// Custom painter for semi-circular progress bar with progress
class _SemiCircleProgressPainter extends CustomPainter {
  final Color color;
  final double progress;

  _SemiCircleProgressPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Background arc
    final Paint backgroundPaint =
        Paint()
          ..color = color.withOpacity(0.2)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Progress arc
    final Paint progressPaint =
        Paint()
          ..color = color
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    // Draw background arc (full semi-circle)
    canvas.drawArc(rect, 3.14159, 3.14159, false, backgroundPaint);

    // Draw progress arc (partial semi-circle based on progress)
    if (progress > 0) {
      canvas.drawArc(rect, 3.14159, 3.14159 * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SemiCircleProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
