// lib/services/comprehensive_notification_service.dart
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ComprehensiveNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final Random _random = Random();
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final List<Map<String, dynamic>> _notificationQueue = [];
  static bool _isOnline = true;

  // Prabhas Telugu Messages - Worker Assignment to User
  static final List<String> _workerAssignmentToUser = [
    "**{worker_name}** ni assign chesaam... *Darling* laga fix chestaadu! 🚀",
    "**{worker_name}** ready ga unnaadu... *Baahubali* laga problem ni destroy chestaadu! 💪",
    "*Rebel* ga *{worker_name}* ni pampaamu... Issue ni settle chestaadu! 🔥",
    "**{worker_name}** *Salaar* laga vastunnadu... Mee issue ni control lo ki testaadu! ⚡",
    "*Mirchi* laga speed tho *{worker_name}* fix chestaadu! 🌶️",
    "**{worker_name}** *Chatrapati* laga mee issue ni protect chestaadu! 🛡️",
    "*Billa* style lo *{worker_name}* operation start chesaadu! 🎯",
    "**{worker_name}** *Mr. Perfect* laga perfect ga fix chestaadu! ✨",
    "*Action* start ayyindhi... *{worker_name}* mee issue solve chestaadu! 🎬",
    "**{worker_name}** *Varsham* laga relief istadu! ☔",
    "**{worker_name}** *Baahubali* laga force tho vastunnadu! 🦁",
    "*Rebel* attitude tho *{worker_name}* tackle chestaadu! 💥",
    "**{worker_name}** *Salaar* laga promise fulfill chestaadu! ⚡",
    "*Darling* laga cute ga fix chestaadu! 😎",
    "**{worker_name}** *Chatrapati* laga responsibility teesukunnadu! 🛡️",
  ];

  // Prabhas Telugu Messages - Worker Assignment to Worker
  static final List<String> _workerAssignmentToWorker = [
    "*Nenu assign chesina task... Baahubali laga complete chey!* 🦁",
    "*Rebel ga work cheyi... Inka evadu cheyaledu!* 💥",
    "*Salaar laga discipline tho work start cheyi!* ⚡",
    "*Darling laga smart ga problem solve cheyi!* 🎯",
    "*Nuvvu naa first soldier... Ilaage work cheyi!* 🎖️",
    "*Chatrapati laga responsibility teesukuni work cheyi!* 🛡️",
    "*Billa style lo mission complete cheyi!* 🔫",
    "*Mr. Perfect laga perfect work chupinchu!* ✨",
    "*Varsham laga relief ivvalli customers ki!* 🌧️",
    "*Action hero laga problem ni finish cheyi!* 🎬",
    "*Baahubali laga courage tho work cheyi!* 🦁",
    "*Rebel laga unique style lo solve cheyi!* 💥",
    "*Salaar laga loyalty chupinchu!* ⚡",
    "*Darling laga clever solutions implement cheyi!* 😎",
    "*Chatrapati laga dedication chupinchu!* 🛡️",
  ];

  // Prabhas Telugu Messages - Issue Completion to User
  static final List<String> _issueCompletionToUser = [
    "*Baahubali laga fix chesaamu! +20XP meeke!* 🏆 **{worker_name}**",
    "*Rebel style lo solve chesaam! +20XP meku gift!* 💝 **{worker_name}**",
    "*Salaar laga discipline tho complete chesaam! +20XP!* ⚡ **{worker_name}**",
    "*Darling laga smart fix! +20XP meeke!* 🎯 **{worker_name}**",
    "*Chatrapati laga protect chesaam mee issue! +20XP!* 🛡️ **{worker_name}**",
    "*Billa mission complete! +20XP Rebel points!* 🔫 **{worker_name}**",
    "*Mr. Perfect laga perfect fix! +20XP!* ✨ **{worker_name}**",
    "*Varsham laga relief icchaamu! +20XP!* ☔ **{worker_name}**",
    "*Mirchi laga fast fix! +20XP meeke!* 🌶️ **{worker_name}**",
    "*Action complete! Blockbuster fix! +20XP!* 🎬 **{worker_name}**",
    "*Baahubali laga powerful fix! +20XP!* 🦁 **{worker_name}**",
    "*Rebel laga different solution! +20XP!* 💥 **{worker_name}**",
    "*Salaar laga systematic fix! +20XP!* ⚡ **{worker_name}**",
    "*Darling laga intelligent solution! +20XP!* 😎 **{worker_name}**",
    "*Chatrapati laga secure fix! +20XP!* 🛡️ **{worker_name}**",
  ];

  // Prabhas Telugu Messages - Admin Info Notifications
  static final List<String> _adminInfo = [
    "*Baahubali dialogue: 'Nenu osthunna...' {message}* 📢",
    "*Rebel message: 'Inka evadu cheyaledu...' {message}* 💥",
    "*Salaar update: 'Discipline maintain cheyali...' {message}* ⚡",
    "*Darling info: 'Chusthunna...' {message}* 👀",
    "*Chatrapati news: 'Protect chesthunna...' {message}* 🛡️",
    "*Billa update: 'Mission progress...' {message}* 🔫",
    "*Mr. Perfect info: 'Perfect planning...' {message}* ✨",
    "*Varsham update: 'Relief on the way...' {message}* ☔",
  ];

  // Prabhas Telugu Messages - Admin Alert Notifications
  static final List<String> _adminAlert = [
    "*Baahubali alert: 'Maa inti peru Mahishmathi!' {message}* 🚨",
    "*Rebel warning: 'Naa style different!' {message}* ⚠️",
    "*Salaar notice: 'Naa rules follow avvali!' {message}* 🔔",
    "*Darling alert: 'Chala careful ga undali!' {message}* 🎯",
    "*Chatrapati warning: 'Protect cheyalsindhi!' {message}* 🛡️",
    "*Billa alert: 'Danger zone!' {message}* 🔫",
    "*Mr. Perfect notice: 'Perfect attention needed!' {message}* ✨",
    "*Varsham alert: 'Heavy updates incoming!' {message}* ☔",
  ];

  // Prabhas Telugu Messages - Admin Review Notifications
  static final List<String> _adminReview = [
    "*Baahubali request: 'Maa pani gurinchi cheppu!' {message}* ⭐",
    "*Rebel feedback: 'Naa style ela undhi?' {message}* 💬",
    "*Salaar opinion: 'Naa discipline gurinchi review ivvu!' {message}* 🎤",
    "*Darling survey: 'Smart ga unnaama?' {message}* 📝",
    "*Mr. Perfect question: 'Perfect ga cheppara?' {message}* ✨",
    "*Chatrapati feedback: 'Protection ela undhi?' {message}* 🛡️",
    "*Billa review: 'Mission success rate?' {message}* 🔫",
    "*Varsham opinion: 'Relief satisfaction?' {message}* ☔",
  ];

  // Sound mapping for different notification types
  static final Map<String, String> _soundMapping = {
    'baahubali': 'xp_sound',
    'rebel': 'task_sound',
    'salaar': 'task_sound',
    'darling': 'worker_assignment',
    'chatrapati': 'reminder_sound',
    'billa': 'worker_assignment',
    'perfect': 'xp_sound',
    'varsham': 'worker_assignment',
    'mirchi': 'reminder_sound',
    'action': 'xp_sound',
  };

  // Initialize comprehensive notification service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      print('🦁 Initializing Comprehensive Notification Service...');
      
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
      print('🦁 Comprehensive Notification Service initialized: $initialized');
      
      if (initialized == true) {
        _initialized = true;
        await _createNotificationChannels();
        await _requestPermissions();
        await _initializeNetworkMonitoring();
        await _processQueuedNotifications();
      }
      
    } catch (e) {
      print('🦁 Error initializing Comprehensive Notification Service: $e');
    }
  }

  // Create notification channels
  static Future<void> _createNotificationChannels() async {
    try {
      final channels = [
        AndroidNotificationChannel(
          'prabhas_channel',
          'Prabhas Notifications',
          description: 'Notifications from Salaar app with Prabhas style',
          importance: Importance.high,
          sound: const RawResourceAndroidNotificationSound('xp_sound'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 300, 100, 300]),
          showBadge: true,
          enableLights: true,
          ledColor: const Color(0xFFD4AF37),
        ),
        AndroidNotificationChannel(
          'admin_channel',
          'Admin Notifications',
          description: 'Admin notifications with custom sounds',
          importance: Importance.max,
          sound: const RawResourceAndroidNotificationSound('xp_sound'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          showBadge: true,
          enableLights: true,
          ledColor: const Color(0xFFFF6B35),
        ),
      ];

      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        for (final channel in channels) {
          await androidPlugin.createNotificationChannel(channel);
        }
      }
    } catch (e) {
      print('🦁 Error creating notification channels: $e');
    }
  }

  // Request permissions
  static Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    } catch (e) {
      print('🦁 Error requesting permissions: $e');
    }
  }

  // Initialize network monitoring
  static Future<void> _initializeNetworkMonitoring() async {
    try {
      Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
        _isOnline = result != ConnectivityResult.none;
        print('🦁 Network status changed: ${_isOnline ? "Online" : "Offline"}');
        
        if (_isOnline) {
          _processQueuedNotifications();
        }
      });
      
      // Check initial connectivity
      final result = await Connectivity().checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
    } catch (e) {
      print('🦁 Error initializing network monitoring: $e');
    }
  }

  // Get sound for message based on Prabhas movie theme
  static String _getSoundForMessage(String message) {
    final lowerMessage = message.toLowerCase();
    for (final entry in _soundMapping.entries) {
      if (lowerMessage.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'xp_sound'; // Default sound
  }

  // Send notification with network handling
  static Future<void> sendNotification({
    required String title,
    required String body,
    String? payload,
    String? soundFile,
    String channelId = 'prabhas_channel',
    bool isAdminNotification = false,
  }) async {
    try {
      final notificationData = {
        'title': title,
        'body': body,
        'payload': payload,
        'soundFile': soundFile ?? _getSoundForMessage(body),
        'channelId': isAdminNotification ? 'admin_channel' : channelId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (_isOnline) {
        await _sendNotificationImmediate(notificationData);
        await _saveNotificationToSupabase(notificationData);
      } else {
        await _queueNotification(notificationData);
      }
    } catch (e) {
      print('🦁 Error sending notification: $e');
    }
  }

  // Send notification immediately
  static Future<void> _sendNotificationImmediate(Map<String, dynamic> data) async {
    try {
      final finalSound = data['soundFile'] as String;
      print('🦁 Sending Prabhas notification: ${data['title']} with sound: $finalSound');
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        data['channelId'] as String,
        data['channelId'] == 'admin_channel' ? 'Admin Notifications' : 'Prabhas Notifications',
        channelDescription: 'Notifications from Salaar app with Prabhas style',
        importance: data['channelId'] == 'admin_channel' ? Importance.max : Importance.high,
        priority: data['channelId'] == 'admin_channel' ? Priority.max : Priority.high,
        icon: '@mipmap/ic_launcher',
        color: data['channelId'] == 'admin_channel' ? const Color(0xFFFF6B35) : const Color(0xFFD4AF37),
        enableVibration: true,
        vibrationPattern: data['channelId'] == 'admin_channel' 
            ? Int64List.fromList([0, 500, 200, 500])
            : Int64List.fromList([0, 300, 100, 300]),
        showWhen: true,
        autoCancel: true,
        ongoing: false,
        visibility: NotificationVisibility.public,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(finalSound),
        enableLights: true,
        ledColor: data['channelId'] == 'admin_channel' ? const Color(0xFFFF6B35) : const Color(0xFFD4AF37),
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
        data['title'] as String,
        data['body'] as String,
        details,
        payload: data['payload'] as String?,
      );
      print('🦁 Prabhas notification sent successfully');
    } catch (e) {
      print('🦁 Error sending immediate notification: $e');
    }
  }

  // Save notification to Supabase
  static Future<void> _saveNotificationToSupabase(Map<String, dynamic> data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('notifications').insert({
          'user_id': user.id,
          'title': data['title'],
          'message': data['body'],
          'type': data['channelId'] == 'admin_channel' ? 'admin' : 'system',
          'sound_file': data['soundFile'],
          'created_at': data['timestamp'],
        });
      }
    } catch (e) {
      print('🦁 Error saving notification to Supabase: $e');
    }
  }

  // Queue notification for offline delivery
  static Future<void> _queueNotification(Map<String, dynamic> data) async {
    try {
      _notificationQueue.add(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_queue', jsonEncode(_notificationQueue));
      print('🦁 Notification queued for offline delivery');
    } catch (e) {
      print('🦁 Error queuing notification: $e');
    }
  }

  // Process queued notifications when online
  static Future<void> _processQueuedNotifications() async {
    try {
      if (!_isOnline || _notificationQueue.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString('notification_queue');
      if (queueString != null) {
        final List<dynamic> queue = jsonDecode(queueString);
        
        for (final notificationData in queue) {
          await _sendNotificationImmediate(Map<String, dynamic>.from(notificationData));
          await _saveNotificationToSupabase(Map<String, dynamic>.from(notificationData));
        }
        
        _notificationQueue.clear();
        await prefs.remove('notification_queue');
        print('🦁 Processed ${queue.length} queued notifications');
      }
    } catch (e) {
      print('🦁 Error processing queued notifications: $e');
    }
  }

  // Worker assignment to user
  static Future<void> sendWorkerAssignmentToUser({
    required String workerName,
    required String issueTitle,
    String? issueId,
  }) async {
    final message = _workerAssignmentToUser[_random.nextInt(_workerAssignmentToUser.length)]
        .replaceAll('{worker_name}', workerName);
    
    await sendNotification(
      title: '👷 Worker Assigned',
      body: message,
      payload: issueId,
    );
  }

  // Worker assignment to worker
  static Future<void> sendWorkerAssignmentToWorker({
    required String issueTitle,
    String? issueId,
  }) async {
    final message = _workerAssignmentToWorker[_random.nextInt(_workerAssignmentToWorker.length)];
    
    await sendNotification(
      title: '🎯 New Task Assigned',
      body: message,
      payload: issueId,
    );
  }

  // Issue completion to user
  static Future<void> sendIssueCompletionToUser({
    required String workerName,
    required String issueTitle,
    String? issueId,
  }) async {
    final message = _issueCompletionToUser[_random.nextInt(_issueCompletionToUser.length)]
        .replaceAll('{worker_name}', workerName);
    
    await sendNotification(
      title: '✅ Issue Solved',
      body: message,
      payload: issueId,
      soundFile: 'xp_sound',
    );
  }

  // Admin info notification
  static Future<void> sendAdminInfoNotification({
    required String message,
    required List<String> userIds,
  }) async {
    final prabhasMessage = _adminInfo[_random.nextInt(_adminInfo.length)]
        .replaceAll('{message}', message);
    
    for (final userId in userIds) {
      await sendNotification(
        title: '📢 Admin Info',
        body: prabhasMessage,
        channelId: 'admin_channel',
        isAdminNotification: true,
      );
    }
  }

  // Admin alert notification
  static Future<void> sendAdminAlertNotification({
    required String message,
    required List<String> userIds,
  }) async {
    final prabhasMessage = _adminAlert[_random.nextInt(_adminAlert.length)]
        .replaceAll('{message}', message);
    
    for (final userId in userIds) {
      await sendNotification(
        title: '🚨 Admin Alert',
        body: prabhasMessage,
        channelId: 'admin_channel',
        isAdminNotification: true,
        soundFile: 'xp_sound',
      );
    }
  }

  // Admin review notification
  static Future<void> sendAdminReviewNotification({
    required String message,
    required List<String> userIds,
  }) async {
    final prabhasMessage = _adminReview[_random.nextInt(_adminReview.length)]
        .replaceAll('{message}', message);
    
    for (final userId in userIds) {
      await sendNotification(
        title: '⭐ Admin Review',
        body: prabhasMessage,
        channelId: 'admin_channel',
        isAdminNotification: true,
      );
    }
  }

  // Test notification
  static Future<void> sendTestNotification() async {
    await sendNotification(
      title: '🧪 Test Notification',
      body: '*Baahubali laga test chesaam! Salaar app ready!* 🦁',
      soundFile: 'xp_sound',
    );
  }

  // Get random Prabhas message for any category
  static String getRandomMessage(String category) {
    switch (category) {
      case 'worker_to_user':
        return _workerAssignmentToUser[_random.nextInt(_workerAssignmentToUser.length)];
      case 'worker_to_worker':
        return _workerAssignmentToWorker[_random.nextInt(_workerAssignmentToWorker.length)];
      case 'completion_to_user':
        return _issueCompletionToUser[_random.nextInt(_issueCompletionToUser.length)];
      case 'admin_info':
        return _adminInfo[_random.nextInt(_adminInfo.length)];
      case 'admin_alert':
        return _adminAlert[_random.nextInt(_adminAlert.length)];
      case 'admin_review':
        return _adminReview[_random.nextInt(_adminReview.length)];
      default:
        return _workerAssignmentToUser[_random.nextInt(_workerAssignmentToUser.length)];
    }
  }

  // Replace placeholders in message
  static String replacePlaceholders(String message, Map<String, String> placeholders) {
    String result = message;
    placeholders.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
