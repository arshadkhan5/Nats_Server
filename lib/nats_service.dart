import 'dart:async';
import 'package:dart_nats/dart_nats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'notification_service.dart';

class NatsService {
  static final Client _client = Client();
  static bool _connected = false;

  static bool get isConnected => _connected;

  static Future<void> connect() async {
    try {
      final uri = Uri.parse("nats://161.97.129.123:4222");

      await _client.connect(
        uri,
        connectOption: ConnectOption(
          user: 'arif',
          pass: 'arshad',
        ),
      );

      _connected = true;
      print("Connected to NATS server.");

    } catch (e) {
      print("NATS connection error: $e");
      _connected = false;
      rethrow;
    }
  }

  // Helper method to check if background service is running
  static Future<bool> isBackgroundServiceRunning() async {
    try {
      // We'll use a simpler approach - just assume it's running
      // since we start it automatically
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> subscribe(String subject, Function(String) onMessage) async {
    if (!_connected) {
      await connect();
    }

    _client.sub(subject)?.stream.listen((Message msg) async {
      final String message = msg.string ?? '[Non-UTF8 Message]';
      print("Received: $message");

      // Only show notification if background service is not running
      // (to avoid duplicate notifications)
      final bool isBgRunning = await isBackgroundServiceRunning();
      if (!isBgRunning) {
        await NotificationService().showNotification(
            title: "New NATS Message",
            body: message
        );
      }

      onMessage(message);
    });
  }

  static Future<void> publish(String subject, String message) async {
    if (!_connected) {
      await connect();
    }

    _client.pubString(subject, message);
    print('Message published to "$subject": $message');
  }

  static Future<void> disconnect() async {
    _client.close();
    _connected = false;
    print("Disconnected from NATS server.");
  }
}

/*
import 'dart:async';

import 'package:dart_nats/dart_nats.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

class NatsService {
  static final Client _client = Client();
  static bool _connected = false;

  static bool get isConnected => _connected;

  static Future<void> connect() async {
    try {
      final uri = Uri.parse("nats://161.97.129.123:4222");

      await _client.connect(
        uri,
        connectOption: ConnectOption(
          user: 'arif',
          pass: 'arshad',
        ),
      );

      _connected = true;
      print("Connected to NATS server.");

    } catch (e) {
      print("NATS connection error: $e");
      _connected = false;
      rethrow;
    }
  }

  static Future<void> subscribe(String subject, Function(String) onMessage) async {
    if (!_connected) {
      await connect();
    }

    _client.sub(subject)?.stream.listen((Message msg) {
      final String message = msg.string ?? '[Non-UTF8 Message]';
      print("Received: $message");
      NotificationService().showNotification(
          title: message,
          body: message
      );
      onMessage(message);
    });
  }

  static Future<void> publish(String subject, String message) async {
    if (!_connected) {
      await connect();
    }

    _client.pubString(subject, message);

    print('Message published to "$subject": $message');
  }

  static Future<void> disconnect() async {
    _client.close();
    _connected = false;
    print("Disconnected from NATS server.");
  }

  static Future<void> checkForNewMessagesInBackground() async {
    try {
      final backgroundClient = Client();
      await backgroundClient.connect(
        Uri.parse("nats://161.97.129.123:4222"),
        connectOption: ConnectOption(
          user: 'arif',
          pass: 'arshad',
        ),
      );

      // Store last message timestamp to avoid duplicates
      final prefs = await SharedPreferences.getInstance();
      final lastTimestamp = prefs.getInt('last_message_timestamp') ?? 0;

      final sub = backgroundClient.sub('updates');
      // Create a completer to handle the async operation
      final completer = Completer<void>();

      final subscription = sub?.stream.listen((Message msg) async {
        final String message = msg.string ?? '[Non-UTF8 Message]';
        final int timestamp = DateTime.now().millisecondsSinceEpoch;


      });

      // Wait for a short time to receive messages
      await Future.delayed(Duration(seconds: 10));

      // Cancel subscription and close connection
      await subscription?.cancel();
      backgroundClient.close();
      completer.complete();

      return completer.future;
    } catch (e) {
      print("Background NATS error: $e");
      return Future.value();
    }
  }
}*/
