import 'base_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SharedPrefs extends BaseStorage {
  // Instead of directly initializing _prefs, we keep it as Future<SharedPreferences>
  static final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  Future<void> clearAllData() async {
    final prefs = await _prefs; // Await for the SharedPreferences instance
    prefs.clear();
  }

  @override
  Future<void> saveData(String key, dynamic value) async {
    final prefs = await _prefs; // Await for the SharedPreferences instance

    if (key == 'device_ids') {
      if (value is List<dynamic>) {
        List<String> deviceIds = [];
        for (var deviceId in value) {
          deviceIds.add(deviceId);
        }
        prefs.setStringList(key, deviceIds);
      } else if (value is String) {
        List<String> deviceIds = await getDeviceList();
        deviceIds.add(value);
        prefs.setStringList(key, deviceIds);
      }
    }

    if (key == 'token') {
      prefs.setString(key, value);
    }
  }

  @override
  Future<void> deleteData(String key) async {
    final prefs = await _prefs; // Await for the SharedPreferences instance
    prefs.remove(key);
  }

  @override
  Future<String> getToken() async {
    final prefs = await _prefs; // Await for the SharedPreferences instance
    return prefs.getString('token') ?? '';
  }

  @override
  Future<List<String>> getDeviceList() async {
    final prefs = await _prefs; // Await for the SharedPreferences instance
    return prefs.getStringList('device_ids') ?? [];
  }
}


BaseStorage getStorage() => SharedPrefs();