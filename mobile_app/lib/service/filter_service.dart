class FilterService {
  static List<dynamic> filterRecords(List<dynamic> records, String selectedFilterValue, String filterType) {
    if (filterType == 'day') {
      return _binarySearchDateSubsection(records, selectedFilterValue, 'timestamp');
    } else if (filterType == 'month') {
      return _binarySearchDateSubsection(records, selectedFilterValue.substring(0, 7), 'timestamp');
    } else if (filterType == 'year') {
      return _binarySearchDateSubsection(records, selectedFilterValue.substring(0, 4), 'timestamp');
    }
    return records;
  }

  static int _findBoundaryIndex(List<dynamic> records, String timestamp, String key, bool findFirst) {
    int low = 0, high = records.length - 1, result = -1;
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      String midTimestamp = records[mid][key];
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

  static List<dynamic> _binarySearchDateSubsection(List<dynamic> records, String timestamp, String key) {
    int firstIndex = _findBoundaryIndex(records, timestamp, key, true);
    if (firstIndex == -1) return [];
    int lastIndex = _findBoundaryIndex(records, timestamp, key, false);
    return records.sublist(firstIndex, lastIndex + 1);
  }

  static Set<String> getFilterValues(List<dynamic> records, String filterType) {
    Set<String> values = {};
    if (records.isEmpty) return values;

    for (var record in records) {
      String timestamp = record['timestamp'];
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

  static double calculateAverage(List<dynamic> records, String key) {
    if (records.isEmpty) return 0;
    return records.map((record) => record['sensor_data'][key].toDouble()).reduce((a, b) => a + b) / records.length;
  }

  static double calculateWaterUsage(List<dynamic> records, String selectedFilterValue) {
    if (records.isEmpty) return 0;
    if (records[0]['date'] == '') return 0;

    if (records.last['date'] == selectedFilterValue) {
      return records.last['water_used'].toDouble();
    }

    if (selectedFilterValue.length < 7) {
      return records.where((record) => record['date'].startsWith(selectedFilterValue))
          .map((record) => record['water_used'].toDouble())
          .fold(0, (a, b) => a + b);
    }

    String timestamp = selectedFilterValue.substring(0, 7);
    return _binarySearchWaterUsage(records, timestamp);
  }

  static double _binarySearchWaterUsage(List<dynamic> records, String timestamp) {
    int low = 0;
    int high = records.length - 1;
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      String midTimestamp = records[mid]['date'];
      if (midTimestamp == timestamp) {
        return records[mid]['water_used'].toDouble();
      } else if (midTimestamp.compareTo(timestamp) < 0) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return 0;
  }
}