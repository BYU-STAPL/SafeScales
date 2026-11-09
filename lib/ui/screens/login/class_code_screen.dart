import 'package:flutter/material.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/ui/screens/app_initialization_screen.dart';
import 'package:safe_scales/services/user_state_service.dart';

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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final cleanClassCode =
          _classCodeController.text
              .replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '')
              .trim();
      final username = _usernameController.text.trim();

      final response = await SupabaseConfig.client.functions.invoke(
        'class-code-auth',
        body: {
          'classCode': cleanClassCode,
          'username': username,
        },
      );

      final data = response.data;
      if (data is! Map) {
        throw Exception('Unexpected response from class-code-auth');
      }

      if (response.status >= 400 || data['error'] != null) {
        throw Exception(
          data['error']?.toString() ??
              'Class code sign-in failed (${response.status})',
        );
      }

      final refreshToken = data['refresh_token']?.toString();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('Missing session tokens from class-code-auth');
      }

      final sessionResponse = await SupabaseConfig.client.auth.setSession(
        refreshToken,
      );

      final authUser =
          sessionResponse.user ?? SupabaseConfig.client.auth.currentUser;
      if (authUser == null) {
        throw Exception('Failed to establish authenticated session');
      }

      _userState.setUser(authUser);
      final profile = data['profile'];
      if (profile is Map<String, dynamic>) {
        _userState.setUserProfile(profile);
      } else if (profile is Map) {
        _userState.setUserProfile(Map<String, dynamic>.from(profile));
      } else {
        await _userState.loadUserProfile();
      }

      if (!mounted) return;

      final theme = Theme.of(context);
      final welcomeBack = data['welcome_back'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            welcomeBack
                ? 'Welcome back! Signed in successfully.'
                : 'Successfully joined class!',
          ),
          backgroundColor: theme.colorScheme.secondaryContainer,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AppInitializationScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: theme.colorScheme.errorContainer,
          ),
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
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.colorScheme.onPrimary,
                    ),
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
                              keyboardType: TextInputType.number,
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
