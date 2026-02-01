import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/auth_service.dart';
import 'package:safe_scales/ui/screens/login/selection_screen.dart';

import 'package:safe_scales/ui/widgets/settings_drawer.dart';

import 'package:safe_scales/ui/screens/home_screen.dart';
import 'package:safe_scales/ui/screens/dragons_screen.dart';
import 'package:safe_scales/ui/screens/items_screen.dart';
import 'package:safe_scales/ui/screens/review_list/review_list_screen.dart';
import 'package:safe_scales/ui/screens/shop_screen.dart';

/// Tab indices for main navigation. Used when navigating programmatically.
const int kHomeTabIndex = 0;
const int kReviewTabIndex = 1;
const int kDragonsTabIndex = 2;
const int kItemsTabIndex = 3;
const int kShopTabIndex = 4;

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
      HomeScreen(
        onNavigateToShop: () {
          _navigateToTab(kShopTabIndex);
        },
      ),
      const ReviewListScreen(),
      DragonsScreen(),
      ItemsScreen(),
      ShopScreen(),
    ];
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case kHomeTabIndex:
        return 'Safe Scales';
      case kReviewTabIndex:
        return 'Review';
      case kDragonsTabIndex:
        return 'Dragons';
      case kItemsTabIndex:
        return 'Items';
      case kShopTabIndex:
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
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: theme.colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
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
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: Platform.isAndroid, // Only apply bottom padding on Android
        child: Container(
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
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
            unselectedItemColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.5,
            ),
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.graduationCap),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.bullseye),
                label: 'Review',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.dragon),
                label: 'Dragons',
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
      ),
    );
  }
}
