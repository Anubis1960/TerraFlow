import 'package:mobile_app/entity/sensor_data.dart';

import '../components/charts.dart';

/// A class to process sensor data and convert it into chart data points.
class ChartDataProcessor {

  /// Converts a list of sensor data records into a list of chart data points.
  /// @param records The list of sensor data records.
  /// @param sensorKey The key of the sensor data to be processed.
  /// @param filterType The type of filter to apply ('day', 'month', 'year').
  /// @return [List] A list of chart data points.
  static List<ChartData> getSensorDataSpots(List<SensorData> records, String sensorKey, String filterType) {
    if (filterType == 'day') {
      return records.map((record) => ChartData(
          record.timestamp.substring(11, 19),
          record.sensorData[sensorKey].toDouble()
      )).toList();
    } else if (filterType == 'month') {
      List<String> xAxisLabels = List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'));
      Map<String, List<double>> aggregatedData = {};
      for (var record in records) {
        String timestamp = record.timestamp;
        String key = timestamp.substring(8, 10);
        double value = record.sensorData[sensorKey].toDouble();
        if (!aggregatedData.containsKey(key)) {
          aggregatedData[key] = [];
        }
        aggregatedData[key]!.add(value);
      }

      List<ChartData> chartData = [];
      for (var label in xAxisLabels) {
        if (aggregatedData.containsKey(label)) {
          double avg = aggregatedData[label]!.reduce((a, b) => a + b) / aggregatedData[label]!.length;
          chartData.add(ChartData(label, avg));
        } else {
          chartData.add(ChartData(label, null));
        }
      }
      return chartData;
    } else if (filterType == 'year') {
      List<String> xAxisLabels = List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
      Map<String, String> monthMap = {
        '01': 'Jan', '02': 'Feb', '03': 'Mar', '04': 'Apr',
        '05': 'May', '06': 'Jun', '07': 'Jul', '08': 'Aug',
        '09': 'Sep', '10': 'Oct', '11': 'Nov', '12': 'Dec'
      };
      Map<String, List<double>> aggregatedData = {};
      for (var record in records) {
        String timestamp = record.timestamp;
        String key = timestamp.substring(5, 7);
        double value = record.sensorData[sensorKey].toDouble();
        if (!aggregatedData.containsKey(key)) {
          aggregatedData[key] = [];
        }
        aggregatedData[key]!.add(value);
      }

      List<ChartData> chartData = [];
      for (var label in xAxisLabels) {
        if (aggregatedData.containsKey(label)) {
          double avg = aggregatedData[label]!.reduce((a, b) => a + b) / aggregatedData[label]!.length;
          chartData.add(ChartData(monthMap[label] ?? label, avg));
        } else {
          chartData.add(ChartData(monthMap[label] ?? label, null));
        }
      }
      return chartData;
    }
    return [];
  }
}