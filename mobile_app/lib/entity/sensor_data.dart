
/// Represents sensor data with a timestamp and a map of sensor readings.
class SensorData {
  final String timestamp;
  final Map<String, dynamic> sensorData;

  /// Creates a SensorData instance with the given timestamp and sensor data.
  /// @param timestamp The timestamp of the sensor data.
  /// @param sensorData A map containing the sensor readings, where keys are sensor names and values are their readings.
  SensorData({
    required this.timestamp,
    required this.sensorData,
  });

  /// Converts a JSON map to a SensorData object.
  /// @param json The JSON map to convert.
  /// @return A [SensorData] object created from the JSON map.
  static SensorData fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp: json['timestamp'] as String,
      sensorData: Map<String, dynamic>.from(json['sensor_data'] as Map),
    );
  }
}