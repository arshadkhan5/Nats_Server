import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nats_service.dart';
class NatsHomePage extends StatefulWidget {
  @override
  _NatsHomePageState createState() => _NatsHomePageState();
}

class _NatsHomePageState extends State<NatsHomePage> {
  final List<String> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initNats();
    _loadStoredMessages();
  }

  void _initNats() async {
    try {
      await NatsService.connect();
      setState(() {
        _isConnected = true;
      });

      // Subscribe to messages
      await NatsService.subscribe('updates', _handleNewMessage);
    } catch (e) {
      print("Failed to initialize NATS: $e");
      setState(() {
        _isConnected = false;
      });
    }
  }

  void _loadStoredMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMessages = prefs.getStringList('cached_messages') ?? [];
    setState(() {
      _messages.addAll(storedMessages);
    });
  }

  void _handleNewMessage(String message) {
    setState(() {
      _messages.insert(0, message);
    });

    // Cache the message
    _cacheMessages();
  }

  void _cacheMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cached_messages', _messages);
  }

  void _publishMessage() async {
    final message = _messageController.text;
    if (message.isEmpty) return;

    try {
      await NatsService.publish('updates', message);
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message sent: $message')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  void dispose() {
    NatsService.disconnect();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NATS Messenger'),
        actions: [
          Icon(
            _isConnected ? Icons.cloud_done : Icons.cloud_off,
            color: _isConnected ? Colors.green : Colors.red,
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Message input section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _publishMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _publishMessage,
                ),
              ],
            ),
          ),
          Divider(),
          // Connection status
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _isConnected ? 'Connected to NATS server' : 'Disconnected from NATS server',
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(),
          // Messages display section
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Text(
                'No messages yet\nSend a message or wait for incoming messages',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.message),
                  title: Text(_messages[index]),
                  subtitle: Text('Received ${index + 1} messages ago'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}