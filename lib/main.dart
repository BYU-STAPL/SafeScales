import 'package:flutter/material.dart';
import 'package:safe_scales/auth/auth_screen.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'home.dart';
import 'my_dragons.dart';
import 'package:safe_scales/accessories/toy_box_page.dart';
import 'package:safe_scales/shop/shop_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  double _fontSize = 1.0;

  void _updateTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  void _updateFontSize(double fontSize) {
    setState(() {
      _fontSize = fontSize;
      AppTheme.setFontSizeScale(fontSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Scales',
      theme: AppTheme.buildLightAppTheme(),
      darkTheme: AppTheme.buildDarkAppTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: FutureBuilder(
        future: SupabaseConfig.initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return AuthScreen(
            onThemeChanged: _updateTheme,
            onFontSizeChanged: _updateFontSize,
            isDarkMode: _isDarkMode,
            fontSize: _fontSize,
          );
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(double) onFontSizeChanged;
  final bool isDarkMode;
  final double fontSize;

  const MainNavigation({
    super.key,
    required this.onThemeChanged,
    required this.onFontSizeChanged,
    required this.isDarkMode,
    required this.fontSize,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      HomePage(
        initialIndex: 0,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onThemeChanged,
        fontSize: widget.fontSize,
        onFontSizeChanged: widget.onFontSizeChanged,
      ),
      MyDragonsPage(
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onThemeChanged,
        fontSize: widget.fontSize,
        onFontSizeChanged: widget.onFontSizeChanged,
      ),
      ToyBoxPage(
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onThemeChanged,
        fontSize: widget.fontSize,
        onFontSizeChanged: widget.onFontSizeChanged,
      ),
      ShopPage(
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onThemeChanged,
        fontSize: widget.fontSize,
        onFontSizeChanged: widget.onFontSizeChanged,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color cardBg = Theme.of(context).colorScheme.surface;
    return Scaffold(
      body: _pages[_selectedIndex],
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
