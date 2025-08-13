import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/ui/screens/reading/reading_results_screen.dart';

import '../../../providers/course_provider.dart';
import '../../../services/old_class_service.dart';
import '../../widgets/progress_bar.dart';

class ReadingActivityScreen extends StatefulWidget {
  final String moduleId;

  const ReadingActivityScreen({Key? key, required this.moduleId})
      : super(key: key);

  @override
  State<ReadingActivityScreen> createState() => _ReadingActivityScreenState();
}

class _ReadingActivityScreenState extends State<ReadingActivityScreen> {
  final OldClassService _classService = OldClassService(SupabaseConfig.client);
  final UserStateService _userState = UserStateService();
  final PageController _pageController = PageController(initialPage: 0);

  List<Map<String, dynamic>> _slides = [];
  int _currentSlideIndex = 0;
  bool _isLoading = true;
  bool _showTableOfContents = false;
  Set<int> _bookmarkedPages = {};
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSlides() async {
    try {
      final moduleData = await _classService.getModuleById(widget.moduleId);
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
      if (user == null) return;

      final response = await _classService.supabase
          .from('Users')
          .select('modules')
          .eq('id', user.id)
          .single();

      if (response['modules'] != null) {
        final modulesData = Map<String, dynamic>.from(response['modules']);
        if (modulesData.containsKey(widget.moduleId) &&
            modulesData[widget.moduleId]['reading'] != null &&
            modulesData[widget.moduleId]['reading']['bookmarks'] != null) {
          final bookmarks = List<int>.from(
            modulesData[widget.moduleId]['reading']['bookmarks'],
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
      if (user == null) return;

      final response = await _classService.supabase
          .from('Users')
          .select('modules')
          .eq('id', user.id)
          .single();

      Map<String, dynamic> modulesData = {};
      if (response['modules'] != null) {
        modulesData = Map<String, dynamic>.from(response['modules']);
      }

      if (!modulesData.containsKey(widget.moduleId)) {
        modulesData[widget.moduleId] = {};
      }

      if (!modulesData[widget.moduleId].containsKey('reading')) {
        modulesData[widget.moduleId]['reading'] = {};
      }

      // Update only the bookmarks, preserve other reading data
      modulesData[widget.moduleId]['reading']['bookmarks'] =
          _bookmarkedPages.toList();

      await _classService.supabase
          .from('Users')
          .update({'modules': modulesData})
          .eq('id', user.id);
    } catch (e) {
      print('❌Error saving bookmarks: $e');
    }
  }

  Future<void> _markAsCompleted() async {
    try {
      final user = _userState.currentUser;
      if (user == null) return;

      // Save progress immediately when reading is completed
      await Provider.of<CourseProvider>(context, listen: false)
          .saveReadingProgress(
          lessonId: widget.moduleId, bookmarks: _bookmarkedPages);

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
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _markAsCompleted();
    }
  }

  void _previousSlide() {
    if (_currentSlideIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentSlideIndex = index;
    });
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

  void _toggleBookmark(int index) {
    setState(() {
      if (_bookmarkedPages.contains(index)) {
        _bookmarkedPages.remove(index);
      } else {
        _bookmarkedPages.add(index);
      }
    });
    _saveBookmarks();
  }

  void _jumpToPage(int index) {
    if (index >= 0 && index < _slides.length) {
      // Check if PageController is attached to a PageView
      if (_pageController.hasClients) {
        // Use jumpToPage for instant navigation without animation
        _pageController.jumpToPage(index);
      } else {
        // If PageController is not attached yet, just update the index
        // and close TOC. The PageView will be built with the correct initial page.
        setState(() {
          _currentSlideIndex = index;
        });

        // Use WidgetsBinding to ensure the PageView is built before jumping
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(index);
          }
        });
      }

      setState(() {
        _showTableOfContents = false;
      });
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
            leading: IconButton(
              iconSize: 22,
              icon: Icon(
                _bookmarkedPages.contains(index)
                    ? FontAwesomeIcons.solidBookmark
                    : FontAwesomeIcons.bookmark,
                color: _bookmarkedPages.contains(index)
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: () {
                _toggleBookmark(index);
              },
            ),
            title: Text(
              'P${index + 1}: ${_slides[index]['headline'] ?? 'Page ${index + 1}'}',
              style: index == _currentSlideIndex
                  ? Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontSize: 18)
                  : Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () => _jumpToPage(index),
          );
        },
      ),
    );
  }

  Widget _buildPageContent(int index) {
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
                'Page ${index + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              IconButton(
                iconSize: 22,
                icon: Icon(
                  _bookmarkedPages.contains(index)
                      ? FontAwesomeIcons.solidBookmark
                      : FontAwesomeIcons.bookmark,
                  color: _bookmarkedPages.contains(index)
                      ? theme.colorScheme.primary
                      : null,
                ),
                onPressed: () {
                  _toggleBookmark(index);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _slides[index]['headline'] ?? 'Reading Content',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Text(
            _slides[index]['content'] ?? '',
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
        body: _isLoading
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
            //TODO: When reading a user can scroll through the reading slides by swiping or clicking the next button
            // TODO: Is it better to only have one method of navigating through the slides?
            Expanded(
              child: _showTableOfContents
                  ? _buildTableOfContents()
                  : PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildPageContent(index);
                },
              ),
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