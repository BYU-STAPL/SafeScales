import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Theme.of(context).colorScheme.secondary;
    final Color cardBg = Colors.white;
    final Color greyBg = const Color(0xFFF4F4F4);
    final Color settingsBg = const Color(0xFFE1E1E1);
    final double borderRadius = 24.0;

    return Scaffold(
      backgroundColor: greyBg,
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
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.menu, color: primary, size: 32),
                      onPressed: () {},
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
                    border: Border.all(color: Colors.black, width: 2),
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
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SOCIAL MEDIA NORMS',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
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
                    ],
                  ),
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
                          color: Colors.black,
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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
      // Modern Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primary,
          unselectedItemColor: Colors.blue[100],
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Learn'),
            BottomNavigationBarItem(
              icon: Icon(Icons.videogame_asset),
              label: 'Play',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.extension),
              label: 'Items',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront),
              label: 'Shop',
            ),
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
