import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  final ScrollController _scrollController = ScrollController();

  _ControllerDashBoard(this.controllerId);

  Map<String, dynamic> controllerData = {
    'record': [],
    'water_usage': [],
  };
  String filterType = 'day';
  String selectedFilterValue = '';

  @override
  void initState() {
    super.initState();

    SocketService.socket.on('controller_data_response', (data) {
      setState(() {
        controllerData = data;
        if (controllerData['record'] != null && controllerData['record'].isNotEmpty) {
          selectedFilterValue = controllerData['record'][0]['timestamp'].substring(0, 10);
        }
        if (controllerData['water_usage'] == null) {
          controllerData['water_usage'] = [
            {
              'date': '',
              'water_used': 0,
            },
          ];
        }

        if (controllerData['record'].isEmpty) {
          controllerData['record'] = [
            {
              'timestamp': '',
              'sensor_data': {
                'soil_moisture': 0,
                'air_humidity': 0,
                'air_temperature': 0,
              },
            },
          ];
        }
      });
    });

    SocketService.socket.on('record', (data) {
      controllerData['record'].add(data);
      setState(() {
        controllerData['record'] = controllerData['record'];
      });
    });

    SocketService.socket.emit('fetch_controller_data', {
      'controller_id': controllerId,
    });

    if (controllerData['water_usage'].isEmpty) {
      controllerData['water_usage'] = [
        {
          'date': '',
          'water_used': 0,
        },
      ];
    }
  }

  @override
  void dispose() {
    SocketService.socket.off('controller_data_response');
    SocketService.socket.off('record');
    _scrollController.dispose();
    super.dispose();
  }

  List<FlSpot> _getSensorDataSpots(List<dynamic> records, String sensorKey) {
    Map<String, double> xAxisMap = {};
    List<String> xAxisLabels = [];
    if (filterType == 'day') {
      return records.asMap().entries.map((entry) {
        int index = entry.key;
        var record = entry.value;
        return FlSpot(index.toDouble(), record['sensor_data'][sensorKey].toDouble());
      }).toList();
    }

    if (filterType == 'year') {
      // Group by months (01 - 12)
      for (var i = 1; i <= 12; i++) {
        xAxisMap[i.toString().padLeft(2, '0')] = (i - 1).toDouble(); // Map Jan-Dec to 0-11
        xAxisLabels.add(i.toString().padLeft(2, '0')); // ["01", "02", ..., "12"]
      }
    } else if (filterType == 'month') {
      // Group by days (1-31)
      for (var i = 1; i <= 31; i++) {
        xAxisMap[i.toString().padLeft(2, '0')] = (i - 1).toDouble();
        xAxisLabels.add(i.toString()); // ["1", "2", ..., "31"]
      }
    }

    Map<String, List<double>> aggregatedData = {};
    for (var record in records) {
      String timestamp = record['timestamp'];
      String key = filterType == 'year'
          ? timestamp.substring(5, 7) // Extract month (MM)
          : timestamp.substring(8, 10); // Extract day (DD)

      double value = record['sensor_data'][sensorKey].toDouble();
      if (!aggregatedData.containsKey(key)) {
        aggregatedData[key] = [];
      }
      aggregatedData[key]!.add(value);
    }

    List<FlSpot> spots = [];
    aggregatedData.forEach((key, values) {
      if (xAxisMap.containsKey(key)) {
        double avg = values.reduce((a, b) => a + b) / values.length;
        spots.add(FlSpot(xAxisMap[key]!, avg));
      }
    });

    return spots;
  }


  List<dynamic> _filterRecords(List<dynamic> records) {
    if (filterType == 'day') {
      return records.where((record) => record['timestamp'].startsWith(selectedFilterValue)).toList();
    } else if (filterType == 'month') {
      return records.where((record) => record['timestamp'].substring(0, 7) == selectedFilterValue).toList();
    } else if (filterType == 'year') {
      return records.where((record) => record['timestamp'].substring(0, 4) == selectedFilterValue).toList();
    }
    return records;
  }

  List<String> _getFilterValues(List<dynamic> records) {
    Set<String> values = {};
    if (records.isEmpty) {
      return [];
    }
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
    return values.toList();
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
      print('No water usage records found');
      return 0;
    }

    if (records[records.length - 1]['date'] == selectedFilterValue) {
      return records[records.length - 1]['water_used'].toDouble();
    }

    if (selectedFilterValue.length < 7) {
      return records.map((record) => record['water_used'].toDouble()).reduce((a, b) => a + b);
    }
    String timestamp = selectedFilterValue.substring(0, 7);
    print('Month: $timestamp');
    return _binarySearchTimestamp(records, timestamp);
  }

  double _binarySearchTimestamp(List<dynamic> records, String timestamp) {
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
    List<dynamic> filteredRecords = _filterRecords(controllerData['record']);
    double avgHumidity = _calculateAverage(filteredRecords, 'air_humidity');
    double avgTemperature = _calculateAverage(filteredRecords, 'air_temperature');
    double avgWaterUsage = _calculateWaterUsage(controllerData['water_usage']);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Controller Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 8,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(11.0),
          child: Column(
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(11.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: filterType,
                          onChanged: (String? newValue) {
                            setState(() {
                              filterType = newValue!;
                              selectedFilterValue = _getFilterValues(controllerData['record']).last;
                            });
                          },
                          items: ['day', 'month', 'year'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
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
                          value: selectedFilterValue == '' ? null : selectedFilterValue,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedFilterValue = newValue!;
                            });
                          },
                          items: controllerData['record'].isNotEmpty
                              ? _getFilterValues(controllerData['record']).map((value) => DropdownMenuItem(value: value, child: Text(value))).toList()
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
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(11.0),
                  child: Charts.buildLineChart(
                    title: 'Soil Moisture',
                    spots: _getSensorDataSpots(filteredRecords, 'soil_moisture'),
                    lineColor: Colors.green,
                    minY: 0,
                    maxY: 110,
                    xAxisLabels: filterType == 'year'
                        ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
                        : filterType == 'month' ? List.generate(31, (index) => (index + 1).toString()) : [],
                    isScrollable: filterType == 'day',
                    scrollController: _scrollController, // Pass the scroll controller here
                    maxX: filterType == 'year'
                        ? 12.0
                        : filterType == 'month'
                        ? 31.0
                        : filteredRecords.length.toDouble(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryCard('Humidity', avgHumidity, Colors.blue),
                  _buildSummaryCard('Temperature', avgTemperature, Colors.red),
                  _buildSummaryCard('Water Usage', avgWaterUsage, Colors.deepPurple),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      SocketService.socket.emit('trigger_irrigation', {
                        'controller_id': controllerId,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Trigger Irrigation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _showScheduleDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Schedule Irrigation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
}