import 'package:flutter/material.dart';

class WelcomeScreens extends StatefulWidget {
  final VoidCallback onComplete;

  const WelcomeScreens({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<WelcomeScreens> createState() => _WelcomeScreensState();
}

class _WelcomeScreensState extends State<WelcomeScreens> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<WelcomeScreenData> _screens = [
    WelcomeScreenData(
      title: "Welcome to LearnQuest!",
      description: "Transform your learning journey into an exciting adventure. Complete lessons, earn rewards, and level up your knowledge!",
      icon: Icons.school_outlined,
      color: Colors.blue,
    ),
    WelcomeScreenData(
      title: "Learn Through Play",
      description: "Every lesson you complete unlocks new challenges and rewards. The more you learn, the more you achieve!",
      icon: Icons.games_outlined,
      color: Colors.green,
    ),
    WelcomeScreenData(
      title: "Track Your Progress",
      description: "Watch your knowledge grow with detailed progress tracking, streaks, and achievements. Celebrate every milestone!",
      icon: Icons.trending_up_outlined,
      color: Colors.orange,
    ),
    WelcomeScreenData(
      title: "Ready to Start?",
      description: "Your learning adventure begins now. Let's dive into your first lesson and start earning those rewards!",
      icon: Icons.rocket_launch_outlined,
      color: Colors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60), // Spacer for centering
                  Text(
                    '${_currentIndex + 1} of ${_screens.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onComplete,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _screens.length,
                itemBuilder: (context, index) {
                  return WelcomeScreen(data: _screens[index]);
                },
              ),
            ),

            // Bottom navigation
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _screens.length,
                          (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index
                              ? _screens[_currentIndex].color
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Navigation buttons
                  Row(
                    children: [
                      // Back button
                      if (_currentIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: _screens[_currentIndex].color),
                            ),
                            child: const Text('Back'),
                          ),
                        ),

                      if (_currentIndex > 0) const SizedBox(width: 16),

                      // Next/Get Started button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentIndex == _screens.length - 1) {
                              widget.onComplete();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _screens[_currentIndex].color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                          child: Text(
                            _currentIndex == _screens.length - 1
                                ? 'Get Started!'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class WelcomeScreen extends StatelessWidget {
  final WelcomeScreenData data;

  const WelcomeScreen({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with animated background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.color.withOpacity(0.1),
              border: Border.all(
                color: data.color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              data.icon,
              size: 60,
              color: data.color,
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 48),

          // Optional: Add some visual elements for gamification
          if (data.icon == Icons.games_outlined)
            _buildGameElements(),
          if (data.icon == Icons.trending_up_outlined)
            _buildProgressElements(),
        ],
      ),
    );
  }

  Widget _buildGameElements() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMiniCard(Icons.star, "Earn Stars", Colors.amber),
        _buildMiniCard(Icons.military_tech, "Unlock Badges", Colors.orange),
        _buildMiniCard(Icons.emoji_events, "Win Trophies", Colors.yellow),
      ],
    );
  }

  Widget _buildProgressElements() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMiniCard(Icons.local_fire_department, "Daily Streaks", Colors.red),
        _buildMiniCard(Icons.bar_chart, "Progress Charts", Colors.blue),
        _buildMiniCard(Icons.grade, "Achievement Level", Colors.green),
      ],
    );
  }

  Widget _buildMiniCard(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeScreenData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  WelcomeScreenData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Example usage in your main app:
class MainApp extends StatefulWidget {
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _showWelcome = true; // In real app, check SharedPreferences

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnQuest',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _showWelcome
          ? WelcomeScreens(
        onComplete: () {
          setState(() {
            _showWelcome = false;
          });
          // In real app: Save to SharedPreferences that user has seen welcome
        },
      )
          : HomeScreen(), // Your main app screen
    );
  }
}

// Placeholder for your main app screen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LearnQuest - Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to your main app!'),
            ElevatedButton(
              onPressed: () {
                // Reset welcome screens for testing
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => WelcomeScreens(
                      onComplete: () => Navigator.of(context).pop(),
                    ),
                  ),
                );
              },
              child: Text('Show Welcome Again'),
            ),
          ],
        ),
      ),
    );
  }
}