
import '../../entity/device.dart';
import 'base_storage_stub.dart'
  if (dart.library.io) 'shared_prefs_storage.dart'
  if (dart.library.html) 'session_storage.dart';

/// Base class for storage implementations that manage user data and devices.
abstract class BaseStorage {

  /// Clears all data stored in the storage.
  Future<void> clearAllData();

  /// Clears all data related to the user.
  Future<void> saveToken(String token);

  /// Retrieves the token from the storage.
  Future<String> getToken();

  /// Adds a device to the storage.
  Future<void> addDevice(Device device);

  /// Saves a list of devices to the storage.
  Future<void> saveDevices(List<Device> devices);

  /// Removes a device from the storage by its ID.
  Future<void> removeDevice(String deviceId);

  /// Removes all devices from the storage.
  Future<void> removeAllDevices();

  /// Retrieves a list of devices from the storage.
  Future<List<Device>> getDevices();

  static BaseStorage getStorageFactory() => getStorage();
}