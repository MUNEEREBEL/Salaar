// lib/services/admin_notification_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AdminNotificationService {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notifications.initialize(initializationSettings);
  }

  /// Send notification to all users
  Future<bool> sendNotificationToAllUsers({
    required String title,
    required String message,
    String? adminId,
  }) async {
    try {
      // Store notification in database
      await Supabase.instance.client.from('notifications').insert({
        'title': title,
        'message': message,
        'type': 'admin_broadcast',
        'admin_id': adminId,
        'created_at': DateTime.now().toIso8601String(),
        'is_broadcast': true,
      });

      // Send local notification
      await _notifications.show(
        0,
        title,
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'admin_notifications',
            'Admin Notifications',
            channelDescription: 'Notifications sent by administrators',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );

      return true;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  /// Send notification to specific user
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    String? adminId,
  }) async {
    try {
      // Store notification in database
      await Supabase.instance.client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': 'admin_direct',
        'admin_id': adminId,
        'created_at': DateTime.now().toIso8601String(),
        'is_broadcast': false,
      });

      return true;
    } catch (e) {
      print('Error sending notification to user: $e');
      return false;
    }
  }

  /// Send notification to users by role
  Future<bool> sendNotificationToRole({
    required String role,
    required String title,
    required String message,
    String? adminId,
  }) async {
    try {
      // Get all users with the specified role
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('role', role);

      if (response is List && response.isNotEmpty) {
        // Store notification for each user
        final notifications = response.map((user) => {
          'user_id': user['id'],
          'title': title,
          'message': message,
          'type': 'admin_role',
          'admin_id': adminId,
          'created_at': DateTime.now().toIso8601String(),
          'is_broadcast': false,
        }).toList();

        await Supabase.instance.client.from('notifications').insert(notifications);
      }

      return true;
    } catch (e) {
      print('Error sending notification to role: $e');
      return false;
    }
  }

  /// Get all notifications for a user
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select('*')
          .or('user_id.eq.$userId,is_broadcast.eq.true')
          .order('created_at', ascending: false)
          .limit(50);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching user notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Get notification statistics
  Future<Map<String, int>> getNotificationStats() async {
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select('type, is_read');

      if (response is List) {
        int total = response.length;
        int unread = response.where((n) => n['is_read'] == false).length;
        int broadcasts = response.where((n) => n['is_broadcast'] == true).length;
        int direct = response.where((n) => n['is_broadcast'] == false).length;

        return {
          'total': total,
          'unread': unread,
          'broadcasts': broadcasts,
          'direct': direct,
        };
      }

      return {'total': 0, 'unread': 0, 'broadcasts': 0, 'direct': 0};
    } catch (e) {
      print('Error fetching notification stats: $e');
      return {'total': 0, 'unread': 0, 'broadcasts': 0, 'direct': 0};
    }
  }
}
