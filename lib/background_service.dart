import 'dart:async';
import 'dart:ui';
import 'package:dart_nats/dart_nats.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

final Client natsClient = Client();

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      autoStartOnBoot: true, // ✅ Restart after device reboot
      foregroundServiceNotificationId: 888,
      notificationChannelId: 'high_importance_channel',
      initialNotificationTitle: 'NATS Listener',
      initialNotificationContent: 'Listening for new alerts…',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Stop service when requested
  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  final notificationService = NotificationService();
  await notificationService.initialize();

  // Maintain persistent NATS connection
  while (true) {
    try {
      if (!natsClient.connected) {
        await natsClient.connect(
          Uri.parse("nats://161.97.129.123:4222"),
          connectOption: ConnectOption(user: 'arif', pass: 'arshad'),
        );
      }

      final sub = natsClient.sub('updates');
      sub?.stream.listen((Message msg) async {
        final String message = msg.string ?? 'New Alert';
        final lastTimestamp = prefs.getInt('last_message_timestamp') ?? 0;
        final currentTimestamp = DateTime.now().millisecondsSinceEpoch;

        if (currentTimestamp > lastTimestamp) {
          await notificationService.showNotification(
            title: "🚨 New Alert",
            body: message,
          );
          await prefs.setInt('last_message_timestamp', currentTimestamp);
        }
      });

      break; // ✅ Exit loop once connected successfully
    } catch (e) {
      print("NATS Background Error: $e");
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
