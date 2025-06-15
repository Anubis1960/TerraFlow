import 'dart:convert';

import '../../entity/device.dart';
import 'base_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Shared Preferences based storage implementation
class SharedPrefs extends BaseStorage {

  /// Instance of SharedPreferences
  static final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  /// Clears all data stored in SharedPreferences
  /// @returns A [Future] that completes when the data is cleared.
  @override
  Future<void> clearAllData() async {
    final sharedPrefs = await _prefs;
    await sharedPrefs.clear();
  }

  /// Saves the user token in SharedPreferences
  /// This token is used for authentication purposes.
  /// @param token The authentication token to be saved.
  /// @returns A [Future] that completes when the token is saved.
  @override
  Future<void> saveToken(String token) async {
    final sharedPrefs = await _prefs;
    await sharedPrefs.setString('token', token);
  }

  /// Retrieves the user token from SharedPreferences
  /// @returns A [Future] that resolves to the token string.
  @override
  Future<String> getToken() async {
    final sharedPrefs = await _prefs;
    return sharedPrefs.getString('token') ?? '';
  }

  /// Adds a device to the SharedPreferences storage
  /// @param device The Device object to be added.
  /// @returns A [Future] that completes when the device is added.
  @override
  Future<void> addDevice(Device device) async {
    final sharedPrefs = await _prefs;

    List<String> deviceStrings = sharedPrefs.getStringList('devices') ?? [];

    // Avoid duplicates
    final existingIndex = deviceStrings.indexWhere((d) {
      final dev = json.decode(d);
      return dev['id'] == device.id;
    });

    if (existingIndex >= 0) {
      deviceStrings.removeAt(existingIndex);
    }

    deviceStrings.add(json.encode(device.toMap()));
    await sharedPrefs.setStringList('devices', deviceStrings);
  }

  /// Saves a list of devices to SharedPreferences
  /// @param devices The list of Device objects to be saved.
  /// @returns A [Future] that completes when the devices are saved.
  @override
  Future<void> saveDevices(List<Device> devices) async {
    final prefs = await _prefs;
    List<String> encodedDevices = devices.map((d) => json.encode(d.toMap())).toList();
    prefs.setStringList('devices', encodedDevices);
  }

  /// Removes a device from SharedPreferences by its ID
  /// @param deviceId The ID of the device to be removed.
  /// @returns A [Future] that completes when the device is removed.
  @override
  Future<void> removeDevice(String deviceId) async {
    final sharedPrefs = await _prefs;

    List<String> deviceStrings = sharedPrefs.getStringList('devices') ?? [];

    deviceStrings.removeWhere((d) {
      final dev = json.decode(d);
      return dev['id'] == deviceId;
    });

    await sharedPrefs.setStringList('devices', deviceStrings);
  }

  /// Removes all devices from SharedPreferences
  /// @returns A [Future] that completes when all devices are removed.
  @override
  Future<void> removeAllDevices() async {
    final sharedPrefs = await _prefs;
    await sharedPrefs.remove('devices');
  }

  /// Retrieves a list of devices from SharedPreferences
  /// @returns A [Future] that resolves to a list of Device objects.
  @override
  Future<List<Device>> getDevices() async {
    final sharedPrefs = await _prefs;

    List<String> deviceStrings = sharedPrefs.getStringList('devices') ?? [];

    return deviceStrings.map((str) {
      Map<String, dynamic> map = json.decode(str);
      return Device(id: map['id'], name: map['name']);
    }).toList();
  }
}

/// Factory method to get the SharedPrefs storage instance
BaseStorage getStorage() => SharedPrefs();