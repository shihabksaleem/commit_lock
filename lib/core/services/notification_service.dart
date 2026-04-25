import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Required for scheduling notifications based on timezones
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [],
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
      },
    );
    
    // Explicitly request permissions for iOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> showNotification({required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'commitment_completion',
      'Commitment Completion',
      channelDescription: 'Notifications for completed commitment sessions',
      importance: Importance.max,
      priority: Priority.high,
      // fullScreenIntent allows the app to launch the alarm UI directly from the background
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(id: id, title: title, body: body, notificationDetails: platformChannelSpecifics);
  }

  static Future<void> showOngoingNotification({
    required int id,
    required String title,
    required String body,
    double? progress, // 0.0 to 1.0
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'ongoing_session',
      'Ongoing Session',
      channelDescription: 'Shows progress of current commitment session',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showProgress: progress != null,
      maxProgress: 100,
      progress: progress != null ? (progress * 100).toInt() : 0,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(presentAlert: false, presentBadge: false, presentSound: false),
    );

    await _notificationsPlugin.show(id: id, title: title, body: body, notificationDetails: platformChannelSpecifics);
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  /// Schedules a high-priority alarm notification for a future time.
  /// This is used to ensure the completion alarm triggers even if the app is terminated.
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'commitment_completion',
          'Commitment Completion',
          channelDescription: 'Notifications for completed commitment sessions',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
