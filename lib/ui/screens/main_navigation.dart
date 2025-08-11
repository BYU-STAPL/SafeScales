import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/auth_service.dart';
import 'package:safe_scales/ui/screens/login/selection_screen.dart';

import 'package:safe_scales/ui/widgets/settings_drawer.dart';

import 'package:safe_scales/ui/screens/home_screen.dart';
import 'package:safe_scales/ui/screens/dragons_screen.dart';
import 'package:safe_scales/ui/screens/items_screen.dart';
import 'package:safe_scales/ui/screens/shop_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, required this.initialIndex});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _userState = UserStateService();
  final _authService = AuthService();

  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.initialIndex;

    _pages = <Widget>[
      // Hard code shop index here, that way this information doesn't need to be shared across files
      HomeScreen(onNavigateToShop: () {_navigateToTab(3);}),
      DragonsScreen(),
      ItemsScreen(),
      ShopScreen(),
      // DevTestingPage(), //TODO: Remove later
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
      default:
        return '';
    }
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();

      if (mounted) {
        // Navigate to selection screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SelectionScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final Color primary = theme.colorScheme.primary;
    final Color barColor = theme.colorScheme.surfaceBright;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceBright,
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
        username: _userState.userProfile?['Username'] ?? 'User',
        email: _userState.currentUser?.email ?? '',
        onTutorial: () {},
        onHelp: () {},
        onLogout: _handleLogout,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: barColor,
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

            //TODO: Remove later
            // const BottomNavigationBarItem(
            //   icon: Icon(Icons.device_hub),
            //   label: 'Dev',
            // ),
          ],
        ),
      ),
    );
  }
}
