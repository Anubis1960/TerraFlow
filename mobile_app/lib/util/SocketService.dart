import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'shared_preferences_storage.dart';

class SocketService {
  static IO.Socket? _socket;
  static String url = '';

  static IO.Socket get socket {
    if (_socket == null) {
      if (kIsWeb) {
        url = 'ws://localhost:5000'; // Adjust URL based on your server setup
      } else if (Platform.isAndroid) {
        url = 'ws://10.0.2.2:5000';
      } else {
        url = 'ws://localhost:5000';
      }
      _socket = IO.io(url, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.onConnect((_) {
      });

      _socket!.onDisconnect((_) {
      });

      _socket!.on('ping', (data) {
        _socket!.emit('pong', 'pong');
      });

      _socket!.on('pong', (data) {
        _socket!.emit('ping', 'ping');
      });

      _socket!.on('message', (data) {
      });

      _socket!.on('controllers', (data) {
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