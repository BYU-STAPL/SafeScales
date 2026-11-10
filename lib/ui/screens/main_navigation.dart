import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/services/activity_event_service.dart';
import 'package:safe_scales/services/auth_service.dart';
import 'package:safe_scales/ui/screens/login/selection_screen.dart';

import 'package:safe_scales/ui/widgets/settings_drawer.dart';

import 'package:safe_scales/ui/screens/home_screen.dart';
import 'package:safe_scales/ui/screens/dragons_screen.dart';
import 'package:safe_scales/ui/screens/shop_screen.dart';
import 'package:safe_scales/ui/screens/review_list/review_list_screen.dart';

/// Tab indices for main navigation. Used when navigating programmatically.
const int kHomeTabIndex = 0;
const int kReviewTabIndex = 1;
const int kDragonsTabIndex = 2;
const int kShopTabIndex = 3;

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, required this.initialIndex});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _userState = UserStateService();
  final _authService = AuthService();
  final ActivityEventService _activityEvents = ActivityEventService();

  int _selectedIndex = 0;
  final Stopwatch _tabStopwatch = Stopwatch();
  DateTime? _backgroundedAt;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _selectedIndex = widget.initialIndex;
    _tabStopwatch.start();
    unawaited(
      _recordAppEvent(
        eventType: 'app_session_started',
        details: {'platform': defaultTargetPlatform.name},
      ),
    );
    unawaited(_recordTabOpened(_selectedIndex));

    _pages = <Widget>[
      HomeScreen(onNavigateToShop: () => _navigateToTab(kShopTabIndex)),
      const ReviewListScreen(),
      const DragonsScreen(),
      const ShopScreen(),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordTabDuration();
    _tabStopwatch.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _backgroundedAt == null) {
      final now = DateTime.now();
      _recordTabDuration(occurredAt: now);
      _tabStopwatch.stop();
      _backgroundedAt = now;
      unawaited(
        _recordAppEvent(eventType: 'app_backgrounded', occurredAt: now),
      );
    } else if (state == AppLifecycleState.resumed && _backgroundedAt != null) {
      final now = DateTime.now();
      final awayDuration = now.difference(_backgroundedAt!).inMilliseconds;
      _backgroundedAt = null;
      _tabStopwatch.start();
      unawaited(
        _recordAppEvent(
          eventType: 'app_resumed',
          occurredAt: now,
          details: {'background_duration_ms': awayDuration},
        ),
      );
    }
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case kHomeTabIndex:
        return 'Safe Scales';
      case kReviewTabIndex:
        return 'Review';
      case kDragonsTabIndex:
        return 'Dragons';
      case kShopTabIndex:
        return 'Shop';
      default:
        return '';
    }
  }

  void _navigateToTab(int index) {
    _selectTab(index);
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    _recordTabDuration();
    setState(() {
      _selectedIndex = index;
    });
    _tabStopwatch..reset();
    if (_backgroundedAt == null) {
      _tabStopwatch.start();
    }
    unawaited(_recordTabOpened(index));
  }

  void _recordTabDuration({DateTime? occurredAt}) {
    final durationMs = _tabStopwatch.elapsedMilliseconds;
    if (durationMs <= 0) return;
    _tabStopwatch
      ..stop()
      ..reset();
    unawaited(
      _recordAppEvent(
        eventType: 'navigation_tab_duration',
        occurredAt: occurredAt,
        contextType: 'navigation_tab',
        contextId: _getAppBarTitle(_selectedIndex),
        details: {'duration_ms': durationMs},
      ),
    );
  }

  Future<void> _recordTabOpened(int index) {
    return _recordAppEvent(
      eventType: 'navigation_tab_opened',
      contextType: 'navigation_tab',
      contextId: _getAppBarTitle(index),
    );
  }

  Future<void> _recordAppEvent({
    required String eventType,
    String? contextType,
    String? contextId,
    Map<String, dynamic> details = const {},
    DateTime? occurredAt,
  }) async {
    final userId = _userState.currentUser?.id;
    if (userId == null) return;
    await _activityEvents.recordBestEffort(
      userId: userId,
      eventType: eventType,
      contextType: contextType,
      contextId: contextId,
      details: details,
      occurredAt: occurredAt,
    );
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
        bottom: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
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
              _selectTab(index);
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
                label: 'Lessons',
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
