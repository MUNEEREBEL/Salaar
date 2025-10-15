// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class NotificationService {
  static final _supabase = Supabase.instance.client;

  // Send notification to a specific user
  static Future<bool> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // 'info', 'success', 'warning', 'error'
    Map<String, dynamic>? data,
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

  // Send notification to multiple users
  static Future<bool> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notifications = userIds.map((userId) => {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
      }).toList();

      await _supabase.from('notifications').insert(notifications);
      return true;
    } catch (e) {
      print('Error sending notifications: $e');
      return false;
    }
  }

  // Task assignment notification to worker
  static Future<bool> sendTaskAssignmentNotification({
    required String workerId,
    required String issueTitle,
    required String issueId,
    required String priority,
  }) async {
    return await sendNotification(
      userId: workerId,
      title: '🎯 New Task Assigned',
      message: 'You have been assigned a new task: "$issueTitle" (Priority: ${priority.toUpperCase()})',
      type: 'info',
    );
  }

  // Worker assignment notification to user
  static Future<bool> sendWorkerAssignmentNotification({
    required String userId,
    required String issueTitle,
    required String workerName,
    required String issueId,
  }) async {
    return await sendNotification(
      userId: userId,
      title: '👷 Worker Assigned',
      message: 'Your issue "$issueTitle" has been assigned to worker: $workerName',
      type: 'success',
    );
  }

  // Task completion notification to user
  static Future<bool> sendTaskCompletionNotification({
    required String userId,
    required String issueTitle,
    required String workerName,
    required String issueId,
  }) async {
    return await sendNotification(
      userId: userId,
      title: '✅ Task Completed',
      message: 'Your issue "$issueTitle" has been completed by $workerName',
      type: 'success',
    );
  }

  // XP added notification to user
  static Future<bool> sendXPNotification({
    required String userId,
    required int xpAmount,
    required String reason,
    required int newLevel,
    required String levelName,
    bool leveledUp = false,
  }) async {
    String title = leveledUp ? '🎉 Level Up!' : '⭐ XP Earned';
    String message = leveledUp 
        ? 'Congratulations! You reached level $newLevel ($levelName) and earned $xpAmount XP!'
        : 'You earned $xpAmount XP for $reason';

    return await sendNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'success',
    );
  }

  // Get user notifications
  static Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Get unread notification count
  static Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Initialize notification service (placeholder for compatibility)
  static Future<void> initialize() async {
    // This method is called by app initialization service
    // No specific initialization needed for this service
    print('NotificationService initialized');
  }

  // Show status update notification (placeholder for compatibility)
  static Future<void> showStatusUpdateNotification({
    String? userId,
    required String issueTitle,
    required String newStatus,
    String? oldStatus,
    String? issueId,
  }) async {
    if (userId != null) {
      await sendNotification(
        userId: userId,
        title: '📋 Status Update',
        message: 'Your issue "$issueTitle" status has been updated to $newStatus',
        type: 'info',
      );
    }
  }

  // Show task assigned notification (placeholder for compatibility)
  static Future<void> showTaskAssignedNotification({
    String? userId,
    required String issueTitle,
    String? workerName,
    String? location,
    String? issueId,
  }) async {
    if (userId != null) {
      await sendWorkerAssignmentNotification(
        userId: userId,
        issueTitle: issueTitle,
        workerName: workerName ?? 'Worker',
        issueId: issueId ?? '',
      );
    }
  }

  // Show announcement notification (placeholder for compatibility)
  static Future<void> showAnnouncementNotification({
    String? userId,
    required String title,
    String? message,
    String? content,
  }) async {
    if (userId != null) {
      await sendNotification(
        userId: userId,
        title: '📢 $title',
        message: message ?? content ?? '',
        type: 'info',
      );
    }
  }
}

// Notification widget for displaying notifications
class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationCard({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] ?? 'info';
    final isRead = notification['is_read'] ?? false;
    
    Color getTypeColor() {
      switch (type) {
        case 'success': return AppTheme.successColor;
        case 'warning': return AppTheme.warningColor;
        case 'error': return AppTheme.errorColor;
        default: return AppTheme.infoColor;
      }
    }

    IconData getTypeIcon() {
      switch (type) {
        case 'success': return Icons.check_circle;
        case 'warning': return Icons.warning;
        case 'error': return Icons.error;
        default: return Icons.info;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? AppTheme.darkCard : AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getTypeColor().withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: getTypeColor().withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: getTypeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                getTypeIcon(),
                color: getTypeColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'] ?? 'Notification',
                    style: AppTheme.titleSmall.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'] ?? '',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.greyColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(notification['created_at']),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.greyColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: getTypeColor(),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}