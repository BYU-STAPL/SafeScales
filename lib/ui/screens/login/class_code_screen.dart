import 'package:flutter/material.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/ui/screens/app_initialization_screen.dart'; // Import the new screen
import 'package:safe_scales/services/user_state_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class ClassCodeScreen extends StatefulWidget {
  const ClassCodeScreen({super.key});

  @override
  State<ClassCodeScreen> createState() => _ClassCodeScreenState();
}

class _ClassCodeScreenState extends State<ClassCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _userState = UserStateService();
  bool isLoading = false;

  @override
  void dispose() {
    _classCodeController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    //TODO: Move Direct database access code into a repository file

    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Clean the class code of any ANSI color codes and trim whitespace
        final cleanClassCode =
            _classCodeController.text
                .replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '')
                .trim();

        // Get class ID from class code (case-insensitive)
        final classResponseList = await SupabaseConfig.client
            .from('classes')
            .select('id, code')
            .ilike('code', cleanClassCode);

        if (classResponseList.isEmpty) {
          throw Exception('Invalid class code');
        }

        final classId = classResponseList[0]['id'];

        // Check if user with same username exists in the class
        final existingUserResponse =
            await SupabaseConfig.client
                .from('Users')
                .select()
                .eq('Username', _usernameController.text.trim())
                .maybeSingle();

        if (existingUserResponse != null) {
          // User exists, check if they're already in the class
          final joinedClasses = List<String>.from(
            existingUserResponse['joined_classes'] ?? [],
          );
          if (joinedClasses.contains(classId)) {
            // User has already joined this class - treat as sign-in
            final supabaseUser = supabase.User(
              id: existingUserResponse['id'],
              email: existingUserResponse['email'],
              createdAt: existingUserResponse['created_at'],
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              role: 'authenticated',
            );

            // Set the user as current user (sign them in)
            _userState.setUser(supabaseUser);
            _userState.setUserProfile(existingUserResponse);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Welcome back! Signed in successfully.'),
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
            return;
          }

          // User exists but not in this class - add class to user's joined_classes
          joinedClasses.add(classId);
          await SupabaseConfig.client
              .from('Users')
              .update({'joined_classes': joinedClasses})
              .eq('id', existingUserResponse['id']);

          // Set the user as current user
          final supabaseUser = supabase.User(
            id: existingUserResponse['id'],
            email: existingUserResponse['email'],
            createdAt: existingUserResponse['created_at'],
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            role: 'authenticated',
          );

          _userState.setUser(supabaseUser);
          _userState.setUserProfile(existingUserResponse);
        }
        else {

          // User doesn't already exist

          // Get modules for the class
          final classResponse = await SupabaseConfig.client
                  .from('classes')
                  .select('course_modules')
                  .eq('id', classId)
                  .single();

          // Initialize empty progress for each module
          Map<String, dynamic> initialReadingProgress = {};
          if (classResponse['course_modules'] != null) {
            for (var moduleId in classResponse['course_modules']) {
              initialReadingProgress[moduleId] = {
                'reading': {
                  'completed': false,
                  'completed_at': null,
                  'bookmarks': [],
                },
              };
            }
          }

          // Initialize dragons for each module
          final classAssetsResponse = await SupabaseConfig.client
              .from('classes')
              .select('assets')
              .eq('id', classId)
              .single();

          final classAssetList = List<Map<String, dynamic>>.from(classAssetsResponse['assets'] ?? []);


          Map<String, dynamic> initialDragonData = {};

          for (final asset in classAssetList) {
            if (asset['type'] != 'dragon') continue;

            final dragonId = asset['id'] as String?;
            if (dragonId == null) continue;

            initialDragonData[dragonId] = {
              'name': 'no name',
              'phases': ['egg'],
            };
          }


          // Create new user with initialized modules
          final newUserResponse =
              await SupabaseConfig.client
                  .from('Users')
                  .insert({
                    'Username': _usernameController.text.trim(),
                    'role': 'student',
                    'joined_classes': [classId],
                    'settings': {"fontSize": 1.0, "isDarkMode": false},
                    'dragons': initialDragonData,
                    'acquired_accessories': [],
                    'acquired_environments': [],
                    'dragon_preferred_phases': {},
                    'dragon_environments': {},
                    'dragon_dressup': {},
                    'reading_progress': initialReadingProgress,
                  })
                  .select()
                  .single();

          // Set the new user as current user
          final supabaseUser = supabase.User(
            id: newUserResponse['id'],
            email: newUserResponse['email'],
            createdAt: newUserResponse['created_at'],
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            role: 'authenticated',
          );

          _userState.setUser(supabaseUser);
          _userState.setUserProfile(newUserResponse);
        }

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    color: theme.colorScheme.surfaceContainer,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Join a Class',
                              style: theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 25),
                            TextFormField(
                              controller: _classCodeController,
                              decoration: InputDecoration(
                                labelText: 'Class Code',
                                prefixIcon: Icon(
                                  Icons.class_,
                                  size: 25 * AppTheme.fontSizeScale,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the class code';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(
                                  Icons.person,
                                  size: 24 * AppTheme.fontSizeScale,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a username';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? const CircularProgressIndicator()
                                        : Text(
                                          'Join Class',
                                          style: TextStyle(
                                            fontSize:
                                                16 * AppTheme.fontSizeScale,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
