import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/accessories/toy_box_page.dart';
import 'package:safe_scales/dragons/dragon_page.dart';
import 'package:safe_scales/lesson/learn_page.dart';
import 'package:safe_scales/shop/shop_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: LearnPage()),
    Center(child: DragonPage()),
    Center(child: ToyBoxPage()),
    Center(child: ShopPage()),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return "Safe Scales";
      case 1:
        return "My Dragons";
      case 2:
        return "Toy Box";
      case 3:
        return "Shop";
      default:
        return "Safe Scales";
    }
  }

  @override
  void initState() {
    setState(() {
      _selectedIndex = widget.initialIndex;
    });
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
            fontSize: 25,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        // iconSize: 20, // Reduce the icon size
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: theme.colorScheme.primary,     // Active color
        unselectedItemColor: theme.colorScheme.secondary,   // Inactive color
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.graduationCap,),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.dragon,),
            label: 'Dragons',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.boxesStacked,), //TODO: MAYBE this would be a fun icon FaIcon(FontAwesomeIcons.parachuteBox,),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.shop,),
            label: 'Shop',
          ),
        ],
      ),
    );
  }
}