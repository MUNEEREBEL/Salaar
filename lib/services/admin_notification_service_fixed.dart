import 'package:supabase_flutter/supabase_flutter.dart';

class AdminNotificationServiceFixed {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Send notification to a specific user
  static Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  /// Send notification to all users with a specific role
  static Future<bool> sendNotificationToRole({
    required String role,
    required String title,
    required String message,
    String type = 'info',
  }) async {
    try {
      // Get all users with the specified role
      final usersResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('role', role);

      if (usersResponse.isEmpty) {
        print('No users found with role: $role');
        return false;
      }

      // Create notifications for all users
      final notifications = (usersResponse as List).map((user) => {
        'user_id': user['id'],
        'title': title,
        'message': message,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
      }).toList();

      await _supabase.from('notifications').insert(notifications);
      return true;
    } catch (e) {
      print('Error sending notification to role: $e');
      return false;
    }
  }

  /// Send notification to all users
  static Future<bool> sendNotificationToAll({
    required String title,
    required String message,
    String type = 'info',
  }) async {
    try {
      // Get all users
      final usersResponse = await _supabase
          .from('profiles')
          .select('id');

      if (usersResponse.isEmpty) {
        print('No users found');
        return false;
      }

      // Create notifications for all users
      final notifications = (usersResponse as List).map((user) => {
        'user_id': user['id'],
        'title': title,
        'message': message,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
      }).toList();

      await _supabase.from('notifications').insert(notifications);
      return true;
    } catch (e) {
      print('Error sending notification to all: $e');
      return false;
    }
  }

  /// Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('type, is_read');

      int total = response.length;
      int unread = response.where((n) => n['is_read'] == false).length;
      int read = total - unread;

      Map<String, int> typeCounts = {};
      for (var notification in response) {
        String type = notification['type'] ?? 'info';
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }

      return {
        'total': total,
        'unread': unread,
        'read': read,
        'type_counts': typeCounts,
      };
    } catch (e) {
      print('Error getting notification stats: $e');
      return {
        'total': 0,
        'unread': 0,
        'read': 0,
        'type_counts': {},
      };
    }
  }

  /// Get all users for notification selection
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, email, role')
          .order('full_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }
}
