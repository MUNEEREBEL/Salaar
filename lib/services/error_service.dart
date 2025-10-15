// lib/services/error_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ErrorType {
  success,
  warning,
  error,
  info,
}

class ErrorService {
  // Log to terminal with rich formatting
  static void logToTerminal({
    required String message,
    required String type, // INFO, WARNING, ERROR, SUCCESS
    dynamic error,
    StackTrace? stackTrace,
    String? context,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final emoji = _getEmojiForType(type);
    
    print('$emoji [$timestamp] $type: $message');
    
    if (context != null) {
      print('   📍 Context: $context');
    }
    
    if (error != null) {
      print('   🚨 Error: $error');
    }
    
    if (stackTrace != null) {
      print('   📋 StackTrace: $stackTrace');
    }
    
    print(''); // Empty line for separation
  }
  
  // Show to user via SnackBar
  static void showToUser({
    required BuildContext context,
    required String message,
    required ErrorType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    final snackBar = _buildErrorSnackBar(message, type, duration);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  // Combined method for auth errors
  static void handleAuthError({
    required BuildContext context,
    required dynamic error,
    StackTrace? stackTrace,
    String? customMessage,
    String? contextInfo,
  }) {
    // Log technically
    logToTerminal(
      message: customMessage ?? 'Authentication error occurred',
      type: 'ERROR',
      error: error,
      stackTrace: stackTrace,
      context: contextInfo ?? 'AuthError',
    );
    
    // Show user-friendly message
    final userMessage = ErrorMessages.getUserMessage(error, customMessage);
    showToUser(
      context: context,
      message: userMessage,
      type: ErrorType.error,
    );
  }
  
  // Show success message
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showToUser(
      context: context,
      message: message,
      type: ErrorType.success,
      duration: duration,
    );
  }
  
  // Show warning message
  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    showToUser(
      context: context,
      message: message,
      type: ErrorType.warning,
      duration: duration,
    );
  }
  
  // Show info message
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showToUser(
      context: context,
      message: message,
      type: ErrorType.info,
      duration: duration,
    );
  }
  
  // Error dialog for critical errors
  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              buttonText ?? 'OK',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build themed SnackBar
  static SnackBar _buildErrorSnackBar(String message, ErrorType type, Duration duration) {
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case ErrorType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case ErrorType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case ErrorType.error:
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case ErrorType.info:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
    }
    
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  
  static String _getEmojiForType(String type) {
    switch (type) {
      case 'INFO': return 'ℹ️';
      case 'WARNING': return '⚠️';
      case 'ERROR': return '❌';
      case 'SUCCESS': return '✅';
      default: return '📝';
    }
  }
}

class ErrorMessages {
  static const Map<String, String> authErrorMap = {
    'Database error querying schema': 
        'Our authentication system is currently experiencing technical difficulties. This is affecting both sign in and sign up. Our team has been notified.',
    'Database error saving new user':
        'We cannot create new accounts at the moment due to a technical issue. Our engineering team is working to resolve this quickly.',
    'unexpected_failure':
        'Authentication services are temporarily unavailable. Please try again in 15-30 minutes.',
    'Invalid login credentials': 
        'Invalid username/email or password. Please check your credentials.',
    'Email not confirmed':
        'Please check your email to verify your account before signing in.',
    'User already registered':
        'An account with this email already exists. Please sign in instead.',
    'weak_password':
        'Password is too weak. Please use a stronger password.',
    'network_error':
        'Network connection failed. Please check your internet and try again.',
    'User not found':
        'No account found with this username. Please check your username or create an account.',
    'Username already taken':
        'This username is already taken. Please choose a different username.',
    'Email already exists':
        'An account with this email already exists. Please sign in instead.',
    'Password too short':
        'Password must be at least 6 characters long.',
    'Invalid email format':
        'Please enter a valid email address.',
    'Username too short':
        'Username must be at least 3 characters long.',
    'Invalid username format':
        'Username can only contain letters, numbers, and underscores.',
  };
  
  static String getUserMessage(dynamic error, [String? customMessage]) {
    if (customMessage != null) {
      return customMessage;
    }
    
    if (error is AuthException) {
      return authErrorMap[error.message] ?? 
        'An unexpected authentication error occurred. Please try again.';
    }
    
    if (error is PostgrestException) {
      return 'Database connection error. Please try again.';
    }
    
    if (error.toString().contains('network') || error.toString().contains('connection')) {
      return 'Network connection failed. Please check your internet and try again.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
}
