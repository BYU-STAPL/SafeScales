import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/themes/app_theme.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int selectedTab = 0; // 0 = Accessories, 1 = Environments
  int? selectedIndex; // Track selected item index
  int? selectedLessonIndex; // Track selected lesson in popup
  bool showLessonDialog = false;

  // Example shop items (replace with your data)
  final List<Map<String, dynamic>> accessories = [
    {'image': null, 'name': 'Ice Cream'},
    {'image': null, 'name': 'Cowboy Hat'},
    {'image': null, 'name': 'Toy Car'},
    {'image': null, 'name': 'Beach Ball'},
    {'image': null, 'name': 'Bicycle'},
  ];

  final List<Map<String, dynamic>> environments = [
    {'image': null, 'name': 'Farm'},
    {'image': null, 'name': 'Mountain'},
    {'image': null, 'name': 'Lake'},
  ];

  // Placeholder completed lessons
  final List<String> completedLessons = [
    'Lesson 1: Internet Safety',
    'Lesson 2: Social Media Norms',
    'Lesson 3: Passwords',
    'Lesson 4: Digital Footprint',
  ];

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
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shop',
                        style: GoogleFonts.poppins(
                          fontSize: 28 * AppTheme.fontSizeScale,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.menu,
                            color: primary,
                            size: 28 * AppTheme.fontSizeScale,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
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
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 0.95,
                      children: [
                        for (int i = 0; i < items.length; i++)
                          _ShopItemCard(
                            image: items[i]['image'],
                            name: items[i]['name'],
                            isSelected: selectedIndex == i,
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
                          onPressed: () {
                            setState(() {
                              showLessonDialog = true;
                              selectedLessonIndex = null;
                            });
                          },
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
                          child: const Text('START REVIEW'),
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
                          'Select a completed lesson',
                          style: GoogleFonts.poppins(
                            fontSize: 18 * AppTheme.fontSizeScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...List.generate(completedLessons.length, (idx) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLessonIndex = idx;
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
                                    selectedLessonIndex == idx
                                        ? primary.withOpacity(0.12)
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      selectedLessonIndex == idx
                                          ? primary
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                completedLessons[idx],
                                style: GoogleFonts.poppins(
                                  fontSize: 15 * AppTheme.fontSizeScale,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }),
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
                                        // TODO: Handle lesson selection logic
                                        setState(
                                          () => showLessonDialog = false,
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Selected: ' +
                                                  completedLessons[selectedLessonIndex!],
                                            ),
                                          ),
                                        );
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
  final bool isSelected;
  final Color highlight;
  final VoidCallback onTap;
  const _ShopItemCard({
    this.image,
    required this.name,
    required this.isSelected,
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
            border: Border.all(color: Colors.black12, width: 1.2),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    image != null
                        ? Image.network(
                          image!,
                          width: 60 * AppTheme.fontSizeScale,
                          height: 60 * AppTheme.fontSizeScale,
                          fit: BoxFit.cover,
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
            ],
          ),
        ),
      ),
    );
  }
}
