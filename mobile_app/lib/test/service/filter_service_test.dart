import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/service/filter_service.dart';

void main() {
  final sampleData = [
    {
      'timestamp': '2024-01-01T10:00:00Z',
      'sensor_data': {'temperature': 22.5},
      'date': '2024-01',
      'water_used': 100
    },
    {
      'timestamp': '2024-01-02T11:00:00Z',
      'sensor_data': {'temperature': 23.0},
      'date': '2024-01',
      'water_used': 120
    },
    {
      'timestamp': '2024-02-01T12:00:00Z',
      'sensor_data': {'temperature': 21.8},
      'date': '2024-02',
      'water_used': 90
    },
    {
      'timestamp': '2024-03-01T13:00:00Z',
      'sensor_data': {'temperature': 20.5},
      'date': '2024-03',
      'water_used': 110
    },
    {
      'timestamp': '2025-01-01T14:00:00Z',
      'sensor_data': {'temperature': 19.0},
      'date': '2025-01',
      'water_used': 130
    }
  ];

  group('FilterService Tests', () {
    test('filterRecords - Filter by day', () {
      final result = FilterService.filterRecords(sampleData, '2024-01-01', 'day');
      expect(result.length, 1);
      expect(result[0]['timestamp'], '2024-01-01T10:00:00Z');
    });

    test('filterRecords - Filter by month', () {
      final result = FilterService.filterRecords(sampleData, '2024-01', 'month');
      expect(result.length, 2);
      expect(result[0]['timestamp'], '2024-01-01T10:00:00Z');
      expect(result[1]['timestamp'], '2024-01-02T11:00:00Z');
    });

    test('filterRecords - Filter by year', () {
      final result = FilterService.filterRecords(sampleData, '2024', 'year');
      expect(result.length, 4);
    });

    test('getFilterValues - Day', () {
      final values = FilterService.getFilterValues(sampleData, 'day');
      expect(values.contains('2024-01-01'), true);
      expect(values.contains('2024-01-02'), true);
      expect(values.contains('2024-02-01'), true);
      expect(values.contains('2024-03-01'), true);
      expect(values.contains('2025-01-01'), true);
    });

    test('getFilterValues - Month', () {
      final values = FilterService.getFilterValues(sampleData, 'month');
      expect(values.contains('2024-01'), true);
      expect(values.contains('2024-02'), true);
      expect(values.contains('2024-03'), true);
      expect(values.contains('2025-01'), true);
    });

    test('calculateAverage - Temperature', () {
      final avg = FilterService.calculateAverage(sampleData, 'temperature');
      expect(avg, closeTo((22.5 + 23.0 + 21.8 + 20.5 + 19.0) / 5, 0.01));
    });

    test('calculateWaterUsage - Exact Match on Date', () {
      final usage = FilterService.calculateWaterUsage(sampleData, '2025-01');
      expect(usage, 130);
    });

    test('calculateWaterUsage - Sum by Year', () {
      final usage = FilterService.calculateWaterUsage(sampleData, '2024');
      expect(usage, 100 + 120 + 90 + 110);
    });

    test('calculateWaterUsage - Binary Search by Month', () {
      final usage = FilterService.calculateWaterUsage(sampleData, '2024-02');
      expect(usage, 90);
    });
  });
}