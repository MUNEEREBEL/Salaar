// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final notifications = await NotificationService.getUserNotifications(user.id);
        final unreadCount = await NotificationService.getUnreadNotificationCount(user.id);
        
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _unreadCount = unreadCount;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await NotificationService.markNotificationAsRead(notificationId);
      await _loadNotifications(); // Refresh the list
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      for (final notification in _notifications) {
        if (!(notification['is_read'] ?? false)) {
          await NotificationService.markNotificationAsRead(notification['id']);
        }
      }
      await _loadNotifications(); // Refresh the list
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: Text(
          'Notifications',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All Read',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['is_read'] ?? false;
                      
                      return GestureDetector(
                        onTap: () {
                          if (!isRead) {
                            _markAsRead(notification['id']);
                          }
                        },
                        child: NotificationCard(notification: notification),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            color: AppTheme.greyColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.whiteColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll receive notifications about your reports and tasks here',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.greyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
