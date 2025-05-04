import 'package:mobile_app/util/storage/base_storage.dart';
import 'dart:html' as html show Storage, window;

class SessionStorage extends BaseStorage{
  static final html.Storage _sessionStorage = html.window.sessionStorage;

  @override
  Future<void> clearAllData() async {
    _sessionStorage.clear();
  }

  @override
  Future<void> deleteData(String key) async{
    _sessionStorage.remove(key);
  }

  @override
  Future<String> getToken() async{
    return _sessionStorage['token'] ?? '';
  }

  @override
  Future<List<String>> getDeviceList() async {
    List<String> deviceIds = _sessionStorage['device_ids']?.split(',') ?? [];

    deviceIds = deviceIds.where((id) => id.isNotEmpty).toList();

    print('Device IDs: $deviceIds');
    return deviceIds;
  }


  @override
  Future<void> saveData(String key, value) async{
    if (key == 'device_ids') {
      if (value is List) {
        List<String> deviceIds = [];
        for (var deviceId in value) {
          deviceIds.add(deviceId);
        }
        _sessionStorage['device_ids'] = deviceIds.join(',');
      } else if (value is String) {
        List<String> deviceIds = await getDeviceList();
        deviceIds.add(value);
        _sessionStorage['device_ids'] = deviceIds.join(',');
      }
    }

    if (key == 'token') {
      _sessionStorage['token'] = value;
    }
  }
  
}

BaseStorage getStorage() => SessionStorage();