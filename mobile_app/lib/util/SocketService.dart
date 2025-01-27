import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'SharedPreferencesStorage.dart';

class SocketService {
  static IO.Socket? _socket;

  static IO.Socket get socket {
    if (_socket == null) {
      _socket = IO.io('ws://10.0.2.2:5000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.onConnect((_) {
        if (kDebugMode) {
          print('connected');
        }
      });

      _socket!.onDisconnect((_) {
        if (kDebugMode) {
          print('disconnected');
        }
      });

      _socket!.on('ping', (data) {
        if (kDebugMode) {
          print(data);
        }
        _socket!.emit('pong', 'pong');
      });

      _socket!.on('pong', (data) {
        if (kDebugMode) {
          print(data);
        }
        _socket!.emit('ping', 'ping');
      });

      _socket!.on('message', (data) {
        if (kDebugMode) {
          print('Received message: $data');
        }
      });

      _socket!.on('controllers', (data) {
        if (kDebugMode) {
          print('Received controller_ids: $data');
        }
        for (var controllerId in data['controllers']) {
          SharedPreferencesStorage.saveControllerId(controllerId);
        }
      });

      _socket!.connect();

      return _socket!;
    } else {
      return _socket!;
    }
  }
}