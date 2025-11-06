import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/material.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize Timezone data
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

  // 💡 [FIX] Method to cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('All notifications cancelled.');
  }


  // 💡 [REFACTOR] Scheduling function now accepts specific hour and minute
  Future<void> scheduleDailyNotification({
    required int hour, 
    required int minute, 
  }) async {
    // Get the local timezone (important for accurate scheduling)
    final location = tz.local;
    
    // Set the target time using the passed parameters
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
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
    );
    debugPrint('Daily notification scheduled for $hour:$minute.');
  }
}