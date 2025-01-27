import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../util/SocketService.dart';
import '../util/SharedPreferencesStorage.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  late Future<String> userId;


  @override
  void initState() {
    if (kDebugMode) {
      print('initState');
    }
    super.initState();
    userId = SharedPreferencesStorage.getUserId();

  }

  void onPressed() {
    if (SocketService.socket.connected) {
      var json = {
        'device_id': '123456',
        'user_id': SocketService.socket.id, // Guaranteed to have an ID
      };
      SocketService.socket.emit('add_device', json);
      SocketService.socket.emit('export', json);
    } else {
      if (kDebugMode) {
        print('Socket not connected yet.');
      }
      SocketService.socket.connect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: TextButton(onPressed: onPressed, child: const Text('Hello World!')),
        )
    );
  }

}