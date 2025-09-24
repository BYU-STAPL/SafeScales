import 'package:flutter/material.dart';
import 'package:safe_scales/services/auth_service.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/ui/screens/app_initialization_screen.dart'; // Import the new screen
import 'package:safe_scales/ui/screens/auth_screen.dart';
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
  final authService = AuthService();
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
      if (await authService.isUserInAnyClasses(currentUser.id)) {
        // User has joined classes, go to initialization screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AppInitializationScreen(),
            ),
                (route) => false, // Remove all previous routes
          );
        }
        return;
      }
    } catch (e) {
      print('❌Error checking joined classes: $e');
    }

    // If no joined classes or error occurred, fetch available classes
    await _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final response = await SupabaseConfig.client
          .from('classes')
          .select();

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

      if (await authService.joinClass(user.id, classId)) {

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully joined class!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to initialization screen instead of MainNavigation
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AppInitializationScreen(),
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