// lib/providers/auth_provider_complete.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/error_service.dart';

class AuthProviderComplete extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  SalaarUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  SalaarUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isWorker => _currentUser?.role == 'worker';
  bool get isDeveloper => _currentUser?.role == 'developer';

  void clearError() {
    _error = null;
    notifyListeners();
  }


  AuthProviderComplete() {
    _isLoading = true;
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _supabase.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        
        print('Auth state change: $event');
        
        if (event == AuthChangeEvent.signedIn && session != null) {
          _error = null; // Clear any previous errors on successful login
          _loadUserProfile(session.user.id);
        } else if (event == AuthChangeEvent.signedOut) {
          _currentUser = null;
          // Don't clear error on sign out - let the UI handle it
          notifyListeners();
        }
      });

      // Check if user is already signed in
      final session = _supabase.auth.currentSession;
      print('Current session: ${session?.user?.id}');
      
      if (session != null) {
        await _loadUserProfile(session.user.id);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error initializing auth: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();

      _currentUser = SalaarUser.fromJson(response);
      _isLoading = false;
      _error = null;
      print('User profile loaded successfully: ${_currentUser?.username}');
      notifyListeners();
    } catch (e) {
      print('Error loading user profile: $e');

      // If profile doesn't exist, create a basic profile for the user
      try {
        final userResponse = await _supabase.auth.getUser();
        if (userResponse.user != null) {
          final user = userResponse.user!;
          await _supabase.from('profiles').insert({
            'id': user.id,
            'role': 'user',
            'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
            'username': user.email?.split('@')[0] ?? 'user_${user.id.substring(0, 8)}',
            'exp_points': 0,
            'issues_reported': 0,
            'issues_verified': 0,
            'created_at': DateTime.now().toIso8601String(),
          });

          // Retry loading profile after creating it
          final retryResponse = await _supabase
              .from('profiles')
              .select('*')
              .eq('id', userId)
              .single();

          _currentUser = SalaarUser.fromJson(retryResponse);
          _isLoading = false;
          notifyListeners();
          return;
        }
      } catch (profileError) {
        print('Error creating profile: $profileError');
      }

      // If we still can't load the profile, set error but don't leave user stuck
      _error = 'Unable to load user profile. Please try logging in again.';
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // SIGNUP WITH EMAIL/PASSWORD
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String username,
    String role = 'user',
  }) async {
    try {
      ErrorService.logToTerminal(
        message: 'Starting signup for: $email, username: $username, role: $role',
        type: 'INFO',
        context: 'AuthProviderComplete.signUpWithEmailPassword',
      );
      
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Validate inputs
      if (password.length < 6) {
        _error = 'Password must be at least 6 characters long.';
        _isLoading = false;
        notifyListeners();
        ErrorService.logToTerminal(
          message: 'Signup validation failed: Password too short',
          type: 'WARNING',
          context: 'AuthProviderComplete.signUpValidation',
        );
        return false;
      }

      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
        _error = 'Username can only contain letters, numbers, and underscores.';
        _isLoading = false;
        notifyListeners();
        ErrorService.logToTerminal(
          message: 'Signup validation failed: Invalid username format',
          type: 'WARNING',
          context: 'AuthProviderComplete.signUpValidation',
        );
        return false;
      }

      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
        _error = 'Please enter a valid email address.';
        _isLoading = false;
        notifyListeners();
        ErrorService.logToTerminal(
          message: 'Signup validation failed: Invalid email format',
          type: 'WARNING',
          context: 'AuthProviderComplete.signUpValidation',
        );
        return false;
      }

      // Check if username is available (with error handling)
      try {
        final usernameCheck = await _supabase
            .from('profiles')
            .select('id')
            .eq('username', username)
            .maybeSingle();

        if (usernameCheck != null) {
          _error = 'Username already taken. Please choose another.';
          _isLoading = false;
          notifyListeners();
          ErrorService.logToTerminal(
            message: 'Signup failed: Username already taken - $username',
            type: 'WARNING',
            context: 'AuthProviderComplete.signUpValidation',
          );
          return false;
        }
      } catch (e) {
        ErrorService.logToTerminal(
          message: 'Username check failed, continuing with signup: $e',
          type: 'WARNING',
          context: 'AuthProviderComplete.signUpValidation',
        );
        // Continue with signup even if username check fails
      }

      // Check if email is already registered (with error handling)
      try {
        final emailCheck = await _supabase
            .from('profiles')
            .select('id')
            .eq('email', email)
            .maybeSingle();

        if (emailCheck != null) {
          _error = 'Email already registered. Please use a different email or try signing in.';
          _isLoading = false;
          notifyListeners();
          ErrorService.logToTerminal(
            message: 'Signup failed: Email already registered - $email',
            type: 'WARNING',
            context: 'AuthProviderComplete.signUpValidation',
          );
          return false;
        }
      } catch (e) {
        ErrorService.logToTerminal(
          message: 'Email check failed, continuing with signup: $e',
          type: 'WARNING',
          context: 'AuthProviderComplete.signUpValidation',
        );
        // Continue with signup even if email check fails
      }

      // Create user account
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'username': username,
        },
      );

      if (response.user == null) {
        _error = 'Failed to create account. Please try again.';
        _isLoading = false;
        notifyListeners();
        ErrorService.logToTerminal(
          message: 'Signup failed: No user returned from auth.signUp',
          type: 'ERROR',
          context: 'AuthProviderComplete.signUpWithEmailPassword',
        );
        return false;
      }

      ErrorService.logToTerminal(
        message: 'Auth user created successfully: ${response.user!.id}',
        type: 'SUCCESS',
        context: 'AuthProviderComplete.signUpWithEmailPassword',
      );

      // Wait a moment for the trigger to create the profile
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if profile was created by trigger, if not create it manually
      try {
        final existingProfile = await _supabase
            .from('profiles')
            .select('id')
            .eq('id', response.user!.id)
            .maybeSingle();

        if (existingProfile == null) {
          // Create profile manually if trigger didn't work
          await _supabase.from('profiles').insert({
            'id': response.user!.id,
            'role': role,
            'full_name': fullName,
            'username': username,
            'email': email,
            'exp_points': 0,
            'issues_reported': 0,
            'issues_verified': 0,
            'created_at': DateTime.now().toIso8601String(),
          });

          ErrorService.logToTerminal(
            message: 'Profile created manually with role: $role',
            type: 'SUCCESS',
            context: 'AuthProviderComplete.signUpWithEmailPassword',
          );
        } else {
          // Update existing profile with correct role and details
          await _supabase.from('profiles').update({
            'role': role,
            'full_name': fullName,
            'username': username,
            'email': email,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', response.user!.id);

          ErrorService.logToTerminal(
            message: 'Profile updated with role: $role',
            type: 'SUCCESS',
            context: 'AuthProviderComplete.signUpWithEmailPassword',
          );
        }
      } catch (e) {
        ErrorService.logToTerminal(
          message: 'Profile creation/update failed: $e',
          type: 'WARNING',
          context: 'AuthProviderComplete.signUpWithEmailPassword',
        );
        // Continue anyway, profile might still work
      }

      // Load user profile
      await _loadUserProfile(response.user!.id);

      _isLoading = false;
      notifyListeners();

      ErrorService.logToTerminal(
        message: 'Signup successful for: $email',
        type: 'SUCCESS',
        context: 'AuthProviderComplete.signUpWithEmailPassword',
      );
      return _currentUser != null;
    } on AuthException catch (e, stackTrace) {
      _error = ErrorMessages.getUserMessage(e);
      _isLoading = false;
      notifyListeners();
      
      // Check if this is an auth database error
      if (e.message.contains('Database error') || e.message.contains('unexpected_failure')) {
        // Removed diagnostic calls - simplified error handling
      }
      
      ErrorService.logToTerminal(
        message: 'AuthException during signup: ${e.message}',
        type: 'ERROR',
        error: e,
        stackTrace: stackTrace,
        context: 'AuthProviderComplete.signUpWithEmailPassword',
      );
      return false;
    } catch (e, stackTrace) {
      _error = 'Sign up failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      ErrorService.logToTerminal(
        message: 'Unexpected error during signup',
        type: 'ERROR',
        error: e,
        stackTrace: stackTrace,
        context: 'AuthProviderComplete.signUpWithEmailPassword',
      );
      return false;
    }
  }

  // LOGIN WITH EMAIL/PASSWORD OR USERNAME
  Future<bool> loginWithEmailPassword(String emailOrUsername, String password) async {
    try {
      ErrorService.logToTerminal(
        message: 'Starting login for: $emailOrUsername',
        type: 'INFO',
        context: 'AuthProviderComplete.loginWithEmailPassword',
      );
      
      _isLoading = true;
      _error = null;
      notifyListeners();

      String email = emailOrUsername.trim();

      // If it's not an email format, try to find email from username
      if (!emailOrUsername.contains('@')) {
        try {
          ErrorService.logToTerminal(
            message: 'Looking up email for username: $emailOrUsername',
            type: 'INFO',
            context: 'AuthProviderComplete.usernameLookup',
          );
          
          // Use a simpler approach to avoid RLS recursion
          final profile = await _supabase
              .from('profiles')
              .select('email')
              .eq('username', emailOrUsername.toLowerCase())
              .limit(1);

          if (profile.isNotEmpty && profile[0]['email'] != null) {
            email = profile[0]['email'] as String;
            ErrorService.logToTerminal(
              message: 'Found email for username: $emailOrUsername -> $email',
              type: 'SUCCESS',
              context: 'AuthProviderComplete.usernameLookup',
            );
          } else {
            _error = 'Username not found';
            _isLoading = false;
            notifyListeners();
            ErrorService.logToTerminal(
              message: 'Username not found: $emailOrUsername',
              type: 'WARNING',
              context: 'AuthProviderComplete.usernameLookup',
            );
            return false;
          }
        } catch (e, stackTrace) {
          ErrorService.logToTerminal(
            message: 'Username lookup failed, treating as email: $e',
            type: 'WARNING',
            error: e,
            stackTrace: stackTrace,
            context: 'AuthProviderComplete.usernameLookup',
          );
          // If username lookup fails, treat the input as email and continue
          email = emailOrUsername;
        }
      }

      // Attempt login with email
      ErrorService.logToTerminal(
        message: 'Attempting login with email: $email',
        type: 'INFO',
        context: 'AuthProviderComplete.signInWithPassword',
      );
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _error = null;
        ErrorService.logToTerminal(
          message: 'Login successful for: ${response.user!.email}',
          type: 'SUCCESS',
          context: 'AuthProviderComplete.loginWithEmailPassword',
        );
        
        // Load user profile
        await _loadUserProfile(response.user!.id);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email/username or password';
        _isLoading = false;
        notifyListeners();
        ErrorService.logToTerminal(
          message: 'Login failed - no user returned',
          type: 'ERROR',
          context: 'AuthProviderComplete.signInWithPassword',
        );
        return false;
      }
    } on AuthException catch (e, stackTrace) {
      _error = ErrorMessages.getUserMessage(e);
      _isLoading = false;
      notifyListeners();
      
      // Check if this is an auth database error
      if (e.message.contains('Database error') || e.message.contains('unexpected_failure')) {
        // Removed diagnostic calls - simplified error handling
      }
      
      ErrorService.logToTerminal(
        message: 'AuthException during login: ${e.message}',
        type: 'ERROR',
        error: e,
        stackTrace: stackTrace,
        context: 'AuthProviderComplete.loginWithEmailPassword',
      );
      return false;
    } catch (e, stackTrace) {
      _error = 'Login failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      ErrorService.logToTerminal(
        message: 'Unexpected error during login',
        type: 'ERROR',
        error: e,
        stackTrace: stackTrace,
        context: 'AuthProviderComplete.loginWithEmailPassword',
      );
      return false;
    }
  }

  // PASSWORD RECOVERY
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Starting password reset for: $email');

      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _error = 'Please enter a valid email address';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _supabase.auth.resetPasswordForEmail(email);
      
      _isLoading = false;
      notifyListeners();
      print('Password reset email sent to: $email');
      return true;
    } on AuthException catch (e) {
      print('AuthException during password reset: ${e.message}');
      _error = 'Failed to send reset email. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Unexpected error during password reset: $e');
      _error = 'Failed to send reset email. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // CREATE PROFILE FOR GOOGLE USER
  Future<bool> createGoogleUserProfile(String username) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      if (user == null) {
        _error = 'No authenticated user found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if username is available
      final usernameAvailable = await checkUsernameAvailable(username);
      if (!usernameAvailable) {
        _error = 'Username is already taken';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create profile for Google user
      await _supabase.from('profiles').insert({
        'id': user.id,
        'role': 'user',
        'full_name': user.userMetadata?['full_name'] ?? 'Google User',
        'username': username,
        'email': user.email!,
        'exp_points': 0,
        'issues_reported': 0,
        'issues_verified': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Load user profile
      await _loadUserProfile(user.id);
      
      _isLoading = false;
      notifyListeners();
      print('Google user profile created successfully with username: $username');
      return true;
    } catch (e) {
      print('Error creating Google user profile: $e');
      _error = 'Failed to create profile. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // GOOGLE SIGN IN
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (response.user != null) {
        // Check if profile exists
        try {
          await _supabase
              .from('profiles')
              .select('id, username')
              .eq('id', response.user!.id)
              .single();
          
          // Profile exists, load it
          await _loadUserProfile(response.user!.id);
          _isLoading = false;
          notifyListeners();
          return _currentUser != null;
        } catch (e) {
          // Profile doesn't exist, need to create one with username
          _isLoading = false;
          notifyListeners();
          
          // Return a special flag indicating username setup is needed
          _error = 'USERNAME_SETUP_NEEDED';
          return false;
        }
      } else {
        _error = 'Google sign in failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Google sign in failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _googleSignIn.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // RELOAD USER DATA
  Future<void> reloadUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _loadUserProfile(session.user.id);
      }
    } catch (e) {
      print('Error reloading user: $e');
    }
  }

  // UPDATE PROFILE
  Future<bool> updateProfile({
    String? fullName,
    String? bio,
    String? phoneNumber,
    String? username,
  }) async {
    try {
      if (_currentUser == null) return false;

      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (bio != null) updateData['bio'] = bio;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (username != null) updateData['username'] = username;

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', _currentUser!.id);

      await _loadUserProfile(_currentUser!.id);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Method to check if current user has a specific role
  bool hasRole(String role) {
    return _currentUser?.role == role;
  }

  // Method to check if user needs username setup (for Google sign-in)
  Future<bool> needsUsernameSetup() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', user.id);

      if (response != null && response.isNotEmpty) {
        final username = response[0]['username'];
        // Check if username is auto-generated (contains @ or is default format)
        return username == null ||
               username.contains('@') ||
               username.startsWith('user_') ||
               username.length < 3;
      }
      return true; // Profile doesn't exist or error occurred
    } catch (e) {
      print('Error checking username setup need: $e');
      return true;
    }
  }

  // Method to update user role (admin only)
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      if (!hasRole('admin')) {
        _error = 'Only admins can update user roles.';
        notifyListeners();
        return false;
      }

      await _supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);

      // If updating current user, reload profile
      if (userId == _currentUser?.id) {
        await _loadUserProfile(userId);
      }
      return true;
    } catch (e) {
      _error = 'Error updating user role: $e';
      notifyListeners();
      return false;
    }
  }

  // Check if username is available
  Future<bool> checkUsernameAvailable(String username) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      
      return response == null; // Available if no user found
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

}
