import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/services/class_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/ui/screens/reading/reading_results_screen.dart';

import '../../widgets/progress_bar.dart';

class ReadingActivityScreen extends StatefulWidget {
  final String moduleId;
  final String topic;

  const ReadingActivityScreen({Key? key, required this.moduleId, required this.topic,})
    : super(key: key);

  @override
  State<ReadingActivityScreen> createState() => _ReadingActivityScreenState();
}

class _ReadingActivityScreenState extends State<ReadingActivityScreen>
    with TickerProviderStateMixin {
  final ClassService _classService = ClassService(SupabaseConfig.client);
  final UserStateService _userState = UserStateService();

  List<Map<String, dynamic>> _slides = [];
  int _currentSlideIndex = 0;
  bool _isLoading = true;
  bool _showTableOfContents = false;
  Set<int> _bookmarkedPages = {};
  // late AnimationController _pageController;
  // late Animation<Offset> _slideAnimation;
  bool _isForward = true;
  bool _isFirstLoad = true;

  bool _isCompleted = false;


  @override
  void initState() {
    super.initState();
    _loadSlides();
    // _pageController = AnimationController(
    //   duration: const Duration(milliseconds: 300),
    //   vsync: this,
    // );
    // _slideAnimation = Tween<Offset>(
    //   begin: const Offset(1.0, 0.0),
    //   end: Offset.zero,
    // ).animate(
    //   CurvedAnimation(parent: _pageController, curve: Curves.easeInOut),
    // );
  }

  @override
  void dispose() {
    // _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSlides() async {
    try {
      if (widget.moduleId != null) {
        final moduleData = await _classService.getModuleById(widget.moduleId!);
        if (moduleData != null && moduleData['revision'] != null) {
          final revision = Map<String, dynamic>.from(moduleData['revision']);
          if (revision['slides'] != null) {
            setState(() {
              _slides = List<Map<String, dynamic>>.from(revision['slides']);
              _isLoading = false;
            });

            // Load previously saved bookmarks
            await _loadBookmarks();
          }
        }
      }
    } catch (e) {
      print('❌Error loading slides: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final user = _userState.currentUser;
      if (user == null || widget.moduleId == null) return;

      final response =
          await _classService.supabase
              .from('Users')
              .select('modules')
              .eq('id', user.id)
              .single();

      if (response['modules'] != null) {
        final modulesData = Map<String, dynamic>.from(response['modules']);
        if (modulesData.containsKey(widget.moduleId!) &&
            modulesData[widget.moduleId!]['reading'] != null &&
            modulesData[widget.moduleId!]['reading']['bookmarks'] != null) {
          final bookmarks = List<int>.from(
            modulesData[widget.moduleId!]['reading']['bookmarks'],
          );
          setState(() {
            _bookmarkedPages = Set<int>.from(bookmarks);
          });
        }
      }
    } catch (e) {
      print('❌Error loading bookmarks: $e');
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final user = _userState.currentUser;
      if (user == null || widget.moduleId == null) return;

      final response =
          await _classService.supabase
              .from('Users')
              .select('modules')
              .eq('id', user.id)
              .single();

      Map<String, dynamic> modulesData = {};
      if (response['modules'] != null) {
        modulesData = Map<String, dynamic>.from(response['modules']);
      }

      if (!modulesData.containsKey(widget.moduleId!)) {
        modulesData[widget.moduleId!] = {};
      }

      if (!modulesData[widget.moduleId!].containsKey('reading')) {
        modulesData[widget.moduleId!]['reading'] = {};
      }

      // Update only the bookmarks, preserve other reading data
      modulesData[widget.moduleId!]['reading']['bookmarks'] =
          _bookmarkedPages.toList();

      await _classService.supabase
          .from('Users')
          .update({'modules': modulesData})
          .eq('id', user.id);
    } catch (e) {
      print('❌Error saving bookmarks: $e');
    }
  }

  Future<void> _saveReadingProgress() async {
    try {
      final user = _userState.currentUser;
      if (user == null || widget.moduleId == null) return;

      final response =
      await _classService.supabase
          .from('Users')
          .select('modules')
          .eq('id', user.id)
          .single();

      Map<String, dynamic> modulesData = {};
      if (response['modules'] != null) {
        modulesData = Map<String, dynamic>.from(response['modules']);
      }

      if (!modulesData.containsKey(widget.moduleId!)) {
        modulesData[widget.moduleId!] = {};
      }

      modulesData[widget.moduleId!]['reading'] = {
        'completed': true,
        'completed_at': DateTime.now().toIso8601String(),
        'bookmarks': _bookmarkedPages.toList(),
      };

      await _classService.supabase
          .from('Users')
          .update({'modules': modulesData})
          .eq('id', user.id);
    } catch (e) {
      print('❌Error saving reading progress: $e');
      rethrow; // Re-throw to be caught by _markAsCompleted
    }
  }

  Future<void> _markAsCompleted() async {
    try {
      final user = _userState.currentUser;
      if (user == null || widget.moduleId == null) return;

      // Save progress immediately when reading is completed
      await _saveReadingProgress();

      // Save isComplete flag.
      _isCompleted = true;

      // Navigate to results screen and wait for it to return
      final shouldPopReading = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReadingResultScreen(
            modeuleId: widget.moduleId,
          ),
        ),
      );

      // Only pop the reading screen if the results screen returned true
      // (meaning the user wants to go back to the lesson)
      if (mounted && shouldPopReading == true) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌Error marking reading as completed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _nextSlide() {
    if (_currentSlideIndex < _slides.length - 1) {
      setState(() {
        _isForward = true;
        _isFirstLoad = false;
      });
      // _pageController.forward(from: 0.0).then((_) {
      setState(() {
        _currentSlideIndex++;
      });
      // });
    } else {
      _markAsCompleted();
    }
  }

  void _previousSlide() {
    if (_currentSlideIndex > 0) {
      setState(() {
        _isForward = false;
        _isFirstLoad = false;
      });
      // _pageController.forward(from: 0.0).then((_) {
      setState(() {
        _currentSlideIndex--;
      });
      // });
    }
  }

  Container _buildNavigationBar() {
    ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _currentSlideIndex > 0 ? _previousSlide : null,
            icon: const Icon(Icons.arrow_back_ios_rounded),
            label: Text('Previous'.toUpperCase()),
          ),
          TextButton.icon(
            iconAlignment: IconAlignment.end,
            onPressed: _nextSlide,
            label: Text(
              _currentSlideIndex < _slides.length - 1
                  ? 'Next'.toUpperCase()
                  : 'Complete'.toUpperCase(),
            ),
            icon: Icon(Icons.arrow_forward_ios_rounded),
          ),
        ],
      ),
    );
  }

  void _toggleBookmark() {
    setState(() {
      if (_bookmarkedPages.contains(_currentSlideIndex)) {
        _bookmarkedPages.remove(_currentSlideIndex);
      } else {
        _bookmarkedPages.add(_currentSlideIndex);
      }
    });

    // Save bookmarks in real-time
    _saveBookmarks();
  }

  void _jumpToPage(int index) {
    if (index >= 0 && index < _slides.length) {
      setState(() {
        _isForward = index > _currentSlideIndex;
        _isFirstLoad = false;
      });
      // _pageController.forward(from: 0.0).then((_) {
      setState(() {
        _currentSlideIndex = index;
        _showTableOfContents = false;
      });
      // });
    }
  }

  Widget _buildTableOfContents() {
    return Container(
      padding: EdgeInsets.all(30),
      color: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        itemCount: _slides.length,
        itemBuilder: (context, index) {
          final isBookmarked = _bookmarkedPages.contains(index);
          return ListTile(
            leading: Icon(
              isBookmarked
                  ? FontAwesomeIcons.solidBookmark
                  : FontAwesomeIcons.bookmark,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'P${index + 1}: ${_slides[index]['headline'] ?? 'Page ${index + 1}'}',
              style:
                  index == _currentSlideIndex
                      ? Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 18)
                      : Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () => _jumpToPage(index),
          );
        },
      ),
    );
  }

  Widget _buildPageContent() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page ${_currentSlideIndex + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              IconButton(
                iconSize: 22,
                icon: Icon(
                  _bookmarkedPages.contains(_currentSlideIndex)
                      ? FontAwesomeIcons.solidBookmark
                      : FontAwesomeIcons.bookmark,
                  color:
                      _bookmarkedPages.contains(_currentSlideIndex)
                          ? theme.colorScheme.primary
                          : null,
                ),
                onPressed: _toggleBookmark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _slides[_currentSlideIndex]['headline'] ?? 'Reading Content',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Text(
            _slides[_currentSlideIndex]['content'] ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_currentSlideIndex + 1) / _slides.length;

    return PopScope(
      canPop: false, // Prevent default back button behavior
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // If reading is completed, return true to indicate completion
        if (_isCompleted) {
          Navigator.pop(context, true);
        } else {
          // If reading is not completed, just go back normally
          Navigator.pop(context, false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Reading'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _showTableOfContents ? Icons.close : FontAwesomeIcons.list,
              ),
              iconSize: 25,
              onPressed: () {
                setState(() {
                  _showTableOfContents = !_showTableOfContents;
                });
              },
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _slides.isEmpty
                ? Center(
                  child: Text(
                    'No reading content available',
                    style: theme.textTheme.labelMedium,
                  ),
                )
                : Column(
                  children: [
                    // Progress bar
                    ProgressBar(
                      progress: progress,
                      currentSlideIndex: _currentSlideIndex,
                      slideLength: _slides.length,
                      slideName: 'page',
                    ),

                    // Main content
                    Expanded(
                      child:
                          _showTableOfContents
                              ? _buildTableOfContents()
                              : _isFirstLoad
                              ? _buildPageContent()
                              : _buildPageContent(),

                      // : SlideTransition(
                      //   position: _slideAnimation,
                      //   child: _buildPageContent(),
                      // ),
                    ),

                    // Navigation controls
                    _buildNavigationBar(),

                    SizedBox(height: 15),
                  ],
                ),
      ),
    );
  }
}
