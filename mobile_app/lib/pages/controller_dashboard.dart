import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/util/SharedPreferencesStorage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mobile_app/pages/home.dart';
import 'package:mobile_app/pages/login.dart';

import '../util/SocketService.dart';
import '../util/Charts.dart';

class ControllerDashBoard extends StatefulWidget {
  final dynamic controllerId;

  const ControllerDashBoard({super.key, required this.controllerId});

  @override
  _ControllerDashBoard createState() => _ControllerDashBoard(controllerId);
}

class _ControllerDashBoard extends State<ControllerDashBoard> {
  final dynamic controllerId;

  final ScrollController _scrollController = ScrollController(initialScrollOffset: 0, keepScrollOffset: true);

  _ControllerDashBoard(this.controllerId);

  Map<String, dynamic> controllerData = {
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
    print('Controller Dashboard init');

    // Socket response listeners
    SocketService.socket.on('export_response', (data) async {
      if (data.containsKey('file')){
        if (data['file'] is List<int>) {
          final fileData = Uint8List.fromList(data['file']);
          await saveToInternalStorage(fileData, Permission.storage);
        }
      }
    });

    SocketService.socket.on('controller_data_response', (data) {
      setState(() {
        controllerData = data;
        if (controllerData['record'] != null && controllerData['record'].isNotEmpty) {
          selectedFilterValue = controllerData['record'].last['timestamp'].substring(0, 10);

          filteredRecords = _filterRecords(controllerData['record']);
          humidity = _calculateAverage(filteredRecords, 'air_humidity');
          temperature = _calculateAverage(filteredRecords, 'air_temperature');
          waterUsage = _calculateWaterUsage(controllerData['water_usage']);
          filteredValues = _getFilterValues(controllerData['record']);

          setState(() {
            selectedFilterValue = selectedFilterValue; // This will update correctly now
          });
        }
      });
    });

    SocketService.socket.on('record', (data) {
      controllerData['record'].add(data);

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
          controllerData = controllerData;
          filteredRecords = filteredRecords;
          filteredValues = filteredValues;
          humidity = _calculateAverage(filteredRecords, 'air_humidity');
          temperature = _calculateAverage(filteredRecords, 'air_temperature');
          print("setState triggered, selectedFilterValue: $selectedFilterValue");
        });
      }
    });

    SocketService.socket.emit('fetch_controller_data', {
      'controller_id': controllerId,
    });

    print('Selected Filter Value: $selectedFilterValue');
    print('Filtered Records: $filteredRecords');
    print('Filtered Values: $filteredValues');

  }

  @override
  void dispose() {
    print('Controller Dashboard Disposed');
    SocketService.socket.off('controller_data_response');
    SocketService.socket.off('record');
    SocketService.socket.off('export_response');
    _scrollController.dispose();

    super.dispose();
  }


  Future<void> saveToInternalStorage(Uint8List fileData, Permission permission) async {
    try {
      if(Platform.isAndroid){
        AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
        if (build.version.sdkInt >= 30) {
          var re = await Permission.manageExternalStorage.request();
          if (re.isGranted) {
            final directory = await getExternalStorageDirectory();
            final path = directory!.path;
            final file = File('$path/exported_data.xlsx');
            await file.writeAsBytes(fileData);
          }
          else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Permission denied'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
        else{
          var re = await permission.request();
          if (re.isGranted) {
            final directory = await getExternalStorageDirectory();
            final path = directory!.path;
            final file = File('$path/exported_data.csv');
            await file.writeAsBytes(fileData);
          }
          else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Permission denied'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving file: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  List<ChartData> _getSensorDataSpots(List<dynamic> records, String sensorKey) {
    print("getSensorDataSpots");

    if (filterType == 'day') {
      print("Filtering records for day: $selectedFilterValue");
      return records
          .asMap()
          .entries
          .map((entry) {
        int index = entry.key;
        var record = entry.value;
        return ChartData(
            index.toString(), record['sensor_data'][sensorKey].toDouble());
      }).toList();
    }
    List<String> xAxisLabels = filterType == 'year'
        ? ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']
        :  List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'));

    // Map to store aggregated data
    Map<String, List<double>> aggregatedData = {};

    // Map to convert month numbers to month names
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

    // Aggregate data
    for (var record in records) {
      String timestamp = record['timestamp'];
      String key = filterType == 'year'
          ? timestamp.substring(5, 7) // Extract MM
          : timestamp.substring(8, 10); // Extract DD

      double value = record['sensor_data'][sensorKey].toDouble();
      if (!aggregatedData.containsKey(key)) {
        aggregatedData[key] = [];
      }
      aggregatedData[key]!.add(value);
    }

    print("Aggregated Data: $aggregatedData");

    List<ChartData> chartData = [];
    for (var label in xAxisLabels) {
      if (aggregatedData.containsKey(label)) {
        double avg = aggregatedData[label]!.reduce((a, b) => a + b) / aggregatedData[label]!.length;
        if (filterType == 'year') {
          chartData.add(ChartData(monthMap[label] ?? label, avg));
        } else {
          chartData.add(ChartData(label, avg));
        }
      } else {
        // Add null for missing data
        if (filterType == 'year') {
          chartData.add(ChartData(monthMap[label] ?? label, null));
        } else {
          chartData.add(ChartData(label, null));
        }
      }
    }

    return chartData;
  }

  List<dynamic> _filterRecords(List<dynamic> records) {
    print("Filtering records for: $selectedFilterValue with filterType: $filterType");

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
    print("Performing binary search for timestamp: $timestamp");

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

    print("Binary search result: firstIndex=$firstIndex, lastIndex=$lastIndex");


    return records.sublist(firstIndex, lastIndex + 1);
  }

  Set<String> _getFilterValues(List<dynamic> records) {
    print("getFilterValues");
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
    print("calculateAverage");
    if (records.isEmpty) {
      return 0;
    }
    return records.map((record) => record['sensor_data'][key].toDouble()).reduce((a, b) => a + b) / records.length;
  }

  double _calculateWaterUsage(List<dynamic> records) {
    print("calculateWaterUsage");
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
      appBar: _buildAppBar(),
      body: selectedFilterValue.isEmpty || filteredRecords.isEmpty || controllerData.isEmpty
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
        ),
      )
          : SingleChildScrollView(
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
                  _buildSummaryCard('Humidity', humidity, Colors.blue, screenWidth, screenHeight),
                  _buildSummaryCard('Temperature', temperature, Colors.red, screenWidth, screenHeight),
                  _buildSummaryCard('Water Usage', waterUsage, Colors.greenAccent, screenWidth, screenHeight),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: screenHeight * 0.15, // 15% of screen height
        child: _buildBottomNavBar(),
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
          title: 'Soil Moisture',
          data: _getSensorDataSpots(filteredRecords, 'soil_moisture'),
          lineColor: Colors.green,
          minY: 0,
          maxY: 110,
          xAxisLabels: filterType == 'year'
              ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
              : filterType == 'month'
              ? List.generate(31, (index) => (index + 1).toString())
              : [],
          isScrollable: filterType == 'day',
          scrollController: _scrollController, // Pass the scroll controller here
          maxX: filterType == 'year'
              ? 12.0
              : filterType == 'month'
              ? 31.0
              : filteredRecords.length.toDouble(),
        ),
      ),
    );
  }


  Widget _buildDatePicker(){
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: filterType,
                onChanged: (String? newValue) {
                  setState(() {
                    filterType = newValue!;
                    filteredValues = _getFilterValues(controllerData['record']);
                    selectedFilterValue = filteredValues.isNotEmpty ? filteredValues.last : '';
                    filteredRecords = _filterRecords(controllerData['record']);
                    humidity = _calculateAverage(filteredRecords, 'air_humidity');
                    temperature = _calculateAverage(filteredRecords, 'air_temperature');
                    waterUsage = _calculateWaterUsage(controllerData['water_usage']);
                  });
                },
                items: ['day', 'month', 'year'].map((value) => DropdownMenuItem(
                  value: value,
                  child: Center(  // Center the text inside the DropdownMenuItem
                    child: Text(
                      value,
                      textAlign: TextAlign.center,  // Ensures the text is centered inside the child widget
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
            Expanded(
              child: DropdownButton<String>(
                value: selectedFilterValue.isNotEmpty && filteredValues.contains(selectedFilterValue)
                    ? selectedFilterValue
                    : filteredValues.isNotEmpty
                    ? filteredValues.first
                    : '',  // Use an empty string or a fallback value
                onChanged: (String? newValue) {
                  setState(() {
                    if (newValue != null) {
                      selectedFilterValue = newValue;
                      filteredRecords = _filterRecords(controllerData['record']);
                      humidity = _calculateAverage(filteredRecords, 'air_humidity');
                      temperature = _calculateAverage(filteredRecords, 'air_temperature');
                      waterUsage = _calculateWaterUsage(controllerData['water_usage']);
                    }
                  });
                },
                items: filteredValues.isNotEmpty
                    ? filteredValues.map((value) => DropdownMenuItem<String>(value: value, child: Text(
                    value,
                  textAlign: TextAlign.center,
                ))).toList()
                    : [],
                isExpanded: true,
                style: TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontWeight: FontWeight.bold,

                ),
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurpleAccent),
              ),
            )

          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(){
    return BottomAppBar(
      elevation: 0,
      color: Colors.white,
      shape: CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Home Button
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    // Navigate to Home Screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Home()),
                    );
                  },
                  icon: Icon(Icons.home, color: Colors.deepPurpleAccent),
                  tooltip: 'Home',
                ),
                Flexible(
                  child: Text(
                    'Home',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 14, // Adjusted font size
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center, // Center the text
                  ),
                ),
              ],
            ),
          ),
          // Trigger Irrigation Button
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    SocketService.socket.emit('trigger_irrigation', {
                      'controller_id': controllerId,
                    });
                  },
                  icon: Icon(Icons.water_drop, color: Colors.deepPurpleAccent),
                  tooltip: 'Trigger Irrigation',
                ),
                Flexible(
                  child: Text(
                    'Irrigation',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 14, // Adjusted font size
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Schedule Irrigation Button
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    _showScheduleDialog(context);
                  },
                  icon: Icon(Icons.schedule, color: Colors.deepPurpleAccent),
                  tooltip: 'Schedule Irrigation',
                ),
                Flexible(
                  child: Text(
                    'Schedule',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 14, // Adjusted font size
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Export Data Button
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    SocketService.socket.emit('export', {
                      'controller_id': controllerId,
                    });
                  },
                  icon: Icon(Icons.cloud_download, color: Colors.green),
                  tooltip: 'Export Data',
                ),
                Flexible(
                  child: Text(
                    'Export',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14, // Adjusted font size
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color, double screenWidth, double screenHeight) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: screenWidth * 0.28, // 28% of screen width
        height: screenHeight * 0.12, // 12% of screen height
        padding: EdgeInsets.all(screenWidth * 0.02), // 2% of screen width
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: screenHeight * 0.018, // 1.8% of screen height
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: screenHeight * 0.01), // 1% of screen height
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: screenHeight * 0.022, // 2.2% of screen height
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showScheduleDialog(BuildContext context) {
    List<String> type = ['DAILY', 'WEEKLY', 'MONTHLY'];
    String selectedType = type[0];

    TimeOfDay selectedTime = TimeOfDay(hour: 0, minute: 0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Schedule Irrigation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedType,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedType = newValue!;
                      });
                    },
                    items: type.map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text('Select Time'),
                    trailing: Text(
                      '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    onTap: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedTime = pickedTime;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final formattedTime = '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}';
                    SocketService.socket.emit('schedule_irrigation', {
                      'controller_id': controllerId,
                      'schedule_type': selectedType,
                      'schedule_time': formattedTime,
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(){
    return AppBar(
      title: Text(
        'Dashboard',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.deepPurpleAccent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: Colors.white), // Logout icon
          onPressed: () async {
            try {
              // Fetch user ID and controller IDs asynchronously
              final String userId = await SharedPreferencesStorage.getUserId();
              final List<String> controllerIds = await SharedPreferencesStorage.getControllerList();

              // Emit logout event via SocketService
              SocketService.socket.emit('logout', {
                'user_id': userId,
                'controllers': controllerIds,
              });

              // Clear user data from SharedPreferences
              await SharedPreferencesStorage.saveUserId('');
              await SharedPreferencesStorage.saveControllerList([]);

              // Navigate to the login page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            } catch (e) {
              // Handle any errors that occur during the async operations
              print('Error during logout: $e');
            }
          },
        ),
      ],
    );
  }
}