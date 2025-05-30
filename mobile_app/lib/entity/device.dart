class Device {
  final String id;
  final String name;

  Device({required this.id, required this.name});

  // Convert Device to Map for JSON encoding
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Optional: Create Device from Map
  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }
}