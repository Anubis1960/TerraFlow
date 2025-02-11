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
  Future<List<String>> getControllerList() async {
    List<String> controllerIds = _sessionStorage['controller_ids']?.split(',') ?? [];

    controllerIds = controllerIds.where((id) => id.isNotEmpty).toList();

    print('Controller IDs: $controllerIds');
    return controllerIds;
  }


  @override
  Future<void> saveData(String key, value) async{
    if (key == 'controller_ids') {
      if (value is List) {
        List<String> controllerIds = [];
        for (var controllerId in value) {
          controllerIds.add(controllerId);
        }
        _sessionStorage['controller_ids'] = controllerIds.join(',');
      } else if (value is String) {
        List<String> controllerIds = await getControllerList();
        controllerIds.add(value);
        _sessionStorage['controller_ids'] = controllerIds.join(',');
      }
    }

    if (key == 'token') {
      _sessionStorage['token'] = value;
    }
  }
  
}

BaseStorage getStorage() => SessionStorage();