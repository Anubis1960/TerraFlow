import 'package:mobile_app/util/storage/base_storage.dart';
import 'dart:convert';
import 'dart:html' as html show Storage, window;
import '../../entity/device.dart';

/// SessionStorage class that implements BaseStorage to manage session data
class SessionStorage extends BaseStorage {

  /// The session storage instance for storing data in the browser's session storage.
  static final html.Storage _sessionStorage = html.window.sessionStorage;

  /// Clears all data stored in the session storage.
  /// @returns A [Future] that completes when the data is cleared.
  @override
  Future<void> clearAllData() async {
    _sessionStorage.clear();
  }

  /// Saves the user token in the session storage.
  /// @param token The authentication token to be saved.
  /// @returns A [Future] that completes when the token is saved.
  @override
  Future<void> saveToken(String token) async {
    _sessionStorage['token'] = token;
  }

  /// Retrieves the user token from the session storage.
  /// @returns A [Future] that resolves to the token string.
  @override
  Future<String> getToken() async {
    return _sessionStorage['token'] ?? '';
  }

  /// Adds a device to the session storage.
  /// @param device The Device object to be added.
  /// @returns A [Future] that completes when the device is added.
  @override
  Future<void> addDevice(Device device) async {
    List<Device> devices = await getDevices();

    devices.removeWhere((d) => d.id == device.id);
    devices.add(device);

    String encoded = json.encode(devices.map((d) => d.toMap()).toList());
    _sessionStorage['devices'] = encoded;
  }

  /// Saves a list of devices to the session storage.
  /// @param devices The list of Device objects to be saved.
  /// @returns A [Future] that completes when the devices are saved.
  @override
  Future<void> saveDevices(List<Device> devices) async {
    String encoded = json.encode(devices.map((d) => d.toMap()).toList());
    _sessionStorage['devices'] = encoded;
  }

  /// Removes a device from the session storage by its ID.
  /// @param deviceId The ID of the device to be removed.
  /// @returns A [Future] that completes when the device is removed.
  @override
  Future<void> removeDevice(String deviceId) async {
    List<Device> devices = await getDevices();
    devices.removeWhere((d) => d.id == deviceId);
    List<String> encodedDevices = devices.map((d) => json.encode(d.toMap())).toList();
    _sessionStorage['devices'] = json.encode(encodedDevices);
  }

  /// Removes all devices from the session storage.
  /// @returns A [Future] that completes when all devices are removed.
  @override
  Future<void> removeAllDevices() async {
    _sessionStorage.remove('devices');
  }

  /// Retrieves a list of devices from the session storage.
  /// @returns A [Future] that resolves to a list of Device objects.
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

/// Factory method to get the session storage instance
BaseStorage getStorage() => SessionStorage();