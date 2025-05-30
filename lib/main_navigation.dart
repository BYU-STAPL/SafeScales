import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/settings_drawer.dart';
import 'package:safe_scales/shop/shop_page.dart';
import 'package:safe_scales/services/user_state_service.dart';

import 'accessories/toy_box_page.dart';
import 'dev_testing_page.dart';
import 'dragons/my_dragons.dart';
import 'home.dart';

class MainNavigation extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(double) onFontSizeChanged;
  final bool isDarkMode;
  final double fontSize;

  final int initialIndex;

  const MainNavigation({
    super.key,
    required this.onThemeChanged,
    required this.onFontSizeChanged,
    required this.isDarkMode,
    required this.fontSize,
    required this.initialIndex,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _userState = UserStateService();

  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.initialIndex;

    _pages = <Widget>[
      HomePage(
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
      DevTestingPage(
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onThemeChanged,
        fontSize: widget.fontSize,
        onFontSizeChanged: widget.onFontSizeChanged,
      ),
    ];
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Safe Scales';
      case 1:
        return 'Dragons';
      case 2:
        return 'Items';
      case 3:
        return 'Shop';
      case 4:
        return 'Dev Testing Page';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final Color primary = theme.colorScheme.primary;
    final Color cardBg = theme.colorScheme.surface;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(_selectedIndex),
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu_rounded), // 👈 your custom icon
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: SettingsDrawer(
        fontSize: widget.fontSize,
        onFontSizeChanged: widget.onFontSizeChanged,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onThemeChanged,
        username: _userState.userProfile?['Username'] ?? 'User',
        email: _userState.currentUser?.email ?? '',
        onTutorial: () {},
        onHelp: () {},
        onLogout: () {},
      ),
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
              color: Colors.black.withValues(alpha: 0.05),
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
          items: [
            const BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.graduationCap),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.dragon),
              label: 'Dragons',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.extension),
              label: 'Items',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront),
              label: 'Shop',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.construction_rounded),
              label: 'Dev Testing Page',
            ),
          ],
        ),
      ),
    );
  }
}
