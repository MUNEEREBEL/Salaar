// lib/services/basic_notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';

class BasicNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Initialize basic notifications
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      print('🔔 Initializing Basic NotificationService...');
      
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      final bool? initialized = await _notifications.initialize(settings);
      print('🔔 Basic NotificationService initialized: $initialized');
      
      if (initialized == true) {
        _initialized = true;
        await _createNotificationChannel();
        await _requestPermissions();
      }
      
    } catch (e) {
      print('🔔 Error initializing Basic NotificationService: $e');
    }
  }

  // Create notification channel
  static Future<void> _createNotificationChannel() async {
    try {
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        'salaar_channel',
        'Salaar Notifications',
        description: 'Notifications from Salaar app',
        importance: Importance.high,
        sound: const RawResourceAndroidNotificationSound('xp_sound'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300]),
        showBadge: true,
        enableLights: true,
        ledColor: const Color(0xFF2196F3),
      );

      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        print('🔔 Notification channel created successfully');
      }
    } catch (e) {
      print('🔔 Error creating notification channel: $e');
    }
  }

  // Request permissions
  static Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final bool? granted = await androidPlugin.requestNotificationsPermission();
        print('🔔 Android notification permission granted: $granted');
      }
    } catch (e) {
      print('🔔 Error requesting permissions: $e');
    }
  }

  // Send notification
  static Future<void> sendNotification({
    required String title,
    required String body,
    String? payload,
    String soundFile = 'xp_sound',
  }) async {
    try {
      print('🔔 Sending notification: $title with sound: $soundFile');
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'salaar_channel',
        'Salaar Notifications',
        channelDescription: 'Notifications from Salaar app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF2196F3),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300]),
        showWhen: true,
        autoCancel: true,
        ongoing: false,
        visibility: NotificationVisibility.public,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundFile),
        enableLights: true,
        ledColor: const Color(0xFF2196F3),
        ledOnMs: 1000,
        ledOffMs: 500,
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );
      print('🔔 Notification sent successfully with sound: $soundFile');
    } catch (e) {
      print('🔔 Error sending notification: $e');
    }
  }

  // Send test notification
  static Future<void> sendTestNotification() async {
    await sendNotification(
      title: '🧪 Test Notification',
      body: 'This is a test notification from Salaar!',
      payload: 'test',
    );
  }

  // Send task assignment notification
  static Future<void> sendTaskAssignmentNotification({
    required String workerId,
    required String issueTitle,
    required String issueId,
    required String priority,
  }) async {
    await sendNotification(
      title: 'New Task Assigned',
      body: 'You have been assigned: $issueTitle (Priority: $priority)',
      payload: 'task_assignment:$issueId:$workerId',
      soundFile: 'task_sound',
    );
  }

  // Send worker assignment notification
  static Future<void> sendWorkerAssignmentNotification({
    required String userId,
    required String issueTitle,
    required String workerName,
    required String issueId,
  }) async {
    await sendNotification(
      title: 'Worker Assigned',
      body: '$workerName has been assigned to your report: $issueTitle',
      payload: 'worker_assignment:$issueId:$userId',
      soundFile: 'worker_assignment',
    );
  }

  // Send task completion notification
  static Future<void> sendTaskCompletionNotification({
    required String userId,
    required String issueTitle,
    required String workerName,
    required String issueId,
  }) async {
    await sendNotification(
      title: 'Task Completed',
      body: 'Your report "$issueTitle" has been completed by $workerName!',
      payload: 'task_completion:$issueId:$userId',
      soundFile: 'xp_sound',
    );
  }

  // Send XP notification
  static Future<void> sendXPNotification({
    required String userId,
    required int xpAmount,
    required String reason,
  }) async {
    await sendNotification(
      title: 'XP Earned!',
      body: '+$xpAmount XP for $reason',
      payload: 'xp_earned:$xpAmount:$userId',
    );
  }

  // Send task creation notification
  static Future<void> sendTaskCreationNotification({
    required String userId,
    required String issueTitle,
    required String issueId,
    required String category,
  }) async {
    await sendNotification(
      title: 'Report Submitted',
      body: 'Your report "$issueTitle" has been submitted successfully!',
      payload: 'task_creation:$issueId:$userId',
      soundFile: 'xp_sound',
    );
  }
}
