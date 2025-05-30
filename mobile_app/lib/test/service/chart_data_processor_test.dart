import 'package:flutter_test/flutter_test.dart';

import '../../components/charts.dart';
import '../../service/chart_data_processor.dart';

void main() {
  final sampleRecords = [
    {
      'timestamp': '2024/01/01 08:30:00',
      'sensor_data': {'temperature': 22.5},
    },
    {
      'timestamp': '2024/01/01 09:30:00',
      'sensor_data': {'temperature': 23.0},
    },
    {
      'timestamp': '2024/01/02 10:00:00',
      'sensor_data': {'temperature': 21.5},
    },
    {
      'timestamp': '2024/02/01 14:00:00',
      'sensor_data': {'temperature': 20.0},
    },
    {
      'timestamp': '2024/02/01 15:00:00',
      'sensor_data': {'temperature': 20.4},
    },
    {
      'timestamp': '2024/03/01 12:00:00',
      'sensor_data': {'temperature': 19.6},
    },
  ];

  group('ChartDataProcessor - getSensorDataSpots', () {
    test('Returns time vs value when filterType == "day"', () {
      List<ChartData> result = ChartDataProcessor.getSensorDataSpots(sampleRecords, 'temperature', 'day');

      expect(result.length, 6); // All records are mapped individually

      expect(result[0].x, '08:30:00');
      expect(result[0].y, 22.5);

      expect(result[1].x, '09:30:00');
      expect(result[1].y, 23.0);

      expect(result[2].x, '10:00:00');
      expect(result[2].y, 21.5);
    });

    test('Groups by day of month and calculates average when filterType == "month"', () {
      List<ChartData> result = ChartDataProcessor.getSensorDataSpots(sampleRecords, 'temperature', 'month');

      expect(result.length, 31); // 31 days

      // January has 2 entries on day 01 and 1 entry on 02
      expect(result[0].x, '01'); // index 0 = 01
      expect(result[0].y, closeTo(21.1, 0.01));

      expect(result[1].x, '02');
      expect(result[1].y, 21.5);

      // Days without data should be null
      expect(result[2].x, '03');
      expect(result[2].y, isNull);
    });

    test('Groups by month and shows abbreviated names when filterType == "year"', () {
      List<ChartData> result = ChartDataProcessor.getSensorDataSpots(sampleRecords, 'temperature', 'year');

      expect(result.length, 12); // 12 months

      // Jan
      expect(result[0].x, 'Jan');
      expect(result[0].y, closeTo((22.5 + 23.0 + 21.5) / 3, 0.01));

      // Feb
      expect(result[1].x, 'Feb');
      expect(result[1].y, closeTo((20.0 + 20.4) / 2, 0.01));

      // Mar
      expect(result[2].x, 'Mar');
      expect(result[2].y, 19.6);

      // Remaining months should be null
      expect(result[3].x, 'Apr');
      expect(result[3].y, isNull);
    });

    test('Returns empty list for invalid filter type', () {
      List<ChartData> result = ChartDataProcessor.getSensorDataSpots(sampleRecords, 'temperature', 'invalid');
      expect(result, isEmpty);
    });
  });
}