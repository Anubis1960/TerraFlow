import 'package:mobile_app/util/storage/base_storage.dart';
import 'dart:html' as html;

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
  Future<String> getUserId() async{
    return _sessionStorage['user_id'] ?? '';
  }

  @override
  Future<List<String>> getControllerList() async{
    return _sessionStorage['controller_ids']?.split(',') ?? [];
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

    if (key == 'user_id') {
      _sessionStorage['user_id'] = value;
    }
  }
  
}

BaseStorage getStorage() => SessionStorage();