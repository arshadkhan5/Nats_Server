import 'package:flutter/material.dart';
import 'background_service.dart';
import 'notification_service.dart';
import 'nats_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService().initialize();

  // Start background service
  await initializeService();

  runApp(NatsSubscriberApp());
}

class NatsSubscriberApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NATS Subscriber',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NatsHomePage(),
    );
  }
}
