
import 'base_storage_stub.dart'
  if (dart.library.io) 'shared_prefs_storage.dart'
  if (dart.library.html) 'session_storage.dart';

abstract class BaseStorage {
  Future<void> saveData(String key, dynamic value);
  Future<String> getUserId();
  Future<List<String>> getControllerList();
  Future<void> deleteData(String key);
  Future<void> clearAllData();

  static BaseStorage getStorageFactory() => getStorage();
}