import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../util/SocketService.dart';
import '../util/Charts.dart';
import 'dart:async';

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
  Timer? updateThrottle;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('initState');
    }

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
      if (updateThrottle?.isActive ?? false) return; // Skip if already throttled

      updateThrottle = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            controllerData['record'].add(data);
          });
        }
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
      // Aggregate data into monthly or daily averages
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
      List<String> sortedKeys = aggregatedData.keys.toList()..sort();
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

  List<BarChartGroupData> _getWaterUsageData(List<dynamic> waterUsageData) {
    return waterUsageData.asMap().entries.map((entry) {
      int index = entry.key;
      var data = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data['water_used'].toDouble(),
            color: Colors.blue,
          ),
        ],
      );
    }).toList();
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
    return values.toList()..sort();
  }

  List<String> _getXAxisLabels(List<dynamic> records) {
    if (filterType == 'day') {
      // Ensure hours are unique and sorted
      Set<String> hours = {};
      for (var record in records) {
        String hour = record['timestamp'].substring(11, 13);
        hours.add('$hour:00');
      }
      return hours.toList()..sort();
    } else if (filterType == 'month') {
      // Ensure days are unique and sorted
      Set<String> days = {};
      for (var record in records) {
        String day = record['timestamp'].substring(8, 10);
        days.add(day);
      }
      return days.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    } else {
      // Ensure months are unique and sorted
      Set<String> months = {};
      for (var record in records) {
        String month = record['timestamp'].substring(5, 7);
        month = month.replaceAll('/', '');
        months.add(month);
      }
      if (kDebugMode) {
        print('Months: $months');
      }
      return months.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    }
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
    List<String> xAxisLabels = _getXAxisLabels(filteredRecords);

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
                xAxisLabels: xAxisLabels,
                isScrollable: filterType == 'day', // Only scrollable for daily
                maxX: filteredRecords.length.toDouble(), // Dynamically set maxX
              ),
              const SizedBox(height: 20),
              Charts.buildLineChart(
                title: 'Air Humidity',
                spots: _getSensorDataSpots(filteredRecords, 'air_humidity'),
                lineColor: Colors.blue,
                minY: 0,
                maxY: 110,
                xAxisLabels: xAxisLabels,
                isScrollable: filterType == 'day', // Only scrollable for daily
                maxX: filteredRecords.length.toDouble(), // Dynamically set maxX
              ),
              const SizedBox(height: 20),
              Charts.buildLineChart(
                title: 'Air Temperature',
                spots: _getSensorDataSpots(filteredRecords, 'air_temperature'),
                lineColor: Colors.red,
                minY: -30,
                maxY: 110,
                xAxisLabels: xAxisLabels,
                isScrollable: filterType == 'day', // Only scrollable for daily
                maxX: filteredRecords.length.toDouble(), // Dynamically set maxX
              ),
              const SizedBox(height: 20),
              Charts.buildBarChart(
                title: 'Monthly Water Usage',
                barGroups: _getWaterUsageData(controllerData['water_used_month']),
                xAxisLabels: xAxisLabels,
              ),
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
}