import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/material.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize Timezone data (needed for scheduling)
    tzdata.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap if needed
      },
    );
  }

  /// Cancels all currently scheduled and pending notifications.
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('All notifications cancelled.');
  }

  /// Schedules a daily repeating notification at the specified hour and minute.
  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
  }) async {
    final location = tz.local;
    
    // Set the target time for today
    var scheduledDate = tz.TZDateTime(
      location,
      tz.TZDateTime.now(location).year,
      tz.TZDateTime.now(location).month,
      tz.TZDateTime.now(location).day,
      hour, // Use the passed hour
      minute, // Use the passed minute
      0, 
    );

    // If the scheduled time is in the past today, schedule it for tomorrow
    if (scheduledDate.isBefore(tz.TZDateTime.now(location))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID
      'حان وقت الذكر اليومي! 🌙', // Title
      'لا تنسَ تسبيحاتك اليومية. العداد بانتظارك!', // Body
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_zikr_channel', 
          'تذكير الذكر اليومي', 
          channelDescription: 'تذكير يومي للذكر والتسبيح.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Key for daily repeat
    );
    debugPrint('Daily notification scheduled for $hour:$minute.');
  }

  /// Shows an immediate, non-scheduled notification for testing purposes.
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel_id',
      'Test Notification Channel',
      channelDescription: 'Channel for immediate test notifications.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      99, // Unique ID
      'تذكير فوري (اختبار) 🚀',
      'هذا اختبار لكي تتأكد من عمل التذكيرات بنجاح.',
      platformDetails,
      payload: 'test_payload',
    );
    debugPrint('Test notification fired.');
}
}