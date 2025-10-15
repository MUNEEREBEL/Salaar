// lib/screens/admin/notification_test_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../services/comprehensive_notification_service.dart';
import '../../theme/app_theme.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedNotificationType = 'info';
  String _selectedSound = 'xp_sound';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('🧪 Notification Test Center'),
        backgroundColor: AppTheme.darkSurface,
        foregroundColor: AppTheme.whiteColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🦁 Prabhas Notification Test',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test all notification types with Prabhas style Telugu messages',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Test Buttons
            const Text(
              'Quick Tests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.whiteColor,
              ),
            ),
            const SizedBox(height: 16),

            // Test notification buttons
            _buildTestButton(
              '🧪 Test Notification',
              'Send a basic test notification',
              () => ComprehensiveNotificationService.sendTestNotification(),
            ),

            const SizedBox(height: 12),

            _buildTestButton(
              '👷 Worker Assignment (User)',
              'Test worker assignment notification to user',
              () => ComprehensiveNotificationService.sendWorkerAssignmentToUser(
                workerName: 'Prabhas Worker',
                issueTitle: 'Test Issue',
                issueId: 'test_123',
              ),
            ),

            const SizedBox(height: 12),

            _buildTestButton(
              '🎯 Worker Assignment (Worker)',
              'Test worker assignment notification to worker',
              () => ComprehensiveNotificationService.sendWorkerAssignmentToWorker(
                issueTitle: 'Test Issue',
                issueId: 'test_123',
              ),
            ),

            const SizedBox(height: 12),

            _buildTestButton(
              '✅ Issue Completion',
              'Test issue completion notification',
              () => ComprehensiveNotificationService.sendIssueCompletionToUser(
                workerName: 'Prabhas Worker',
                issueTitle: 'Test Issue',
                issueId: 'test_123',
              ),
            ),

            const SizedBox(height: 24),

            // Custom Admin Notifications
            const Text(
              'Custom Admin Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.whiteColor,
              ),
            ),
            const SizedBox(height: 16),

            // Notification type selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.greyColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.whiteColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeButton('info', '📢 Info', AppTheme.infoColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeButton('alert', '🚨 Alert', AppTheme.warningColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeButton('review', '⭐ Review', AppTheme.accentColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Message input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.greyColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Custom Message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.whiteColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    style: const TextStyle(color: AppTheme.whiteColor),
                    decoration: InputDecoration(
                      hintText: 'Enter your custom message...',
                      hintStyle: TextStyle(color: AppTheme.greyColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.greyColor.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.greyColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sound selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.greyColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification Sound',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.whiteColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedSound,
                    dropdownColor: AppTheme.darkSurface,
                    style: const TextStyle(color: AppTheme.whiteColor),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.greyColor.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.greyColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'xp_sound', child: Text('🎵 XP Sound')),
                      DropdownMenuItem(value: 'worker_assignment', child: Text('👷 Worker Assignment')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSound = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Send custom notification button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _sendCustomNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '🚀 Send Custom Notification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Random message generator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.greyColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Random Message Generator',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.whiteColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRandomButton('Worker to User', 'worker_to_user'),
                      _buildRandomButton('Worker to Worker', 'worker_to_worker'),
                      _buildRandomButton('Completion to User', 'completion_to_user'),
                      _buildRandomButton('Admin Info', 'admin_info'),
                      _buildRandomButton('Admin Alert', 'admin_alert'),
                      _buildRandomButton('Admin Review', 'admin_review'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String title, String subtitle, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.darkSurface,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.greyColor.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.whiteColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.greyColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.greyColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, Color color) {
    final isSelected = _selectedNotificationType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNotificationType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppTheme.greyColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : AppTheme.greyColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRandomButton(String label, String category) {
    return ElevatedButton(
      onPressed: () {
        final message = ComprehensiveNotificationService.getRandomMessage(category);
        _messageController.text = message;
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentColor.withOpacity(0.2),
        foregroundColor: AppTheme.accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _sendCustomNotification() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final userIds = ['current_user']; // In real app, get from user list

    switch (_selectedNotificationType) {
      case 'info':
        ComprehensiveNotificationService.sendAdminInfoNotification(
          message: message,
          userIds: userIds,
        );
        break;
      case 'alert':
        ComprehensiveNotificationService.sendAdminAlertNotification(
          message: message,
          userIds: userIds,
        );
        break;
      case 'review':
        ComprehensiveNotificationService.sendAdminReviewNotification(
          message: message,
          userIds: userIds,
        );
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_selectedNotificationType notification sent!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}
