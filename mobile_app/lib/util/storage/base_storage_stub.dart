import 'base_storage.dart';

/// A stub implementation of the BaseStorage for unsupported platforms.
BaseStorage getStorage() {
  throw UnsupportedError("Platform not supported");
}