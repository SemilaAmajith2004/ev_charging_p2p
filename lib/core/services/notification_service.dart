import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // ඕනෑම Booking Start Time එකකට Notifications Schedule කිරීම
  Future<void> scheduleBookingAlerts({
    required String bookingId,
    required DateTime bookingStartTime,
    required String stationName,
  }) async {
    final now = DateTime.now();

    // Booking ID එකෙන් Unique Integer ID එකක් සදාගැනීම
    final int reminderId = bookingId.hashCode.abs() % 100000;
    final int exactTimeId = reminderId + 1;

    // 1. Slot එකට විනාඩි 10කට පෙර Reminder එක (උදා: 9:50 AM, 2:20 PM)
    final tenMinsBefore = bookingStartTime.subtract(const Duration(minutes: 10));

    if (tenMinsBefore.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        reminderId,
        'Charging Slot Reminder ⚡',
        '$stationName හි ඔබගේ Slot එක විනාඩි 10කින් ආරම්භ වේ.',
        tz.TZDateTime.from(tenMinsBefore, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'booking_alerts',
            'Booking Slot Reminders',
            channelDescription: 'Reminders for upcoming EV charging slots',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    // 2. හරියටම Slot එක ආරම්භ වන වේලාවට Alert එක (උදා: 10:00 AM, 2:30 PM)
    if (bookingStartTime.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        exactTimeId,
        'Slot Started! 🔌',
        'ඔබගේ Charging Slot එක දැන් සක්‍රියයි. Station එකට පැමිණ Profile එකෙන් "MARK AS ARRIVED" ලබා දෙන්න.',
        tz.TZDateTime.from(bookingStartTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'booking_alerts',
            'Booking Slot Reminders',
            channelDescription: 'Reminders for upcoming EV charging slots',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  // Booking එකක් Cancel කළහොත් Notification එක Cancel කිරීම
  Future<void> cancelBookingAlerts(String bookingId) async {
    final int reminderId = bookingId.hashCode.abs() % 100000;
    await _notificationsPlugin.cancel(reminderId);
    await _notificationsPlugin.cancel(reminderId + 1);
  }
}