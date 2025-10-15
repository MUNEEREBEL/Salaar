// lib/screens/auth/auth_screen_fixed.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../theme/app_theme.dart';
import '../../screens/citizen/main_app_screen.dart';
import '../../services/error_service.dart';
// import '../../services/auth_permission_diagnostics.dart'; // Removed - no longer needed

class AuthScreenFixed extends StatefulWidget {
  const AuthScreenFixed({super.key});

  @override
  State<AuthScreenFixed> createState() => _AuthScreenFixedState();
}

class _AuthScreenFixedState extends State<AuthScreenFixed> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    
    // Add listeners to clear errors when user starts typing
    _emailController.addListener(_clearErrorOnInput);
    _passwordController.addListener(_clearErrorOnInput);
    _usernameController.addListener(_clearErrorOnInput);
    _nameController.addListener(_clearErrorOnInput);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.removeListener(_clearErrorOnInput);
    _passwordController.removeListener(_clearErrorOnInput);
    _usernameController.removeListener(_clearErrorOnInput);
    _nameController.removeListener(_clearErrorOnInput);
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateEmailOrUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email or username is required';
    }
    // Allow both email format and username format (alphanumeric + underscore)
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value) &&
        !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Enter a valid email or username';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Only alphanumerics and underscore allowed';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<bool> _checkUsernameAvailable(String username) async {
    if (username.isEmpty || username.length < 3) return false;
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) return false;

    try {
      final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
      return await authProvider.checkUsernameAvailable(username);
    } catch (e) {
      return false;
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);

    // Removed maintenance check - no longer needed

    try {
      if (_isLogin) {
        // LOGIN - simplified
        final success = await authProvider.loginWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (success && mounted) {
          ErrorService.showSuccess(
            context: context,
            message: '✅ Successfully logged in!',
          );
          Navigator.pushReplacementNamed(context, '/home');
        } else if (mounted) {
          // Force update the error message from provider
          setState(() => _errorMessage = authProvider.error ?? 'Login failed');
          print('UI Error Message Set: $_errorMessage');
        }

      } else {
        // SIGN UP - simplified (remove email check)
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = 'Passwords do not match';
            _isLoading = false;
          });
          return;
        }

        // Only check username, not email
        final usernameAvailable = await _checkUsernameAvailable(_usernameController.text.trim());
        if (!usernameAvailable) {
          setState(() {
            _errorMessage = 'Username already taken';
            _isLoading = false;
          });
          return;
        }

        final success = await authProvider.signUpWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
        );

        if (success && mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Account created successfully! Logging you in...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Auto-login after successful signup
          final loginSuccess = await authProvider.loginWithEmailPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

          if (loginSuccess && mounted) {
            // Clear form
            _emailController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            _nameController.clear();
            _usernameController.clear();
            
            // Navigate to home
            Navigator.pushReplacementNamed(context, '/home');
          } else if (mounted) {
            // If auto-login fails, switch to login mode
            setState(() {
              _isLogin = true;
              _errorMessage = 'Account created! Please log in with your credentials.';
            });
          }
        } else if (mounted) {
          setState(() => _errorMessage = authProvider.error ?? 'Failed to create account');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
      final success = await authProvider.signInWithGoogle();

      if (success) {
        // Google sign in successful
        if (mounted) {
          ErrorService.showSuccess(
            context: context,
            message: '✅ Signed in with Google!',
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // Check if user needs to set up username
        if (authProvider.error == 'USERNAME_SETUP_NEEDED') {
          if (mounted) {
            await _showGoogleUsernameSetupDialog();
          }
        } else {
          // Google sign in failed
          if (mounted) {
            setState(() => _errorMessage = authProvider.error ?? 'Google sign in failed');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Google sign in error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showGoogleUsernameSetupDialog() async {
    final TextEditingController usernameController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: Text(
            'Set Your Username',
            style: TextStyle(color: AppTheme.whiteColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome! Please choose a unique username to continue.',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: usernameController,
                style: TextStyle(color: AppTheme.whiteColor),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username is required';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                    return 'Username can only contain letters, numbers, and underscores';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Sign out the user if they cancel
                Provider.of<AuthProviderComplete>(context, listen: false).signOut();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              onPressed: () async {
                final username = usernameController.text.trim();
                if (username.isNotEmpty && username.length >= 3) {
                  try {
                    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
                    final success = await authProvider.createGoogleUserProfile(username);

                    if (success) {
                      Navigator.of(context).pop();
                      if (mounted) {
                        ErrorService.showSuccess(
                          context: context,
                          message: '✅ Profile created successfully!',
                        );
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    } else {
                      if (mounted) {
                        ErrorService.showErrorDialog(
                          context: context,
                          title: 'Profile Creation Failed',
                          message: authProvider.error ?? 'Failed to create profile',
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ErrorService.showErrorDialog(
                        context: context,
                        title: 'Error',
                        message: 'Error creating profile. Please try again.',
                      );
                    }
                  }
                } else {
                  ErrorService.showWarning(
                    context: context,
                    message: 'Username must be at least 3 characters long.',
                  );
                }
              },
              child: Text(
                'Continue',
                style: TextStyle(color: AppTheme.whiteColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: Text(
            'Reset Password',
            style: TextStyle(color: AppTheme.whiteColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                style: TextStyle(color: AppTheme.whiteColor),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.email, color: AppTheme.primaryColor),
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isNotEmpty && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                  try {
                    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
                    final success = await authProvider.resetPassword(email);

                    Navigator.of(context).pop();
                    if (mounted) {
                      if (success) {
                        ErrorService.showSuccess(
                          context: context,
                          message: '✅ Password reset email sent! Check your inbox.',
                        );
                      } else {
                        ErrorService.showErrorDialog(
                          context: context,
                          title: 'Reset Failed',
                          message: authProvider.error ?? 'Failed to send reset email',
                        );
                      }
                    }
                  } catch (e) {
                    Navigator.of(context).pop();
                    if (mounted) {
                      ErrorService.showErrorDialog(
                        context: context,
                        title: 'Error',
                        message: 'Error sending reset email. Please try again.',
                      );
                    }
                  }
                } else {
                  ErrorService.showWarning(
                    context: context,
                    message: 'Please enter a valid email address.',
                  );
                }
              },
              child: Text(
                'Send Reset Email',
                style: TextStyle(color: AppTheme.whiteColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUsernameSetupDialog() async {
    final TextEditingController usernameController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must set username
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: Text(
            'Set Your Username',
            style: TextStyle(color: AppTheme.whiteColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please choose a unique username to continue:',
                style: TextStyle(color: AppTheme.greyColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                style: TextStyle(color: AppTheme.whiteColor),
                decoration: InputDecoration(
                  hintText: 'Enter username',
                  hintStyle: TextStyle(color: AppTheme.greyColor),
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Set Username',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
              onPressed: () async {
                final username = usernameController.text.trim();
                if (username.isNotEmpty && username.length >= 3) {
                  try {
                    // Update username in profile
                    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
                    final user = authProvider.currentUser;
                    if (user != null) {
                      // Update username using the auth provider's method
                      final success = await authProvider.updateProfile(
                        username: username,
                      );

                      if (success) {
                        Navigator.of(context).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Username set successfully!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to set username. Please try again.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error setting username. Please try again.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Username must be at least 3 characters long.'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _nameController.clear();
    _usernameController.clear();
    setState(() => _errorMessage = null);
    // Also clear provider error
    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
    authProvider.clearError();
  }

  void _clearErrorOnInput() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
      final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
      authProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Consumer<AuthProviderComplete>(
                builder: (context, authProvider, child) {
                  // Listen to auth provider error changes and update UI
                  if (authProvider.error != null && _errorMessage != authProvider.error) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _errorMessage = authProvider.error;
                        });
                        print('UI Error Updated from Provider: $_errorMessage');
                      }
                    });
                  }
                  
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // App Logo and Title
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified_user,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'SALAAR',
                            style: AppTheme.headlineLarge.copyWith(
                              color: AppTheme.whiteColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin ? 'Welcome Back - Sign in rebel' : 'Want to become Salaar, join now to make a difference',
                            style: AppTheme.bodyLarge.copyWith(
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            validator: _validateEmailOrUsername,
                            style: TextStyle(color: AppTheme.whiteColor),
                            decoration: InputDecoration(
                              labelText: 'Email or Username',
                              hintText: 'Enter your email or username',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                              filled: true,
                              fillColor: AppTheme.darkSurface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Username Field (only for sign up)
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _usernameController,
                              validator: _validateUsername,
                              style: TextStyle(color: AppTheme.whiteColor),
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                                filled: true,
                                fillColor: AppTheme.darkSurface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Name Field (only for sign up)
                            TextFormField(
                              controller: _nameController,
                              validator: (value) {
                                if (!_isLogin && (value == null || value.isEmpty)) {
                                  return 'Full name is required';
                                }
                                return null;
                              },
                              style: TextStyle(color: AppTheme.whiteColor),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(Icons.badge, color: AppTheme.primaryColor),
                                filled: true,
                                fillColor: AppTheme.darkSurface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            validator: _validatePassword,
                            obscureText: true,
                            style: TextStyle(color: AppTheme.whiteColor),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.lock, color: AppTheme.primaryColor),
                              filled: true,
                              fillColor: AppTheme.darkSurface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                            ),
                          ),

                          // Confirm Password Field (only for sign up)
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              validator: _validateConfirmPassword,
                              obscureText: true,
                              style: TextStyle(color: AppTheme.whiteColor),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                                filled: true,
                                fillColor: AppTheme.darkSurface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Error Message
                          if (_errorMessage != null) ...[
                            // Debug print
                            Builder(
                              builder: (context) {
                                print('Displaying error message in UI: $_errorMessage');
                                return Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, size: 20, color: Colors.red),
                                    onPressed: () {
                                      setState(() => _errorMessage = null);
                                      final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
                                      authProvider.clearError();
                                    },
                                  ),
                                ],
                              ),
                                );
                              },
                            ),
                          ],

                          // Submit Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: AppTheme.whiteColor)
                                  : Text(
                                      _isLogin ? 'Sign In' : 'Create Account',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.whiteColor,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Forgot Password Link (inside Form)
                          if (_isLogin)
                            GestureDetector(
                              onTap: () {
                                _showForgotPasswordDialog();
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Toggle between Login and Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? "Don't have an account? " : "Already have an account? ",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _clearForm();
                            });
                          },
                          child: Text(
                            _isLogin ? 'Create Account' : 'Sign In',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
