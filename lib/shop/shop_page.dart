import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/extensions/string_extensions.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/settings_drawer.dart';
import 'package:safe_scales/services/shop_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/config/supabase_config.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ShopService _shopService = ShopService();
  final UserStateService _userState = UserStateService();
  int selectedTab = 0; // 0 = Accessories, 1 = Environments
  int? selectedIndex; // Track selected item index
  String? selectedLessonIndex; // Track selected lesson in popup
  bool showLessonDialog = false;
  List<Map<String, dynamic>> accessories = [];
  List<Map<String, dynamic>> environments = [];
  bool isLoading = true;
  List<String> acquiredAccessories = [];
  List<String> acquiredEnvironments = [];
  Map<String, Map<String, dynamic>> quizDetails = {};
  Map<String, Map<String, dynamic>> moduleDetails = {};

  // Placeholder completed lessons
  final List<String> completedLessons = [
    'Lesson 1: Internet Safety',
    'Lesson 2: Social Media Norms',
    'Lesson 3: Passwords',
    'Lesson 4: Digital Footprint',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _reloadUserProfile();
  }

  Future<void> _reloadUserProfile() async {
    print('Reloading user profile in shop page');
    await _userState.loadUserProfile();
    print(
      'User profile reloaded. Modules data: ${_userState.currentUser?.modules}',
    );
    await _loadModuleDetails();
  }

  Future<void> _loadModuleDetails() async {
    try {
      final completedModules = _getCompletedQuizzes();
      if (completedModules.isEmpty) return;

      final moduleIds = completedModules.map((m) => m['id']).toList();
      print('Loading details for module IDs: $moduleIds');

      final response = await SupabaseConfig.client
          .from('modules')
          .select()
          .inFilter('id', moduleIds);

      print('Loaded module details: $response');

      setState(() {
        moduleDetails = {for (var module in response) module['id']: module};
      });
    } catch (e) {
      print('❌Error loading module details: $e');
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final accessoriesData = await _shopService.getAccessories();
      final environmentsData = await _shopService.getEnvironments();

      // Load user's acquired items
      final userId = _userState.currentUser?.id;
      if (userId != null) {
        acquiredAccessories = await _shopService.getUserAcquiredAccessories(
          userId,
        );
        acquiredEnvironments = await _shopService.getUserAcquiredEnvironments(
          userId,
        );
      }

      setState(() {
        accessories = accessoriesData;
        environments = environmentsData;
        isLoading = false;
      });
    } catch (e) {
      print('❌Error loading shop items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getCompletedQuizzes() {
    final user = _userState.currentUser;
    print('Getting completed modules for user: ${user?.id}');
    print('User modules data: ${user?.modules}');

    if (user == null || user.modules == null) {
      print('No user or modules data available');
      return [];
    }

    final Map<String, dynamic> modules = user.modules!;
    print('Processing modules: $modules');

    final completedQuizzes =
        modules.entries
            .where((moduleEntry) {
              final moduleData = moduleEntry.value as Map<String, dynamic>;
              // Check if both preQuiz and postQuiz are completed with 100% score
              final preQuiz = moduleData['preQuiz'] as Map<String, dynamic>?;
              final postQuiz = moduleData['postQuiz'] as Map<String, dynamic>?;

              // Check if either quiz is already spent
              final isPreQuizSpent = preQuiz?['spent'] == true;
              final isPostQuizSpent = postQuiz?['spent'] == true;

              return preQuiz != null &&
                  postQuiz != null &&
                  preQuiz['score'] == 100 &&
                  postQuiz['score'] == 100 &&
                  !isPreQuizSpent &&
                  !isPostQuizSpent;
            })
            .map((moduleEntry) {
              final moduleData = moduleEntry.value as Map<String, dynamic>;
              return {
                'id': moduleEntry.key,
                'preQuiz': moduleData['preQuiz'],
                'postQuiz': moduleData['postQuiz'],
              };
            })
            .toList();

    print(
      'Found ${completedQuizzes.length} available completed modules: $completedQuizzes',
    );
    return completedQuizzes;
  }

  Future<void> _handlePurchase() async {
    if (selectedIndex == null) return;

    final userId = _userState.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to purchase items')),
      );
      return;
    }

    print('Showing completed modules popup');
    print('Current user: ${_userState.currentUser?.id}');
    print('User quizzes: ${_userState.currentUser?.quizzes}');

    // Show completed modules popup first
    setState(() {
      showLessonDialog = true;
      selectedLessonIndex = null;
    });
  }

  Future<void> _completePurchase() async {
    if (selectedIndex == null || selectedLessonIndex == null) return;

    final userId = _userState.currentUser?.id;
    if (userId == null) return;

    try {
      // Get current user's modules data
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select('modules')
              .eq('id', userId)
              .single();

      final Map<String, dynamic> modules = response['modules'] ?? {};

      // Update the spent flag for the selected module
      if (modules[selectedLessonIndex] != null) {
        final moduleData = modules[selectedLessonIndex] as Map<String, dynamic>;

        // Check if module is already spent
        final preQuiz = moduleData['preQuiz'] as Map<String, dynamic>?;
        final postQuiz = moduleData['postQuiz'] as Map<String, dynamic>?;

        if (preQuiz?['spent'] == true || postQuiz?['spent'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This module has already been used for a purchase'),
            ),
          );
          return;
        }

        // Mark both preQuiz and postQuiz as spent
        if (preQuiz != null) {
          preQuiz['spent'] = true;
          preQuiz['spent_at'] = DateTime.now().toIso8601String();
        }
        if (postQuiz != null) {
          postQuiz['spent'] = true;
          postQuiz['spent_at'] = DateTime.now().toIso8601String();
        }

        // Update the modules data in the database
        await SupabaseConfig.client
            .from('Users')
            .update({'modules': modules})
            .eq('id', userId);

        // Update local user state
        await _userState.loadUserProfile();

        // Proceed with the purchase
        bool purchaseSuccess;
        if (selectedTab == 0) {
          purchaseSuccess = await _shopService.purchaseAccessory(
            userId,
            accessories[selectedIndex!]['id'].toString(),
          );
        } else {
          purchaseSuccess = await _shopService.purchaseEnvironment(
            userId,
            environments[selectedIndex!]['id'].toString(),
          );
        }

        if (purchaseSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase successful! Module marked as spent.'),
            ),
          );
          await _loadItems(); // Reload items to update owned status
        } else {
          // If purchase fails, revert the spent flags
          if (preQuiz != null) {
            preQuiz['spent'] = false;
            preQuiz.remove('spent_at');
          }
          if (postQuiz != null) {
            postQuiz['spent'] = false;
            postQuiz.remove('spent_at');
          }

          // Update the database to revert the spent flags
          await SupabaseConfig.client
              .from('Users')
              .update({'modules': modules})
              .eq('id', userId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to complete purchase')),
          );
        }
      }

      setState(() {
        showLessonDialog = false;
        selectedLessonIndex = null;
      });
    } catch (e) {
      print('❌Error during purchase: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    final Color primary = Theme.of(context).colorScheme.primary;
    final Color selected = primary;
    final Color unselected = theme.colorScheme.lightBlue.withValues(alpha: 0.5); //Colors.blue[100]!;
    final Color selectedText = Colors.white;
    final Color unselectedText = primary;
    final Color highlight = theme.colorScheme.green.withValues(alpha: 0.25);

    final items = selectedTab == 0 ? accessories : environments;

    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    'Buy new accessories and environments for your dragons! Earn coins by playing and reviewing.',
                    style: theme.textTheme.labelMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Toggle Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => setState(() {
                                selectedTab = 0;
                                selectedIndex = null;
                              }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedTab == 0 ? selected : unselected,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'ACCESSORIES'.toUpperCase(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: selectedTab == 0
                                      ? selectedText
                                      : unselectedText,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => setState(() {
                                selectedTab = 1;
                                selectedIndex = null;
                              }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedTab == 1 ? selected : unselected,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'ENVIRONMENTS',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: selectedTab == 1
                                      ? selectedText
                                      : unselectedText,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Shop Items Grid
                  Expanded(
                    child:
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 24,
                              crossAxisSpacing: 24,
                              childAspectRatio: 0.95,
                              children: [
                                for (int i = 0; i < items.length; i++)
                                  _ShopItemCard(
                                    image:
                                        items[i]['image_url'] ??
                                        items[i]['imageUrl'] ??
                                        items[i]['image'],
                                    name: items[i]['name'],
                                    cost: items[i]['cost']?.toString() ?? '1',
                                    isSelected: selectedIndex == i,
                                    isOwned:
                                        selectedTab == 0
                                            ? acquiredAccessories.contains(
                                              items[i]['id'].toString(),
                                            )
                                            : acquiredEnvironments.contains(
                                              items[i]['id'].toString(),
                                            ),
                                    highlight: highlight,
                                    onTap: () {
                                      setState(() {
                                        selectedIndex = i;
                                      });
                                    },
                                  ),
                              ],
                            ),
                  ),
                  if (selectedIndex != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: _handlePurchase,
                          // style: ElevatedButton.styleFrom(
                          //   backgroundColor: primary,
                          //   foregroundColor: Colors.white,
                          //   elevation: 2,
                          //   shape: RoundedRectangleBorder(
                          //     borderRadius: BorderRadius.circular(12),
                          //   ),
                          //   padding: const EdgeInsets.symmetric(
                          //     horizontal: 36,
                          //     vertical: 14,
                          //   ),
                          // ),
                          child: Text(
                              'PURCHASE'.toUpperCase(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showLessonDialog)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => showLessonDialog = false),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a completed module'.toTitleCase(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 18 * AppTheme.fontSizeScale,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.5,
                          ),
                          child: ListView(
                            shrinkWrap: true,
                            children:
                                _getCompletedQuizzes().map((module) {
                                  final moduleDetail =
                                      moduleDetails[module['id']];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedLessonIndex = module['id'];
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            selectedLessonIndex == module['id']
                                                ? primary.withOpacity(0.12)
                                                : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              selectedLessonIndex ==
                                                      module['id']
                                                  ? primary
                                                  : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            moduleDetail?['title'] ??
                                                'Unknown Module',
                                            style: theme.textTheme.headlineSmall?.copyWith(
                                              fontSize: 15 * AppTheme.fontSizeScale,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pre-Quiz Score: ${module['preQuiz']['score']}%',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Post-Quiz Score: ${module['postQuiz']['score']}%',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed:
                                  () =>
                                      setState(() => showLessonDialog = false),
                              child: Text(
                                'CANCEL',
                                style: TextStyle(
                                  fontSize: 14 * AppTheme.fontSizeScale,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed:
                                  selectedLessonIndex != null
                                      ? () {
                                        _completePurchase();
                                      }
                                      : null,
                              // style: ElevatedButton.styleFrom(
                              //   backgroundColor: primary,
                              //   foregroundColor: Colors.white,
                              //   elevation: 1,
                              //   shape: RoundedRectangleBorder(
                              //     borderRadius: BorderRadius.circular(8),
                              //   ),
                              //   padding: const EdgeInsets.symmetric(
                              //     horizontal: 18,
                              //     vertical: 10,
                              //   ),
                              // ),
                              child: const Text('SELECT'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final String? image;
  final String name;
  final String cost;
  final bool isSelected;
  final bool isOwned;
  final Color highlight;
  final VoidCallback onTap;

  const _ShopItemCard({
    this.image,
    required this.name,
    required this.cost,
    required this.isSelected,
    required this.isOwned,
    required this.highlight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? highlight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOwned ? Colors.green : Colors.black12,
              width: isOwned ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                        image != null
                            ? Image.network(
                              image!,
                              width: 60 * AppTheme.fontSizeScale,
                              height: 60 * AppTheme.fontSizeScale,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60 * AppTheme.fontSizeScale,
                                  height: 60 * AppTheme.fontSizeScale,
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.shopping_bag,
                                    size: 32 * AppTheme.fontSizeScale,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            )
                            : Container(
                              width: 60 * AppTheme.fontSizeScale,
                              height: 60 * AppTheme.fontSizeScale,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.shopping_bag,
                                size: 32 * AppTheme.fontSizeScale,
                                color: Colors.grey[600],
                              ),
                            ),
                  ),
                  if (isOwned)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 16 * AppTheme.fontSizeScale,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                name.toTitleCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 15 * AppTheme.fontSizeScale,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                isOwned ? 'OWNED'.toUpperCase() : 'Cost: $cost review set',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isOwned ? Colors.green : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
