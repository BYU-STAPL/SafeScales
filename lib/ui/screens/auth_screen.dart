import 'package:flutter/material.dart';
import 'package:safe_scales/services/auth_service.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/ui/screens/login/class_selection_screen.dart';
import 'package:safe_scales/ui/screens/set_password_screen.dart';
import 'package:safe_scales/utils/supabase_errors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  bool _setupLoading = false;
  bool _obscurePassword = true;
  bool _showLegacyHelp = false;
  String? _formError;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  final _userState = UserStateService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      _formError = null;
    });

    try {
      if (isLogin) {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (_userState.needsPasswordSetup() || _userState.passwordRecovery) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SetPasswordScreen()),
          );
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ClassSelectionScreen(),
          ),
        );
      } else {
        await _authService.signUp(
          username: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        setState(() {
          isLogin = true;
        });
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Account created successfully! Please log in.',
            ),
            backgroundColor: theme.colorScheme.secondaryContainer,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message = getErrorMessage(e, isLogin ? 'Login failed' : 'Sign up failed');
      setState(() {
        _formError = message;
        _showLegacyHelp = isLogin;
      });
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: theme.colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _requestPasswordSetupEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _formError =
            'Enter your email above, then request a password setup link.';
      });
      return;
    }

    setState(() {
      _setupLoading = true;
      _formError = null;
    });

    try {
      await _authService.requestPasswordSetupEmail(email);
      if (!mounted) return;
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Check your email for a link to set a new password.',
          ),
          backgroundColor: theme.colorScheme.secondaryContainer,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _formError = getErrorMessage(e, 'Could not send password setup email');
      });
    } finally {
      if (mounted) {
        setState(() {
          _setupLoading = false;
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
          child: Center(
            child: Stack(
              children: [
                _authService.currentUser == null
                    ? Align(
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
                    )
                    : const SizedBox.shrink(),
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
                                isLogin ? 'Welcome Back!' : 'Create Account',
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 24),
                              if (_formError != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _formError!,
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (!isLogin)
                                TextFormField(
                                  style: theme.textTheme.labelLarge,
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    labelStyle: theme.textTheme.labelLarge,
                                    prefixIcon: Icon(
                                      Icons.person,
                                      size: 24 * AppTheme.fontSizeScale,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color:
                                            theme.colorScheme.surfaceContainer,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (!isLogin &&
                                        (value == null || value.isEmpty)) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                              if (!isLogin) const SizedBox(height: 16),
                              TextFormField(
                                style: theme.textTheme.labelLarge,
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: theme.textTheme.labelLarge,
                                  prefixIcon: Icon(
                                    Icons.email,
                                    size: 24 * AppTheme.fontSizeScale,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.surfaceContainer,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                style: theme.textTheme.labelLarge,
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: theme.textTheme.labelLarge,
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    size: 24 * AppTheme.fontSizeScale,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      size: 24 * AppTheme.fontSizeScale,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.surfaceContainer,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              if (isLogin) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed:
                                        _setupLoading
                                            ? null
                                            : _requestPasswordSetupEmail,
                                    child:
                                        _setupLoading
                                            ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : Text(
                                              'Forgot / set up password',
                                              style: TextStyle(
                                                fontSize:
                                                    14 * AppTheme.fontSizeScale,
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
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
                                          ? CircularProgressIndicator(
                                            color:
                                                theme.colorScheme.onPrimary,
                                          )
                                          : Text(
                                            isLogin ? 'Login' : 'Sign Up',
                                            style: TextStyle(
                                              fontSize:
                                                  16 * AppTheme.fontSizeScale,
                                              color:
                                                  theme.colorScheme.onPrimary,
                                            ),
                                          ),
                                ),
                              ),
                              if (_showLegacyHelp && isLogin) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Had an account before Auth migration? Your old password may no longer work. Enter your email above and send a setup link.',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton(
                                        onPressed:
                                            _setupLoading
                                                ? null
                                                : _requestPasswordSetupEmail,
                                        child: const Text(
                                          'Email me a password setup link',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    isLogin = !isLogin;
                                    _formError = null;
                                    _showLegacyHelp = false;
                                  });
                                },
                                child: Text(
                                  isLogin
                                      ? 'Don\'t have an account? Sign Up'
                                      : 'Already have an account? Login',
                                  style: TextStyle(
                                    fontSize: 14 * AppTheme.fontSizeScale,
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
      ),
    );
  }
}
