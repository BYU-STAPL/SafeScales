import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int? selectedLessonIndex; // Track selected lesson in popup
  bool showLessonDialog = false;
  List<Map<String, dynamic>> accessories = [];
  List<Map<String, dynamic>> environments = [];
  bool isLoading = true;
  List<int> acquiredAccessories = [];
  List<String> acquiredEnvironments = [];
  Map<String, Map<String, dynamic>> quizDetails = {};

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
      'User profile reloaded. Quizzes data: ${_userState.currentUser?.quizzes}',
    );
    await _loadQuizDetails();
  }

  Future<void> _loadQuizDetails() async {
    try {
      final completedQuizzes = _getCompletedQuizzes();
      if (completedQuizzes.isEmpty) return;

      final quizIds = completedQuizzes.map((q) => int.parse(q['id'])).toList();
      print('Loading details for quiz IDs: $quizIds');

      final response = await SupabaseConfig.client
          .from('quizzes')
          .select()
          .inFilter('id', quizIds);

      print('Loaded quiz details: $response');

      setState(() {
        quizDetails = {for (var quiz in response) quiz['id'].toString(): quiz};
      });
    } catch (e) {
      print('Error loading quiz details: $e');
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
      print('Error loading shop items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getCompletedQuizzes() {
    final user = _userState.currentUser;
    print('Getting completed quizzes for user: ${user?.id}');
    print('User quizzes data: ${user?.quizzes}');

    if (user == null || user.quizzes == null) {
      print('No user or quizzes data available');
      return [];
    }

    final Map<String, dynamic> quizzes = user.quizzes!;
    print('Processing quizzes: $quizzes');

    final completedQuizzes =
        quizzes.entries
            .where((entry) {
              print(
                'Checking quiz ${entry.key}: score = ${entry.value['score']}, spent = ${entry.value['spent']}',
              );
              // Only include quizzes with 100% score and not spent
              return entry.value['score'] == 100 &&
                  entry.value['spent'] != true;
            })
            .map(
              (entry) => {
                'id': entry.key,
                'score': entry.value['score'],
                'completed_at': entry.value['completed_at'],
              },
            )
            .toList();

    print(
      'Found ${completedQuizzes.length} available completed quizzes: $completedQuizzes',
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
      // Get current user's quizzes data
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select('quizzes')
              .eq('id', userId)
              .single();

      final Map<String, dynamic> quizzes = response['quizzes'] ?? {};

      // Update the spent flag for the selected quiz
      if (quizzes[selectedLessonIndex.toString()] != null) {
        quizzes[selectedLessonIndex.toString()]['spent'] = true;

        // Update the quizzes data in the database
        await SupabaseConfig.client
            .from('Users')
            .update({'quizzes': quizzes})
            .eq('id', userId);

        // Update local user state
        await _userState.loadUserProfile();

        // Proceed with the purchase
        bool purchaseSuccess;
        if (selectedTab == 0) {
          purchaseSuccess = await _shopService.purchaseAccessory(
            userId,
            accessories[selectedIndex!]['id'],
          );
        } else {
          purchaseSuccess = await _shopService.purchaseEnvironment(
            userId,
            environments[selectedIndex!]['id'],
          );
        }

        if (purchaseSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Purchase successful!')));
          await _loadItems(); // Reload items to update owned status
        } else {
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
      print('Error during purchase: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color selected = primary;
    final Color unselected = Colors.blue[100]!;
    final Color selectedText = Colors.white;
    final Color unselectedText = primary;
    final Color highlight = Colors.green[300]!;

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
                    style: GoogleFonts.poppins(
                      fontSize: 16 * AppTheme.fontSizeScale,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                'ACCESSORIES',
                                style: GoogleFonts.poppins(
                                  fontSize: 15 * AppTheme.fontSizeScale,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      selectedTab == 0
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
                                style: GoogleFonts.poppins(
                                  fontSize: 15 * AppTheme.fontSizeScale,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      selectedTab == 1
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
                                        items[i]['image'],
                                    name: items[i]['name'],
                                    cost: items[i]['cost']?.toString() ?? '0',
                                    isSelected: selectedIndex == i,
                                    isOwned:
                                        selectedTab == 0
                                            ? acquiredAccessories.contains(
                                              items[i]['id'],
                                            )
                                            : acquiredEnvironments.contains(
                                              items[i]['id'],
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 14,
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 16 * AppTheme.fontSizeScale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('PURCHASE'),
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
                          'Select a completed module',
                          style: GoogleFonts.poppins(
                            fontSize: 18 * AppTheme.fontSizeScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
                                _getCompletedQuizzes().map((quiz) {
                                  final quizDetail = quizDetails[quiz['id']];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedLessonIndex = int.parse(
                                          quiz['id'],
                                        );
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
                                            selectedLessonIndex ==
                                                    int.parse(quiz['id'])
                                                ? primary.withOpacity(0.12)
                                                : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              selectedLessonIndex ==
                                                      int.parse(quiz['id'])
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
                                            quizDetail?['topic'] ??
                                                'Unknown Topic',
                                            style: GoogleFonts.poppins(
                                              fontSize:
                                                  15 * AppTheme.fontSizeScale,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Activity: ${quizDetail?['activity_type'] ?? 'Unknown'}',
                                            style: GoogleFonts.poppins(
                                              fontSize:
                                                  13 * AppTheme.fontSizeScale,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Score: ${quiz['score']}%',
                                            style: GoogleFonts.poppins(
                                              fontSize:
                                                  13 * AppTheme.fontSizeScale,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 14 * AppTheme.fontSizeScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                name,
                style: GoogleFonts.poppins(
                  fontSize: 15 * AppTheme.fontSizeScale,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                isOwned ? 'OWNED' : '$cost coins',
                style: GoogleFonts.poppins(
                  fontSize: 13 * AppTheme.fontSizeScale,
                  color: isOwned ? Colors.green : Colors.grey[600],
                  fontWeight: isOwned ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
