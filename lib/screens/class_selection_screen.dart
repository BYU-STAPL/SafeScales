import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/main_navigation.dart';
import 'package:safe_scales/auth/auth_screen.dart';
import 'package:safe_scales/services/user_state_service.dart';

class ClassSelectionScreen extends StatefulWidget {
  const ClassSelectionScreen({super.key});

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> classes = [];
  String? error;
  final _userState = UserStateService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchClasses();
  }

  Future<void> _checkAuthAndFetchClasses() async {
    final currentUser = _userState.currentUser;
    if (currentUser == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
      return;
    }

    // Check if user has any joined classes
    try {
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select('joined_classes')
              .eq('id', currentUser.id)
              .single();

      final joinedClasses = response['joined_classes'] as List<dynamic>?;

      if (joinedClasses != null && joinedClasses.isNotEmpty) {
        // User has joined classes, skip to main navigation
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainNavigation(initialIndex: 0),
            ),
                (route) => false, // Remove all previous routes
          );
        }
        return;
      }
    } catch (e) {
      print('Error checking joined classes: $e');
    }

    // If no joined classes or error occurred, fetch available classes
    await _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final response = await SupabaseConfig.client
          .from('classes')
          .select()
          .eq('instructor_id', '6eacec45-30fa-4755-b21c-35bc2af187e7');

      setState(() {
        classes = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _joinClass(String classId) async {
    try {
      setState(() {
        isLoading = true;
      });

      // Verify user is still logged in
      final user = _userState.currentUser;
      if (user == null) {
        throw Exception('Please log in to join a class');
      }

      // Get current user's joined classes
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select('joined_classes')
              .eq('id', user.id)
              .single();

      List<String> joinedClasses = List<String>.from(
        response['joined_classes'] ?? [],
      );

      // Add new class if not already joined
      if (!joinedClasses.contains(classId)) {
        joinedClasses.add(classId);

        // Update user's joined classes
        await SupabaseConfig.client
            .from('Users')
            .update({'joined_classes': joinedClasses})
            .eq('id', user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully joined class!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to main navigation
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainNavigation(initialIndex: 0),
            ),
                (route) => false, // Remove all previous routes
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already joined this class'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () => Navigator.of(context).pop(),
      //   ),
      // ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              theme.colorScheme.lightBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
              children: [
                // Add back button at the top
                // Not using app bar, so that the linear gradient takes up whole screen
                // More aesthetic
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),

                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        SizedBox(height: 100),

                        Text(
                          'Available Classes',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select a class to join',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white
                          ),
                        ),
                        const SizedBox(height: 25),
                        if (isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (error != null)
                          Center(
                            child: Text(
                              'Error: $error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        else if (classes.isEmpty)
                            const Center(
                              child: Text(
                                'No classes available',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                itemCount: classes.length,
                                itemBuilder: (context, index) {
                                  final classData = classes[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: Text(
                                        classData['name'] ?? 'Unnamed Class',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontSize: 18 * AppTheme.fontSizeScale,
                                        ),
                                      ),
                                      subtitle: Text(
                                        classData['description'] ??
                                            'No description available',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: () => _joinClass(classData['id']),
                                        child: Text('Join Class'.toUpperCase()),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                      ],
                    ),
                  )


                )
              ],
            ),
          ),
        ),
    );
  }
}
