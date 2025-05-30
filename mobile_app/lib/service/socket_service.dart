import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../util/storage/base_storage.dart';
import '../util/constants.dart';

class SocketService {
  static IO.Socket? _socket;

  static IO.Socket get socket {
    String url = '';
    if (_socket == null) {
      if (kIsWeb) {
        url = Server.WEB_SOCKET_URL;
      } else if (Platform.isAndroid) {
        url = Server.MOBILE_SOCKET_URL;
      } else {
        url = Server.WEB_SOCKET_URL;
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

      _socket!.on('devices', (data) {
        BaseStorage.getStorageFactory().removeAllDevices();
        BaseStorage.getStorageFactory().saveDevices(data['devices']);
      });

      _socket!.connect();

      return _socket!;
    } else {

      return _socket!;
    }
  }
}