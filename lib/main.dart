import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'nats_home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.initialize();

  runApp(NatsSubscriberApp());
}




class NatsSubscriberApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NATS Subscriber',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NatsHomePage(),
    );
  }

 // NotificationDetails
}