import 'package:mobile_app/util/storage/base_storage.dart';
import 'dart:convert';
import 'dart:html' as html show Storage, window;
import '../../entity/device.dart';

/// SessionStorage class that implements BaseStorage to manage session data
class SessionStorage extends BaseStorage {
  static final html.Storage _sessionStorage = html.window.sessionStorage;

  @override
  Future<void> clearAllData() async {
    _sessionStorage.clear();
  }

  @override
  Future<void> saveToken(String token) async {
    _sessionStorage['token'] = token;
  }

  @override
  Future<String> getToken() async {
    return _sessionStorage['token'] ?? '';
  }

  @override
  Future<void> addDevice(Device device) async {
    List<Device> devices = await getDevices();

    devices.removeWhere((d) => d.id == device.id);
    devices.add(device);

    String encoded = json.encode(devices.map((d) => d.toMap()).toList());
    _sessionStorage['devices'] = encoded;
  }

  @override
  Future<void> saveDevices(List<Device> devices) async {
    String encoded = json.encode(devices.map((d) => d.toMap()).toList());
    _sessionStorage['devices'] = encoded;
  }

  @override
  Future<void> removeDevice(String deviceId) async {
    List<Device> devices = await getDevices();
    devices.removeWhere((d) => d.id == deviceId);
    List<String> encodedDevices = devices.map((d) => json.encode(d.toMap())).toList();
    _sessionStorage['devices'] = json.encode(encodedDevices);
  }

  @override
  Future<void> removeAllDevices() async {
    _sessionStorage.remove('devices');
  }

  @override
  Future<List<Device>> getDevices() async {
    String? devicesJson = _sessionStorage['devices'];
    if (devicesJson == null || devicesJson.isEmpty) {
      return [];
    }
    List<dynamic> decoded = json.decode(devicesJson);
    return decoded.map((d) => Device.fromMap(d)).toList();
  }
}

BaseStorage getStorage() => SessionStorage();