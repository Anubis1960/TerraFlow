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

  _ControllerDashBoard(this.controllerId);

  Map<String, dynamic> controllerData = {
    'record': [],
    'water_used_month': [],
  };
  String filterType = 'day';
  String selectedFilterValue = '';

  @override
  void initState() {
    super.initState();

    SocketService.socket.on('controller_data_response', (data) {
      if (kDebugMode) {
        print('Received controller data response: $data');
      }
      setState(() {
        controllerData = data;
        if (controllerData['record'] != null && controllerData['record'].isNotEmpty) {
          selectedFilterValue = controllerData['record'][0]['timestamp'].substring(0, 10);
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
  }

  @override
  void dispose() {
    SocketService.socket.off('controller_data_response');
    SocketService.socket.off('record');
    super.dispose();
  }

  List<FlSpot> _getSensorDataSpots(List<dynamic> records, String sensorKey) {
    if (filterType == 'year' || filterType == 'month') {
      Map<String, List<double>> aggregatedData = {};
      for (var record in records) {
        String timestamp = record['timestamp'];
        String key = filterType == 'year' ? timestamp.substring(5, 7) : timestamp.substring(8, 10); // Extract month or day
        double value = record['sensor_data'][sensorKey].toDouble();

        if (!aggregatedData.containsKey(key)) {
          aggregatedData[key] = [];
        }
        aggregatedData[key]!.add(value);
      }

      // Sort keys (months or days) and calculate averages
      List<String> sortedKeys = aggregatedData.keys.toList();
      List<FlSpot> spots = [];
      for (var key in sortedKeys) {
        double avg = aggregatedData[key]!.reduce((a, b) => a + b) / aggregatedData[key]!.length;
        spots.add(FlSpot(spots.length.toDouble(), avg));
      }

      return spots;
    } else {
      // For daily, use all data points
      return records.asMap().entries.map((entry) {
        int index = entry.key;
        var record = entry.value;
        return FlSpot(index.toDouble(), record['sensor_data'][sensorKey].toDouble());
      }).toList();
    }
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

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredRecords = _filterRecords(controllerData['record']);
    double avgHumidity = _calculateAverage(filteredRecords, 'air_humidity');
    double avgTemperature = _calculateAverage(filteredRecords, 'air_temperature');
    double avgWaterUsage = controllerData['water_used_month'].isNotEmpty ? 0.0 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Controller Details: ${widget.controllerId}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  DropdownButton<String>(
                    value: filterType,
                    onChanged: (String? newValue) {
                      setState(() {
                        filterType = newValue!;
                        selectedFilterValue = _getFilterValues(controllerData['record']).last;
                      });
                    },
                    items: ['day', 'month', 'year'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedFilterValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFilterValue = newValue!;
                      });
                    },
                    items: controllerData['record'].isNotEmpty
                        ? _getFilterValues(controllerData['record']).map((value) => DropdownMenuItem(value: value, child: Text(value))).toList()
                        : [],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Charts.buildLineChart(
                title: 'Soil Moisture',
                spots: _getSensorDataSpots(filteredRecords, 'soil_moisture'),
                lineColor: Colors.green,
                minY: 0,
                maxY: 110,
                xAxisLabels: [],
                isScrollable: filterType == 'day', // Only scrollable for daily
                maxX: filteredRecords.length.toDouble(), // Dynamically set maxX
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryCard('Humidity', avgHumidity, Colors.blue),
                  _buildSummaryCard('Temperature', avgTemperature, Colors.red),
                  _buildSummaryCard('Water Usage', avgWaterUsage, Colors.green),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      SocketService.socket.emit('trigger_irrigation', {
                        'controller_id': controllerId,
                      });
                    },
                    child: const Text('Trigger Irrigation'),
                  ),
                  ElevatedButton(onPressed: (){
                    _showScheduleDialog(context);
                  }, child: const Text('Schedule Irrigation'))
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}