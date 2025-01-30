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