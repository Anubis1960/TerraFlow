import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_app/util/export/file_downloader.dart';
import 'package:mobile_app/util/socket_service.dart';
import 'package:mobile_app/components/charts.dart';
import 'package:mobile_app/components/summary_card.dart';
import 'package:mobile_app/components/top_navbar.dart';
import 'package:mobile_app/components/bottom_navbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_app/util/constants.dart';
import 'package:http/http.dart' as http;

import '../util/storage/base_storage.dart';

class DeviceDashBoard extends StatefulWidget {
  final dynamic deviceId;

  const DeviceDashBoard({super.key, required this.deviceId});

  @override
  _DeviceDashBoard createState() => _DeviceDashBoard(deviceId);
}

class _DeviceDashBoard extends State<DeviceDashBoard> {
  final dynamic deviceId;

  final ScrollController _scrollController = ScrollController(initialScrollOffset: 0, keepScrollOffset: true);

  _DeviceDashBoard(this.deviceId);

  Map<String, dynamic> deviceData = {
    'record': [],
    'water_usage': [],
  };
  String filterType = 'day';
  String selectedFilterValue = '';
  List<dynamic> filteredRecords = [];
  Set<dynamic> filteredValues = {};

  double humidity = 0;
  double temperature = 0;
  double waterUsage = 0;


  @override
  void initState() {
    super.initState();

    // Socket response listeners
    SocketService.socket.on('export_response', (data) async {
      if (data.containsKey('file')) {
        print('File data found in response');
        if (data['file'] is List<int>) {
          final fileData = Uint8List.fromList(data['file']);
          print('File data received: ${fileData.length} bytes');
          await saveToStorage(context, fileData, "exported_data.xlsx");
        }
      }
    });

    // Fetch device data
    String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;
    url += '${Server.DEVICE_REST_URL}/$deviceId/data';

    late Future<String> token = BaseStorage.getStorageFactory().getToken();

    token.then((value) {
      http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $value',
        }
      ).then((response) {
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body) as Map<String, dynamic>;
          setState(() {
            deviceData = data;
            if (deviceData['record'] != null && deviceData['record'].isNotEmpty) {
              selectedFilterValue = deviceData['record'].last['timestamp'].substring(0, 10);
              filteredRecords = _filterRecords(deviceData['record']);
              humidity = _calculateAverage(filteredRecords, 'humidity');
              temperature = _calculateAverage(filteredRecords, 'temperature');
              waterUsage = _calculateWaterUsage(deviceData['water_usage']);
              filteredValues = _getFilterValues(deviceData['record']);
            }
          });
        } else {
        }
      });
    });


    SocketService.socket.on('record', (data) {
      print('Received data: $data');
      deviceData['record'].add(data);

      if (data['timestamp'].startsWith(selectedFilterValue)) {
        filteredRecords.add(data);

        if (filterType == 'day'){
          filteredValues.add(data['timestamp'].substring(0, 10));
        } else if (filterType == 'month'){
          filteredValues.add(data['timestamp'].substring(0, 7));
        } else if (filterType == 'year'){
          filteredValues.add(data['timestamp'].substring(0, 4));
        }

        setState(() {
          deviceData = deviceData;
          filteredRecords = filteredRecords;
          filteredValues = filteredValues;
          humidity = _calculateAverage(filteredRecords, 'humidity');
          temperature = _calculateAverage(filteredRecords, 'temperature');
        });
      }
    });
    token.then((value) {
      late Future<List<String>> deviceIds = BaseStorage.getStorageFactory().getDeviceList();
      deviceIds.then((deviceIds) {
        Map<String, dynamic> data = {
          'token': value,
          'devices': deviceIds, // ✅ Now it's a real List<String>
        };

        SocketService.socket.emit('init', data);
      });
    });
  }

  @override
  void dispose() {
    // SocketService.socket.off('device_data_response');
    SocketService.socket.off('record');
    SocketService.socket.off('export_response');
    _scrollController.dispose();

    super.dispose();
  }



  Future<void> saveToStorage(BuildContext context, Uint8List fileData, String fileName) async {
    FileDownloader fileDownloader = FileDownloader.getFileDownloaderFactory();
    print('FileDownloader: $fileDownloader');
    await fileDownloader.downloadFile(context, fileData, fileName);
  }

  List<ChartData> _getSensorDataSpots(List<dynamic> records, String sensorKey) {

    if (filterType == 'day') {
      return records
          .asMap()
          .entries
          .map((entry) {
        var record = entry.value;
        return ChartData(
            record['timestamp'].substring(12, 19), record['sensor_data'][sensorKey].toDouble());
      }).toList();
    }
    else if (filterType == 'month'){
      List<String> xAxisLabels = List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'));
      Map<String, List<double>> aggregatedData = {};
      for (var record in records) {
        String timestamp = record['timestamp'];
        String key = timestamp.substring(8, 10); // Extract DD
        double value = record['sensor_data'][sensorKey].toDouble();
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
    }
    else if (filterType == 'year'){
      List<String> xAxisLabels = List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
      Map<String, String> monthMap = {
        '01': 'Jan',
        '02': 'Feb',
        '03': 'Mar',
        '04': 'Apr',
        '05': 'May',
        '06': 'Jun',
        '07': 'Jul',
        '08': 'Aug',
        '09': 'Sep',
        '10': 'Oct',
        '11': 'Nov',
        '12': 'Dec',
      };
      Map<String, List<double>> aggregatedData = {};

      for (var record in records) {
        String timestamp = record['timestamp'];
        String key = timestamp.substring(5, 7); // Extract MM
        double value = record['sensor_data'][sensorKey].toDouble();
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

  List<dynamic> _filterRecords(List<dynamic> records) {

    if (filterType == 'day') {
      return _binarySearchDateSubsection(records, selectedFilterValue, 'timestamp');
    } else if (filterType == 'month') {
      return _binarySearchDateSubsection(records, selectedFilterValue.substring(0, 7), 'timestamp');
    } else if (filterType == 'year') {
      return _binarySearchDateSubsection(records, selectedFilterValue.substring(0, 4), 'timestamp');
    }
    return records;
  }

  List<dynamic> _binarySearchDateSubsection(List<dynamic> records, String timestamp, String key) {

    int findBoundaryIndex(bool findFirst) {
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

    int firstIndex = findBoundaryIndex(true);
    if (firstIndex == -1) return [];
    int lastIndex = findBoundaryIndex(false);



    return records.sublist(firstIndex, lastIndex + 1);
  }

  Set<String> _getFilterValues(List<dynamic> records) {
    Set<String> values = {};
    if (records.isEmpty) {
      return values;
    }
    for (var record in records) {
      String timestamp = record['timestamp'];
      if (filterType == 'day') {
        values.add(timestamp.substring(0, 10)); // e.g. '2025/01/31'
      } else if (filterType == 'month') {
        values.add(timestamp.substring(0, 7)); // e.g. '2025/01'
      } else if (filterType == 'year') {
        values.add(timestamp.substring(0, 4)); // e.g. '2025'
      }
    }
    return values;
  }

  double _calculateAverage(List<dynamic> records, String key) {
    if (records.isEmpty) {
      return 0;
    }
    return records.map((record) => record['sensor_data'][key].toDouble()).reduce((a, b) => a + b) / records.length;
  }

  double _calculateWaterUsage(List<dynamic> records) {
    if (records.isEmpty) {
      return 0;
    }
    if (records[0]['date'] == '') {
      return 0;
    }

    if (records[records.length - 1]['date'] == selectedFilterValue) {
      return records[records.length - 1]['water_used'].toDouble();
    }

    if (selectedFilterValue.length < 7) {
      return records.where((record) => record['date'].startsWith(selectedFilterValue)).map((record) => record['water_used'].toDouble()).reduce((a, b) => a + b);
    }
    String timestamp = selectedFilterValue.substring(0, 7);
    return _binarySearchWaterUsage(records, timestamp);
  }

  double _binarySearchWaterUsage(List<dynamic> records, String timestamp) {
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

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: TopBar.buildTopBar(context: context, title: 'Device Dashboard'),
      body:  SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.02), // 2% of screen width
          child: Column(
            children: [
              _buildDatePicker(),
              SizedBox(height: screenHeight * 0.02), // 2% of screen height
              _buildLineChart(),
              SizedBox(height: screenHeight * 0.01), // 1% of screen height
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SummaryCard.buildSummaryCard(
                      title: 'Humidity',
                      value: humidity,
                      color: Colors.blue,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight
                  ),
                  SummaryCard.buildSummaryCard(
                      title: 'Temperature',
                      value: temperature,
                      color: Colors.red,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight
                  ),
                  SummaryCard.buildSummaryCard(
                      title: 'Water Usage',
                      value: waterUsage,
                      color: Colors.green,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: screenHeight * 0.15, // 15% of screen height
        child: BottomNavBar.buildBottomNavBar(context: context, deviceId: deviceId),
      ),
    );
  }


  Widget _buildLineChart(){
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Charts.buildLineChart(
          title: 'Sensor Data',
          data: [_getSensorDataSpots(filteredRecords, 'moisture'), _getSensorDataSpots(filteredRecords, 'humidity'), _getSensorDataSpots(filteredRecords, 'temperature')],
          lineColors: [Colors.green, Colors.blue, Colors.red],
          headers: ['Moisture', 'Humidity', 'Temperature'],
          isScrollable: filterType == 'day',
          scrollController: _scrollController, // Pass the scroll device here
          minY: -30,
          maxY: 110,
          xAxisLabels: filterType == 'year'
              ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
              : filterType == 'month'
              ? List.generate(31, (index) => (index + 1).toString())
              : [],

          maxX: filterType == 'year'
              ? 12.0
              : filterType == 'month'
              ? 31.0
              : filteredRecords.length.toDouble(),
        ),
      ),
    );
  }


  Widget _buildDatePicker() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: filterType,
                onChanged: (String? newValue) {
                  setState(() {
                    filterType = newValue!;
                    filteredValues = _getFilterValues(deviceData['record']);
                    selectedFilterValue = filteredValues.isNotEmpty ? filteredValues.last : '';
                    filteredRecords = _filterRecords(deviceData['record']);
                    humidity = _calculateAverage(filteredRecords, 'humidity');
                    temperature = _calculateAverage(filteredRecords, 'temperature');
                    waterUsage = _calculateWaterUsage(deviceData['water_usage']);
                  });
                },
                items: ['day', 'month', 'year'].map((value) => DropdownMenuItem(
                  value: value,
                  child: Center(
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )).toList(),
                isExpanded: true,
                style: TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontWeight: FontWeight.bold,
                ),
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
              ),
            ),
            const SizedBox(width: 10),
            // Conditional rendering based on filterType
            if (filterType == 'day')
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      String formattedDate = "${pickedDate.year}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.day.toString().padLeft(2, '0')}";
                      setState(() {
                        selectedFilterValue = formattedDate;
                        filteredRecords = _filterRecords(deviceData['record']);
                        humidity = _calculateAverage(filteredRecords, 'humidity');
                        temperature = _calculateAverage(filteredRecords, 'temperature');
                        waterUsage = _calculateWaterUsage(deviceData['water_usage']);
                      });
                    }
                  },
                  icon: Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    selectedFilterValue.isEmpty ? "Select Date" : selectedFilterValue,
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              )
            else
              Expanded(
                child: DropdownButton<String>(
                  value: selectedFilterValue.isNotEmpty && filteredValues.contains(selectedFilterValue)
                      ? selectedFilterValue
                      : filteredValues.isNotEmpty
                      ? filteredValues.first
                      : '',
                  onChanged: (String? newValue) {
                    setState(() {
                      if (newValue != null) {
                        selectedFilterValue = newValue;
                        filteredRecords = _filterRecords(deviceData['record']);
                        humidity = _calculateAverage(filteredRecords, 'humidity');
                        temperature = _calculateAverage(filteredRecords, 'temperature');
                        waterUsage = _calculateWaterUsage(deviceData['water_usage']);
                      }
                    });
                  },
                  items: filteredValues.isNotEmpty
                      ? filteredValues.map((value) => DropdownMenuItem<String>(
                    value: value,
                    child: Center(
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )).toList()
                      : [],
                  isExpanded: true,
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurpleAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

}