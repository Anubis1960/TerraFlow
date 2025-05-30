import 'dart:convert';

import '../../entity/device.dart';
import 'base_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SharedPrefs extends BaseStorage {
  static final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  Future<void> clearAllData() async {
    final sharedPrefs = await _prefs;
    await sharedPrefs.clear();
  }

  @override
  Future<void> saveToken(String token) async {
    final sharedPrefs = await _prefs;
    await sharedPrefs.setString('token', token);
  }

  @override
  Future<String> getToken() async {
    final sharedPrefs = await _prefs;
    return sharedPrefs.getString('token') ?? '';
  }

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

  @override
  Future<void> saveDevices(List<Device> devices) async {
    final prefs = await _prefs;
    List<String> encodedDevices = devices.map((d) => json.encode(d.toMap())).toList();
    prefs.setStringList('devices', encodedDevices);
  }

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

  @override
  Future<void> removeAllDevices() async {
    final sharedPrefs = await _prefs;
    await sharedPrefs.remove('devices');
  }

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


BaseStorage getStorage() => SharedPrefs();