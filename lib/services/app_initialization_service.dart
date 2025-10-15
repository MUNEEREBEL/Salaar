// lib/services/app_initialization_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comprehensive_permission_service.dart';
import 'comprehensive_error_service.dart';
import 'notification_service.dart';
import 'basic_notification_service.dart';
import 'prabhas_notification_service.dart';
import 'realtime_service.dart';
import 'background_service.dart';
import '../config/app_config.dart';

class AppInitializationService {
  static final AppInitializationService _instance = AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;

  /// Initialize the entire app
  static Future<bool> initializeApp() async {
    final service = AppInitializationService();
    
    if (service._isInitialized) {
      return true;
    }
    
    if (service._isInitializing) {
      // Wait for initialization to complete
      while (service._isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return service._isInitialized;
    }
    
    service._isInitializing = true;
    
    try {
      print('🚀 Starting app initialization...');
      
      // Step 1: Initialize Supabase
      await _initializeSupabase();
      print('✅ Supabase initialized');
      
      // Step 2: Initialize permissions
      await _initializePermissions();
      print('✅ Permissions initialized');
      
      // Step 3: Initialize notifications
      await _initializeNotifications();
      print('✅ Notifications initialized');
      
      // Step 4: Initialize background services
      await _initializeBackgroundServices();
      print('✅ Background services initialized');
      
      // Step 5: Initialize realtime
      await _initializeRealtime();
      print('✅ Realtime initialized');
      
      service._isInitialized = true;
      print('🎉 App initialization completed successfully!');
      
      return true;
    } catch (e, stackTrace) {
      print('❌ App initialization failed: $e');
      print('📋 StackTrace: $stackTrace');
      service._isInitialized = false;
      return false;
    } finally {
      service._isInitializing = false;
    }
  }

  /// Initialize Supabase
  static Future<void> _initializeSupabase() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }

  /// Initialize permissions
  static Future<void> _initializePermissions() async {
    try {
      // Request all essential permissions
      await ComprehensivePermissionService.requestAllPermissions();
    } catch (e) {
      print('⚠️ Permission initialization failed: $e');
      // Don't throw here as permissions can be requested later
    }
  }

  /// Initialize notifications
  static Future<void> _initializeNotifications() async {
    try {
      await NotificationService.initialize();
      await BasicNotificationService.initialize();
      await PrabhasNotificationService.initialize();
    } catch (e) {
      print('⚠️ Notification initialization failed: $e');
      // Don't throw here as notifications are not critical
    }
  }

  /// Initialize background services
  static Future<void> _initializeBackgroundServices() async {
    try {
      await initializeService();
    } catch (e) {
      print('⚠️ Background service initialization failed: $e');
      // Don't throw here as background services are not critical
    }
  }

  /// Initialize realtime
  static Future<void> _initializeRealtime() async {
    try {
      // Set up auth state change listener
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          // Initialize real-time listeners when user logs in
          RealtimeService.initializeRealtimeListeners(session.user.id);
        } else {
          // Clean up when user logs out
          RealtimeService.dispose();
        }
      });
    } catch (e) {
      print('⚠️ Realtime initialization failed: $e');
      // Don't throw here as realtime is not critical
    }
  }

  /// Check if app is ready for use
  static bool isAppReady() {
    final service = AppInitializationService();
    return service._isInitialized;
  }

  /// Reset initialization state (for testing)
  static void reset() {
    final service = AppInitializationService();
    service._isInitialized = false;
    service._isInitializing = false;
  }

  /// Get initialization status
  static Map<String, dynamic> getInitializationStatus() {
    final service = AppInitializationService();
    return {
      'isInitialized': service._isInitialized,
      'isInitializing': service._isInitializing,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
