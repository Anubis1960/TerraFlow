import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../util/SharedPreferencesStorage.dart';
import '../util/SocketService.dart';

class ControllerDashBoard extends StatefulWidget {
  final dynamic controllerId;

  const ControllerDashBoard({super.key, required this.controllerId});

  @override
  _ControllerDashBoard createState() => _ControllerDashBoard(controllerId);
}

class _ControllerDashBoard extends State<ControllerDashBoard> {
  final dynamic controllerId;

  _ControllerDashBoard(this.controllerId);

  Map<String, dynamic> controllerData = {};

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('initState');
    }
    Future<String> userId = SharedPreferencesStorage.getUserId();

    SocketService.socket.on('controller_data_response', (data) {
      controllerData = data;
      if (kDebugMode) {
        print('Received controller data response: $data');
      }
      setState(() {
        controllerData = data;
      });
    });

    SocketService.socket.emit('fetch_controller_data', {
      'controller_id': controllerId,
    });
  }

  @override
  void dispose() {
    SocketService.socket.off('controller_data_response');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('controller Details: $controllerId'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('controller ID: $controllerId'),
            Text('controller Data: $controllerData'),
          ],
        ),
      ),
    );
  }
}