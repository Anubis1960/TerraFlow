
/// Represents a device with an ID and a name.
class Device {
  final String id;
  final String name;

  /// Constructs a Device instance with the given ID and name.
  /// @param id The unique identifier for the device.
  /// @param name The name of the device.
  Device({required this.id, required this.name});

  /// Converts the [Device] instance to a Map for serialization.
  /// @return A [Map] representation of the Device instance.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  /// Creates a Device instance from a Map.
  /// @param map The Map containing device data.
  /// @return A [Device] instance created from the Map.
  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }
}