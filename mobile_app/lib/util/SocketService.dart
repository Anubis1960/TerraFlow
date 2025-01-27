import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;

  static IO.Socket get socket {
    if (_socket == null) {
      _socket = IO.io('ws://10.0.2.2:5000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.onConnect((_) {
        print('connected');
      });

      _socket!.onDisconnect((_) {
        print('disconnected');
      });

      _socket!.on('ping', (data) {
        print(data);
        _socket!.emit('pong', 'pong');
      });

      _socket!.on('pong', (data) {
        print(data);
        _socket!.emit('ping', 'ping');
      });

      _socket!.on('message', (data) {
        print('Received message: $data');
      });

      _socket!.connect();

      return _socket!;
    } else {
      return _socket!;
    }
  }
}