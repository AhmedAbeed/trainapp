import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 🔥 التغيير هنا: إزالة "settings:"
    await _notifications.initialize(settings);

    debugPrint('✅ Local Notifications initialized');
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'train_status_channel',
      'حالة القطارات',
      channelDescription: 'إشعارات تحديث حالة القطارات',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 🔥 التغيير هنا: إزالة "notificationDetails:" و "id:" و "title:" و "body:"
    await _notifications.show(
      id,
      title,
      body,
      details,
    );

    debugPrint('✅ إشعار محلي ظهر: $title');
  }
}