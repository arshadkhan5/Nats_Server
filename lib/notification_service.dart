import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await notifications.initialize(settings);
    await _createNotificationChannel();

    _isInitialized = true;
    print('✅ Notifications initialized');
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Important notifications for NATS messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  NotificationDetails _getNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'Important notifications for NATS messages',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        autoCancel: true,
        colorized: true,
        color: Colors.blue,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await notifications.show(
        id,
        title,
        body,
        _getNotificationDetails(),
        payload: payload,
      );
      print('✅ Notification shown: $title - $body');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }
}