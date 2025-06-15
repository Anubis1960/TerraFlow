import 'dart:core';

import 'package:mobile_app/entity/sensor_data.dart';
import 'package:mobile_app/entity/water_usage.dart';

/// Represents the data structure for a device, including sensor data and water usage data.
class DeviceData {
  List<SensorData> sensorData;
  List<WaterUsage> waterUsageData;

  /// Constructs a DeviceData object with optional sensor data and water usage data.
  /// @param sensorData A list of SensorData objects. Defaults to an empty list if not provided.
  /// @param waterUsageData A list of WaterUsage objects. Defaults to an empty list if not provided.
  DeviceData({
    List<SensorData>? sensorData,
    List<WaterUsage>? waterUsageData,
  })  : sensorData = sensorData ?? [],
        waterUsageData = waterUsageData ?? [];

  /// Adds a new sensor data record to the device data.
  /// @param data The SensorData object to be added.
  /// @return [void]
  void addSensorData(SensorData data) {
    sensorData.add(data);
  }

  /// Adds a new water usage record to the device data.
  /// @param data The WaterUsage object to be added.
  /// @return [void]
  void addWaterUsageData(WaterUsage data) {
    waterUsageData.add(data);
  }

  /// Converts the JSON map representation of a DeviceData instance into a DeviceData object.
  /// @param json The JSON map to convert.
  /// @return A [DeviceData] object constructed from the JSON map.
  static DeviceData fromJson(Map<String, dynamic> json) {
    return DeviceData(
      sensorData: (json['record'] as List<dynamic>?)
              ?.map((item) => SensorData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      waterUsageData: (json['water_usage'] as List<dynamic>?)
              ?.map((item) => WaterUsage.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    return 'DeviceData(sensorData: $sensorData, waterUsageData: $waterUsageData)';
  }
}