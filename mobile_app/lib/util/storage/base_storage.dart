
import '../../entity/device.dart';
import 'base_storage_stub.dart'
  if (dart.library.io) 'shared_prefs_storage.dart'
  if (dart.library.html) 'session_storage.dart';

abstract class BaseStorage {
  Future<void> clearAllData();

  Future<void> saveToken(String token);
  Future<String> getToken();

  Future<void> addDevice(Device device);
  Future<void> saveDevices(List<Device> devices);
  Future<void> removeDevice(String deviceId);
  Future<void> removeAllDevices();
  Future<List<Device>> getDevices();

  static BaseStorage getStorageFactory() => getStorage();
}