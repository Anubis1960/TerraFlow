import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesStorage {
  // Save user details
  static Future<void> saveUserId(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  static Future<void> saveControllerId(String controllerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> controllerIds = await getControllerList();
    controllerIds.add(controllerId);
    await prefs.setStringList('controller_ids', controllerIds);
  }

  // Get user details
  static Future<String> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? '';
  }

  static Future<List<String>> getControllerList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('controller_ids') ?? [];
  }

  static Future<void> saveControllerList(List<dynamic> controllers) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> controllerIds = List<String>.from(controllers);
    print('Saving controller list: $controllers');
    await prefs.setStringList('controller_ids', controllerIds);
  }
}