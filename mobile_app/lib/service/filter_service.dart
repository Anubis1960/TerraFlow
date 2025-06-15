import 'package:mobile_app/entity/sensor_data.dart';
import 'package:mobile_app/entity/water_usage.dart';

/// FilterService provides methods to filter sensor data and water usage records
class FilterService {

  /// Filters the records based on the selected filter value and filter type.
  /// @param records List of SensorData records
  /// @param selectedFilterValue The value to filter by (e.g., date, month, year)
  /// @param filterType The type of filter to apply (e.g., 'day', 'month', 'year')
  /// @return [List] A list of SensorData records that match the filter criteria.
  static List<SensorData> filterRecords(List<SensorData> records, String selectedFilterValue, String filterType) {
    if (filterType == 'day') {
      return _binarySearchDateSubsection(records, selectedFilterValue, 'timestamp');
    } else if (filterType == 'month') {
      return _binarySearchDateSubsection(records, selectedFilterValue.substring(0, 7), 'timestamp');
    } else if (filterType == 'year') {
      return _binarySearchDateSubsection(records, selectedFilterValue.substring(0, 4), 'timestamp');
    }
    return records;
  }

  /// Finds the first or last index of a record with a timestamp that matches the given timestamp.
  /// @param records List of SensorData records
  /// @param timestamp The timestamp to search for
  /// @param key The key to search in the records
  /// @param findFirst If true, finds the first occurrence; if false, finds the last occurrence.
  /// @return [int] The index of the first or last occurrence of the record with the matching timestamp, or -1 if not found.
  static int _findBoundaryIndex(List<SensorData> records, String timestamp, String key, bool findFirst) {
    int low = 0, high = records.length - 1, result = -1;
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      String midTimestamp = records[mid].timestamp;
      if (midTimestamp.startsWith(timestamp)) {
        result = mid;
        if (findFirst) {
          high = mid - 1;
        } else {
          low = mid + 1;
        }
      } else if (midTimestamp.compareTo(timestamp) < 0) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return result;
  }

  /// Returns a subsection of records that match the given timestamp.
  /// @param records List of SensorData records
  /// @param timestamp The timestamp to search for
  /// @param key The key to search in the records
  /// @return [List] A list of SensorData records that match the timestamp.
  static List<SensorData> _binarySearchDateSubsection(List<SensorData> records, String timestamp, String key) {
    int firstIndex = _findBoundaryIndex(records, timestamp, key, true);
    if (firstIndex == -1) return [];
    int lastIndex = _findBoundaryIndex(records, timestamp, key, false);
    return records.sublist(firstIndex, lastIndex + 1);
  }

  /// Returns a set of unique filter values based on the filter type.
  /// @param records List of SensorData records
  /// @param filterType The type of filter to apply (e.g., 'day', 'month', 'year')
  /// @return [Set] A set of unique filter values (e.g., dates, months, years).
  static Set<String> getFilterValues(List<SensorData> records, String filterType) {
    Set<String> values = {};
    if (records.isEmpty) return values;

    for (var record in records) {
      String timestamp = record.timestamp;
      if (filterType == 'day') {
        values.add(timestamp.substring(0, 10));
      } else if (filterType == 'month') {
        values.add(timestamp.substring(0, 7));
      } else if (filterType == 'year') {
        values.add(timestamp.substring(0, 4));
      }
    }
    return values;
  }

  /// Calculates the average value of a specific key from the sensor data records.
  /// @param records List of SensorData records
  /// @param key The key to calculate the average for (e.g., 'temperature', 'humidity')
  /// @return [double] The average value of the specified key across all records, or 0 if no records are present.
  static double calculateAverage(List<SensorData> records, String key) {
    if (records.isEmpty) return 0;
    return records.map((record) => record.sensorData[key]?.toDouble() ?? 0).reduce((a, b) => a + b) / records.length;
  }

  /// Calculates the total water usage based on the selected filter value.
  /// @param records List of WaterUsage records
  /// @param selectedFilterValue The value to filter by (e.g., date, month, year)
  /// @return [double] The total water usage for the specified filter value, or 0 if no records match.
  static double calculateWaterUsage(List<WaterUsage> records, String selectedFilterValue) {
    if (records.isEmpty) return 0;
    if (records[0].date == '') return 0;

    if (records.last.date == selectedFilterValue) {
      return records.last.waterUsed.toDouble();
    }

    if (selectedFilterValue.length < 7) {
      return records.where((record) => record.date.startsWith(selectedFilterValue))
          .map((record) => record.waterUsed.toDouble())
          .fold(0, (a, b) => a + b);
    }

    String timestamp = selectedFilterValue.substring(0, 7);
    return _binarySearchWaterUsage(records, timestamp);
  }

  /// Performs a binary search to find the water usage for a specific timestamp.
  /// @param records List of WaterUsage records
  /// @param timestamp The timestamp to search for
  /// @return [double] The water usage for the specified timestamp, or 0 if not found.
  static double _binarySearchWaterUsage(List<WaterUsage> records, String timestamp) {
    int low = 0;
    int high = records.length - 1;
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      String midTimestamp = records[mid].date;
      if (midTimestamp == timestamp) {
        return records[mid].waterUsed.toDouble();
      } else if (midTimestamp.compareTo(timestamp) < 0) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return 0;
  }
}