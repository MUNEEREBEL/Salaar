// lib/services/maintenance_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaintenanceService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _maintenanceKey = 'maintenance_mode';
  static const String _maintenanceMessageKey = 'maintenance_message';

  /// Get current maintenance status
  static Future<Map<String, dynamic>> getMaintenanceStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'is_maintenance': prefs.getBool(_maintenanceKey) ?? false,
        'message': prefs.getString(_maintenanceMessageKey) ?? 'Server is under maintenance. Please try again later.',
      };
    } catch (e) {
      print('Error getting maintenance status: $e');
      return {
        'is_maintenance': false,
        'message': 'Server is under maintenance. Please try again later.',
      };
    }
  }

  /// Set maintenance mode
  static Future<bool> setMaintenanceMode(bool isMaintenance, String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_maintenanceKey, isMaintenance);
      await prefs.setString(_maintenanceMessageKey, message);
      
      // Also store in Supabase for global access
      await _supabase.from('app_settings').upsert({
        'key': 'maintenance_mode',
        'value': isMaintenance.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      await _supabase.from('app_settings').upsert({
        'key': 'maintenance_message',
        'value': message,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('Error setting maintenance mode: $e');
      return false;
    }
  }

  /// Check if app is in maintenance mode
  static Future<bool> isMaintenanceMode() async {
    try {
      final status = await getMaintenanceStatus();
      return status['is_maintenance'] ?? false;
    } catch (e) {
      print('Error checking maintenance mode: $e');
      return false;
    }
  }

  /// Get maintenance message
  static Future<String> getMaintenanceMessage() async {
    try {
      final status = await getMaintenanceStatus();
      return status['message'] ?? 'Server is under maintenance. Please try again later.';
    } catch (e) {
      print('Error getting maintenance message: $e');
      return 'Server is under maintenance. Please try again later.';
    }
  }
}
