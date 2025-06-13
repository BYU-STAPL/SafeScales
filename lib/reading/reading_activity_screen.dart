import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/services/class_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/config/supabase_config.dart';

class ReadingActivityScreen extends StatefulWidget {
  final String topic;
  final String? moduleId;

  const ReadingActivityScreen({Key? key, required this.topic, this.moduleId})
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
  late AnimationController _pageController;
  late Animation<Offset> _slideAnimation;
  bool _isForward = true;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadSlides();
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
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
          }
        }
      }
    } catch (e) {
      print('Error loading slides: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsCompleted() async {
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

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error marking reading as completed: $e');
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
      _pageController.forward(from: 0.0).then((_) {
        setState(() {
          _currentSlideIndex++;
        });
      });
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
      _pageController.forward(from: 0.0).then((_) {
        setState(() {
          _currentSlideIndex--;
        });
      });
    }
  }

  void _toggleBookmark() {
    setState(() {
      if (_bookmarkedPages.contains(_currentSlideIndex)) {
        _bookmarkedPages.remove(_currentSlideIndex);
      } else {
        _bookmarkedPages.add(_currentSlideIndex);
      }
    });
  }

  void _jumpToPage(int index) {
    if (index >= 0 && index < _slides.length) {
      setState(() {
        _isForward = index > _currentSlideIndex;
        _isFirstLoad = false;
      });
      _pageController.forward(from: 0.0).then((_) {
        setState(() {
          _currentSlideIndex = index;
          _showTableOfContents = false;
        });
      });
    }
  }

  Widget _buildTableOfContents() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        itemCount: _slides.length,
        itemBuilder: (context, index) {
          final isBookmarked = _bookmarkedPages.contains(index);
          return ListTile(
            leading: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color:
                  isBookmarked ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(
              _slides[index]['headline'] ?? 'Page ${index + 1}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight:
                    index == _currentSlideIndex
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page ${_currentSlideIndex + 1}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              IconButton(
                icon: Icon(
                  _bookmarkedPages.contains(_currentSlideIndex)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
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
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _slides[_currentSlideIndex]['content'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 16,
              height: 1.8,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_currentSlideIndex + 1) / _slides.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reading Activity'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showTableOfContents ? Icons.close : Icons.menu_book),
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
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              )
              : Column(
                children: [
                  // Progress bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_currentSlideIndex + 1)} of ${_slides.length} pages',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main content
                  Expanded(
                    child:
                        _showTableOfContents
                            ? _buildTableOfContents()
                            : _isFirstLoad
                            ? _buildPageContent()
                            : SlideTransition(
                              position: _slideAnimation,
                              child: _buildPageContent(),
                            ),
                  ),
                  // Navigation controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed:
                              _currentSlideIndex > 0 ? _previousSlide : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _nextSlide,
                          icon: Icon(
                            _currentSlideIndex < _slides.length - 1
                                ? Icons.arrow_forward
                                : Icons.check,
                          ),
                          label: Text(
                            _currentSlideIndex < _slides.length - 1
                                ? 'Next'
                                : 'Complete',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
