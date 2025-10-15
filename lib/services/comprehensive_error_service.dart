// lib/services/comprehensive_error_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class ComprehensiveErrorService {
  static final ComprehensiveErrorService _instance = ComprehensiveErrorService._internal();
  factory ComprehensiveErrorService() => _instance;
  ComprehensiveErrorService._internal();

  /// Handle authentication errors
  static void handleAuthError({
    required BuildContext context,
    required dynamic error,
    StackTrace? stackTrace,
    String? customMessage,
  }) {
    String userMessage = _getAuthErrorMessage(error, customMessage);
    
    _logError('AUTH_ERROR', error, stackTrace, customMessage);
    _showErrorSnackBar(context, userMessage, ErrorType.error);
  }

  /// Handle network errors
  static void handleNetworkError({
    required BuildContext context,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    _logError('NETWORK_ERROR', error, stackTrace);
    _showErrorSnackBar(context, AppConfig.networkErrorMessage, ErrorType.error);
  }

  /// Handle location errors
  static void handleLocationError({
    required BuildContext context,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    _logError('LOCATION_ERROR', error, stackTrace);
    _showErrorSnackBar(context, AppConfig.locationErrorMessage, ErrorType.error);
  }

  /// Handle permission errors
  static void handlePermissionError({
    required BuildContext context,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    _logError('PERMISSION_ERROR', error, stackTrace);
    _showErrorSnackBar(context, AppConfig.permissionDeniedMessage, ErrorType.warning);
  }

  /// Handle database errors
  static void handleDatabaseError({
    required BuildContext context,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    _logError('DATABASE_ERROR', error, stackTrace);
    _showErrorSnackBar(context, 'Database error. Please try again.', ErrorType.error);
  }

  /// Handle image upload errors
  static void handleImageUploadError({
    required BuildContext context,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    _logError('IMAGE_UPLOAD_ERROR', error, stackTrace);
    _showErrorSnackBar(context, 'Failed to upload image. Please try again.', ErrorType.error);
  }

  /// Handle general errors
  static void handleGeneralError({
    required BuildContext context,
    required dynamic error,
    StackTrace? stackTrace,
    String? customMessage,
  }) {
    _logError('GENERAL_ERROR', error, stackTrace, customMessage);
    _showErrorSnackBar(context, customMessage ?? AppConfig.unknownErrorMessage, ErrorType.error);
  }

  /// Show success message
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showErrorSnackBar(context, message, ErrorType.success, duration);
  }

  /// Show warning message
  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showErrorSnackBar(context, message, ErrorType.warning, duration);
  }

  /// Show info message
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showErrorSnackBar(context, message, ErrorType.info, duration);
  }

  /// Show error dialog
  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
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
            onPressed: () {
              Navigator.pop(context);
              onPressed?.call();
            },
            child: Text(
              buttonText ?? 'OK',
              style: const TextStyle(color: Color(0xFFD4AF37)),
            ),
          ),
        ],
      ),
    );
  }

  /// Log error to console
  static void _logError(String type, dynamic error, StackTrace? stackTrace, [String? customMessage]) {
    final timestamp = DateTime.now().toIso8601String();
    final emoji = _getEmojiForType(type);
    
    print('$emoji [$timestamp] $type: ${customMessage ?? error.toString()}');
    
    if (error != null) {
      print('   🚨 Error: $error');
    }
    
    if (stackTrace != null) {
      print('   📋 StackTrace: $stackTrace');
    }
    
    print(''); // Empty line for separation
  }

  /// Get user-friendly auth error message
  static String _getAuthErrorMessage(dynamic error, String? customMessage) {
    if (customMessage != null) {
      return customMessage;
    }
    
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Invalid username/email or password. Please check your credentials.';
        case 'Email not confirmed':
          return 'Please check your email to verify your account before signing in.';
        case 'User already registered':
          return 'An account with this email already exists. Please sign in instead.';
        case 'weak_password':
          return 'Password is too weak. Please use a stronger password.';
        case 'User not found':
          return 'No account found with this username. Please check your username or create an account.';
        case 'Username already taken':
          return 'This username is already taken. Please choose a different username.';
        case 'Email already exists':
          return 'An account with this email already exists. Please sign in instead.';
        case 'Password too short':
          return 'Password must be at least ${AppConfig.minPasswordLength} characters long.';
        case 'Invalid email format':
          return 'Please enter a valid email address.';
        case 'Username too short':
          return 'Username must be at least ${AppConfig.minUsernameLength} characters long.';
        case 'Invalid username format':
          return 'Username can only contain letters, numbers, and underscores.';
        default:
          return 'An authentication error occurred. Please try again.';
      }
    }
    
    if (error is PostgrestException) {
      return 'Database connection error. Please try again.';
    }
    
    if (error.toString().contains('network') || error.toString().contains('connection')) {
      return AppConfig.networkErrorMessage;
    }
    
    return AppConfig.unknownErrorMessage;
  }

  /// Show error snackbar
  static void _showErrorSnackBar(BuildContext context, String message, ErrorType type, [Duration? duration]) {
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
    
    final snackBar = SnackBar(
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
      duration: duration ?? const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Get emoji for error type
  static String _getEmojiForType(String type) {
    switch (type) {
      case 'AUTH_ERROR': return '🔐';
      case 'NETWORK_ERROR': return '🌐';
      case 'LOCATION_ERROR': return '📍';
      case 'PERMISSION_ERROR': return '🔒';
      case 'DATABASE_ERROR': return '🗄️';
      case 'IMAGE_UPLOAD_ERROR': return '📷';
      case 'GENERAL_ERROR': return '❌';
      default: return '📝';
    }
  }
}

enum ErrorType {
  success,
  warning,
  error,
  info,
}
