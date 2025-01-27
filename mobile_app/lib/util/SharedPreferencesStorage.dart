import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesStorage {
  // Save user details
  static Future<void> saveUserId(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  static Future<void> saveDeviceId(String deviceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> deviceIds = await getDeviceList();
    deviceIds.add(deviceId);
    await prefs.setStringList('device_ids', deviceIds);
  }

  // Get user details
  static Future<String> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? '';
  }

  static Future<List<String>> getDeviceList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('device_ids') ?? [];
  }
}