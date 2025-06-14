import 'dart:core';

import 'package:mobile_app/entity/sensor_data.dart';
import 'package:mobile_app/entity/water_usage.dart';

/// Represents the data structure for a device, including sensor data and water usage data.
class DeviceData {
  List<SensorData> sensorData;
  List<WaterUsage> waterUsageData;

  DeviceData({
    List<SensorData>? sensorData,
    List<WaterUsage>? waterUsageData,
  })  : sensorData = sensorData ?? [],
        waterUsageData = waterUsageData ?? [];

  void addSensorData(SensorData data) {
    sensorData.add(data);
  }

  void addWaterUsageData(WaterUsage data) {
    waterUsageData.add(data);
  }

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