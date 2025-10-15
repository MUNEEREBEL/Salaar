// lib/services/prabhas_notification_service.dart
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class PrabhasNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Worker Assignment - To User (15+ Prabhas Style Messages)
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
    "**{worker_name}** *Billa* laga mission mode lo unnaadu! 🔫",
    "*Mr. Perfect* laga systematic ga *{worker_name}* work chestaadu! ✨",
    "**{worker_name}** *Varsham* laga heavy relief istadu! 🌧️",
    "*Action* hero laga *{worker_name}* problem ni finish chestaadu! 🎬",
    "**{worker_name}** *Mirchi* laga spicy solution istadu! 🌶️",
  ];

  // Worker Assignment - To Worker (15+ Prabhas Style Messages)
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
    "*Billa laga precision tho work cheyi!* 🎯",
    "*Mr. Perfect laga systematic approach follow cheyi!* ✨",
    "*Varsham laga heavy impact create cheyi!* 🌧️",
    "*Mirchi laga spicy performance chupinchu!* 🌶️",
    "*Action laga blockbuster work cheyi!* 🎬",
  ];

  // Issue Completion - To User (15+ Prabhas Style Messages)
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
    "*Billa laga precision fix! +20XP!* 🎯 **{worker_name}**",
    "*Mr. Perfect laga flawless work! +20XP!* ✨ **{worker_name}**",
    "*Varsham laga heavy relief! +20XP!* 🌧️ **{worker_name}**",
    "*Mirchi laga spicy solution! +20XP!* 🌶️ **{worker_name}**",
    "*Action laga blockbuster completion! +20XP!* 🎬 **{worker_name}**",
  ];

  // Admin Notifications - Info Type (8 Prabhas Style Messages)
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

  // Admin Notifications - Alert Type (8 Prabhas Style Messages)
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

  // Admin Notifications - Review Type (8 Prabhas Style Messages)
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

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      print('🦁 Initializing Prabhas NotificationService...');
      
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
      print('🦁 Prabhas NotificationService initialized: $initialized');
      
      if (initialized == true) {
        _initialized = true;
        await _createNotificationChannel();
        await _requestPermissions();
      }
      
    } catch (e) {
      print('🦁 Error initializing Prabhas NotificationService: $e');
    }
  }

  // Create notification channel with Prabhas theme
  static Future<void> _createNotificationChannel() async {
    try {
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        'prabhas_channel',
        'Prabhas Salaar Notifications',
        description: 'Baahubali style notifications from Salaar app',
        importance: Importance.high,
        sound: const RawResourceAndroidNotificationSound('xp_sound'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
        showBadge: true,
        enableLights: true,
        ledColor: const Color(0xFFD4AF37), // Gold color
      );

      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        print('🦁 Prabhas notification channel created successfully');
      }
    } catch (e) {
      print('🦁 Error creating Prabhas notification channel: $e');
    }
  }

  // Request permissions
  static Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final bool? granted = await androidPlugin.requestNotificationsPermission();
        print('🦁 Android notification permission granted: $granted');
      }
      
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final bool? granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('🦁 iOS notification permission granted: $granted');
      }
    } catch (e) {
      print('🦁 Error requesting permissions: $e');
    }
  }

  // Send Prabhas style notification
  static Future<void> sendPrabhasNotification({
    required String title,
    required String body,
    String? payload,
    String soundFile = 'xp_sound',
  }) async {
    try {
      print('🦁 Sending Prabhas notification: $title');
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'prabhas_channel',
        'Prabhas Salaar Notifications',
        channelDescription: 'Baahubali style notifications from Salaar app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFD4AF37), // Gold color
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
        showWhen: true,
        autoCancel: true,
        ongoing: false,
        visibility: NotificationVisibility.public,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundFile),
        enableLights: true,
        ledColor: const Color(0xFFD4AF37),
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
      print('🦁 Prabhas notification sent successfully');
    } catch (e) {
      print('🦁 Error sending Prabhas notification: $e');
    }
  }

  // Get random worker assignment message for user
  static String getWorkerAssignmentToUser(String workerName) {
    final random = Random();
    String message = _workerAssignmentToUser[random.nextInt(_workerAssignmentToUser.length)];
    return message.replaceAll('{worker_name}', workerName);
  }

  // Get random worker assignment message for worker
  static String getWorkerAssignmentToWorker() {
    final random = Random();
    return _workerAssignmentToWorker[random.nextInt(_workerAssignmentToWorker.length)];
  }

  // Get random issue completion message for user
  static String getIssueCompletionToUser(String workerName) {
    final random = Random();
    String message = _issueCompletionToUser[random.nextInt(_issueCompletionToUser.length)];
    return message.replaceAll('{worker_name}', workerName);
  }

  // Get random admin info message
  static String getAdminInfoMessage(String message) {
    final random = Random();
    String template = _adminInfo[random.nextInt(_adminInfo.length)];
    return template.replaceAll('{message}', message);
  }

  // Get random admin alert message
  static String getAdminAlertMessage(String message) {
    final random = Random();
    String template = _adminAlert[random.nextInt(_adminAlert.length)];
    return template.replaceAll('{message}', message);
  }

  // Get random admin review message
  static String getAdminReviewMessage(String message) {
    final random = Random();
    String template = _adminReview[random.nextInt(_adminReview.length)];
    return template.replaceAll('{message}', message);
  }

  // Send worker assignment notification to user
  static Future<void> sendWorkerAssignmentToUser({
    required String workerName,
    required String issueTitle,
    required String issueId,
    required String userId,
  }) async {
    final message = getWorkerAssignmentToUser(workerName);
    await sendPrabhasNotification(
      title: 'Worker Assigned - Salaar Style! 🦁',
      body: message,
      payload: 'worker_assigned:$issueId:$userId',
      soundFile: 'worker_assignment',
    );
  }

  // Send worker assignment notification to worker
  static Future<void> sendWorkerAssignmentToWorker({
    required String issueTitle,
    required String issueId,
    required String workerId,
  }) async {
    final message = getWorkerAssignmentToWorker();
    await sendPrabhasNotification(
      title: 'New Task - Rebel Style! 💥',
      body: message,
      payload: 'task_assigned:$issueId:$workerId',
      soundFile: 'task_sound',
    );
  }

  // Send issue completion notification to user
  static Future<void> sendIssueCompletionToUser({
    required String workerName,
    required String issueTitle,
    required String issueId,
    required String userId,
  }) async {
    final message = getIssueCompletionToUser(workerName);
    await sendPrabhasNotification(
      title: 'Issue Solved - Baahubali Style! 🏆',
      body: message,
      payload: 'task_completed:$issueId:$userId',
      soundFile: 'xp_sound',
    );
  }

  // Send admin notification
  static Future<void> sendAdminNotification({
    required String message,
    required String type,
    required String userId,
  }) async {
    String title;
    String body;
    String soundFile;
    
    switch (type.toLowerCase()) {
      case 'info':
        title = 'Admin Info - Salaar Update! ⚡';
        body = getAdminInfoMessage(message);
        soundFile = 'xp_sound';
        break;
      case 'alert':
        title = 'Admin Alert - Rebel Warning! ⚠️';
        body = getAdminAlertMessage(message);
        soundFile = 'task_sound';
        break;
      case 'review':
        title = 'Admin Review - Baahubali Request! ⭐';
        body = getAdminReviewMessage(message);
        soundFile = 'worker_assignment';
        break;
      default:
        title = 'Admin Message - Salaar Style! 🦁';
        body = getAdminInfoMessage(message);
        soundFile = 'xp_sound';
    }
    
    await sendPrabhasNotification(
      title: title,
      body: body,
      payload: 'admin_notification:$userId:$type',
      soundFile: soundFile,
    );
  }

  // Send test notification
  static Future<void> sendTestNotification() async {
    await sendPrabhasNotification(
      title: '🧪 Test - Prabhas Style!',
      body: '*Baahubali laga test chesaam! Salaar app ready!* 🦁',
      payload: 'test',
    );
  }
}
