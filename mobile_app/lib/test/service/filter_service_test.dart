import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/service/filter_service.dart';

import 'package:mobile_app/entity/sensor_data.dart';

import 'package:mobile_app/entity/device_data.dart';
import 'package:mobile_app/entity/water_usage.dart';

void main() {
  final DeviceData deviceData = DeviceData(
    sensorData: [
      SensorData(timestamp: '2024-01-01T10:00:00Z', sensorData: {'temperature': 22.5}),
      SensorData(timestamp: '2024-01-02T11:00:00Z', sensorData: {'temperature': 23.0}),
      SensorData(timestamp: '2024-02-01T12:00:00Z', sensorData: {'temperature': 21.8}),
      SensorData(timestamp: '2024-03-01T13:00:00Z', sensorData: {'temperature': 20.5}),
      SensorData(timestamp: '2025-01-01T14:00:00Z', sensorData: {'temperature': 19.0}),
    ],
    waterUsageData: [
      WaterUsage(date: '2024-01', waterUsed: 100),
      WaterUsage(date: '2024-01', waterUsed: 120),
      WaterUsage(date: '2024-02', waterUsed: 90),
      WaterUsage(date: '2024-03', waterUsed: 110),
      WaterUsage(date: '2025-01', waterUsed: 130),
    ],
  );

  group('FilterService Tests', () {
    test('filterRecords - Filter by day', () {
      final result = FilterService.filterRecords(deviceData.sensorData, '2024-01-01', 'day');
      expect(result.length, 1);
      expect(result[0].timestamp, '2024-01-01T10:00:00Z');
    });

    test('filterRecords - Filter by month', () {
      final result = FilterService.filterRecords(deviceData.sensorData, '2024-01', 'month');
      expect(result.length, 2);
      expect(result[0].timestamp, '2024-01-01T10:00:00Z');
      expect(result[1].timestamp, '2024-01-02T11:00:00Z');
    });

    test('filterRecords - Filter by year', () {
      final result = FilterService.filterRecords(deviceData.sensorData, '2024', 'year');
      expect(result.length, 4);
    });

    test('getFilterValues - Day', () {
      final values = FilterService.getFilterValues(deviceData.sensorData, 'day');
      expect(values.contains('2024-01-01'), true);
      expect(values.contains('2024-01-02'), true);
      expect(values.contains('2024-02-01'), true);
      expect(values.contains('2024-03-01'), true);
      expect(values.contains('2025-01-01'), true);
    });

    test('getFilterValues - Month', () {
      final values = FilterService.getFilterValues(deviceData.sensorData, 'month');
      expect(values.contains('2024-01'), true);
      expect(values.contains('2024-02'), true);
      expect(values.contains('2024-03'), true);
      expect(values.contains('2025-01'), true);
    });

    test('calculateAverage - Temperature', () {
      final avg = FilterService.calculateAverage(deviceData.sensorData, 'temperature');
      expect(avg, closeTo((22.5 + 23.0 + 21.8 + 20.5 + 19.0) / 5, 0.01));
    });

    test('calculateWaterUsage - Exact Match on Date', () {
      final usage = FilterService.calculateWaterUsage(deviceData.waterUsageData, '2025-01');
      expect(usage, 130);
    });

    test('calculateWaterUsage - Sum by Year', () {
      final usage = FilterService.calculateWaterUsage(deviceData.waterUsageData, '2024');
      expect(usage, 100 + 120 + 90 + 110);
    });

    test('calculateWaterUsage - Binary Search by Month', () {
      final usage = FilterService.calculateWaterUsage(deviceData.waterUsageData, '2024-02');
      expect(usage, 90);
    });
  });
}