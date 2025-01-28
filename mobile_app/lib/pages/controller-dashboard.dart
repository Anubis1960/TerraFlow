import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../util/SharedPreferencesStorage.dart';
import '../util/SocketService.dart';

class ControllerDashBoard extends StatefulWidget {
  final dynamic controllerId;

  const ControllerDashBoard({super.key, required this.controllerId});

  @override
  _ControllerDashBoard createState() => _ControllerDashBoard(controllerId);
}

class _ControllerDashBoard extends State<ControllerDashBoard> {
  final dynamic controllerId;

  _ControllerDashBoard(this.controllerId);

  Map<String, dynamic> controllerData = {};
  String filterType = 'day'; // Default filter type: day, month, year
  String selectedFilterValue = ''; // Selected filter value (e.g., '2025/01')

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('initState');
    }
    Future<String> userId = SharedPreferencesStorage.getUserId();

    SocketService.socket.on('controller_data_response', (data) {
      if (kDebugMode) {
        print('Received controller data response: $data');
      }
      setState(() {
        controllerData = data;
        // Set default filter value to the first available timestamp
        if (controllerData['record'] != null && controllerData['record'].isNotEmpty) {
          selectedFilterValue = controllerData['record'][0]['timestamp'].substring(0, 10); // yyyy/mm/dd
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
    super.dispose();
  }

  // Helper function to extract sensor data for charts
  List<FlSpot> _getSensorDataSpots(List<dynamic> records, String sensorKey) {
    return records.asMap().entries.map((entry) {
      int index = entry.key;
      var record = entry.value;
      return FlSpot(index.toDouble(), record['sensor_data'][sensorKey].toDouble());
    }).toList();
  }

  // Helper function to extract water usage data for bar chart
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

  // Filter records based on the selected filter type and value
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

  // Get unique filter values (days, months, or years) from records
  List<String> _getFilterValues(List<dynamic> records) {
    Set<String> values = {};
    for (var record in records) {
      String timestamp = record['timestamp'];
      if (filterType == 'day') {
        values.add(timestamp.substring(0, 10)); // yyyy/mm/dd
      } else if (filterType == 'month') {
        values.add(timestamp.substring(0, 7)); // yyyy/mm
      } else if (filterType == 'year') {
        values.add(timestamp.substring(0, 4)); // yyyy
      }
    }
    return values.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> records = controllerData['record'] ?? [];
    List<dynamic> waterUsageData = controllerData['water_used_month'] ?? [];

    // Filter records based on the selected filter
    List<dynamic> filteredRecords = _filterRecords(records);

    return Scaffold(
      appBar: AppBar(
        title: Text('Controller Details: $controllerId'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Filter Dropdowns
              Row(
                children: [
                  DropdownButton<String>(
                    value: filterType,
                    onChanged: (String? newValue) {
                      setState(() {
                        filterType = newValue!;
                        // Reset selected filter value
                        selectedFilterValue = _getFilterValues(records).first;
                      });
                    },
                    items: <String>['day', 'month', 'year'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedFilterValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFilterValue = newValue!;
                      });
                    },
                    items: _getFilterValues(records).map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Soil Moisture Line Chart
              _buildLineChart(
                title: 'Soil Moisture',
                spots: _getSensorDataSpots(filteredRecords, 'soil_moisture'),
                color: Colors.green,
                minY: 0,
                maxY: 100,
              ),
              SizedBox(height: 20),

              // Air Humidity Line Chart
              _buildLineChart(
                title: 'Air Humidity',
                spots: _getSensorDataSpots(filteredRecords, 'air_humidity'),
                color: Colors.blue,
                minY: 0,
                maxY: 100,
              ),
              SizedBox(height: 20),

              // Air Temperature Line Chart
              _buildLineChart(
                title: 'Air Temperature',
                spots: _getSensorDataSpots(filteredRecords, 'air_temperature'),
                color: Colors.red,
                minY: -30,
                maxY: 80,
              ),
              SizedBox(height: 20),

              // Water Usage Bar Chart
              _buildBarChart(
                title: 'Monthly Water Usage',
                barGroups: _getWaterUsageData(waterUsageData),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build a line chart
  Widget _buildLineChart({required String title, required List<FlSpot> spots, required Color color, required double minY, required double maxY}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(show: true),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper function to build a bar chart
  Widget _buildBarChart({required String title, required List<BarChartGroupData> barGroups}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(show: true),
              borderData: FlBorderData(show: true),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }
}