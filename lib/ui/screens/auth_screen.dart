import 'package:flutter/material.dart';
import 'package:safe_scales/services/auth_service.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'login/class_selection_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        if (isLogin) {
          final success = await _authService.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          if (!success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid email or password'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() {
                isLoading = false;
              });
            }
            return;
          }

          // Navigate to class selection screen after successful login
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const ClassSelectionScreen(),
              ),
            );
          }
        } else {
          await _authService.signUp(
            username: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          if (mounted) {
            // Switch to login mode after successful signup
            setState(() {
              isLogin = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully! Please log in.'),
                backgroundColor: Colors.green,
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
  }

  Future<void> _developerLogin({required bool isKhaleel}) async {
    setState(() {
      isLoading = true;
    });

    try {

      bool success;

      if (isKhaleel) {
        success = await _authService.signIn(
          email: 'khamad@byu.edu',
          password: 'STPL@2025',
        );
      }
      else {
        success = await _authService.signIn(
          email: 'imapepsi@byu.edu',
          password: 'password',
        );
      }


      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Developer login failed'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      // Navigate to class selection screen after successful login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ClassSelectionScreen()),
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
              //Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Stack(
              children: [
                // Add back button at the top
                // Not using app bar, so that the linear gradient takes up whole screen
                // More aesthetic
                _authService.currentUser == null
                    ? Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    )
                    : SizedBox.shrink(),

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
                                            isLogin ? 'Login' : 'Sign Up',
                                            style: TextStyle(
                                              fontSize:
                                                  16 * AppTheme.fontSizeScale,
                                            ),
                                          ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              //TODO: Remove before release
                              // Developer login button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: isLoading ? null : () {
                                    _developerLogin(isKhaleel: true);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    'Dev: Khaleel',
                                    style: TextStyle(
                                      fontSize: 16 * AppTheme.fontSizeScale,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: isLoading ? null : () {
                                    _developerLogin(isKhaleel: false);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    'Dev: Mia',
                                    style: TextStyle(
                                      fontSize: 16 * AppTheme.fontSizeScale,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    isLogin = !isLogin;
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
