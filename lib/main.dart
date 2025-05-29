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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Scales',
      theme: buildLightAppTheme(),
      darkTheme: buildDarkAppTheme(),
      home: FutureBuilder(
        future: SupabaseConfig.initialize(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Initializing App',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please make sure you have set up your .env file correctly with Supabase credentials.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return const MainNavigation();
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    HomeTab(),
    MyDragonsPage(),
    ToyBoxPage(),
    ShopPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color cardBg = Colors.white;
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
