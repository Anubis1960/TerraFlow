
/// Represents sensor data with a timestamp and a map of sensor readings.
class SensorData {
  final String timestamp;
  final Map<String, dynamic> sensorData;

  SensorData({
    required this.timestamp,
    required this.sensorData,
  });

  static SensorData fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp: json['timestamp'] as String,
      sensorData: Map<String, dynamic>.from(json['sensor_data'] as Map),
    );
  }
}