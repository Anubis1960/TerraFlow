import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/entity/sensor_data.dart';
import '../components/bottom_navbar.dart';
import '../entity/device_data.dart';
import '../service/chart_data_processor.dart';
import '../service/filter_service.dart';
import '../components/date_filter_picker.dart';
import '../components/summary_card.dart';
import '../components/charts.dart';
import '../service/socket_service.dart';
import '../util/constants.dart';
import '../util/storage/base_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../util/export/file_downloader.dart';
import '../components/top_bar.dart';


/// A dashboard page to display device data including sensor readings and water usage.
class DeviceDashBoard extends StatefulWidget {
  final dynamic deviceId;
  const DeviceDashBoard({super.key, required this.deviceId});

  @override
  State<DeviceDashBoard> createState() => _DeviceDashBoardState(deviceId);
}

/// The state class for DeviceDashBoard that manages the device data and UI updates.
class _DeviceDashBoardState extends State<DeviceDashBoard> {
  final String deviceId;
  String deviceName = 'Device Dashboard';
  late ScrollController _scrollController;

  _DeviceDashBoardState(this.deviceId);

  DeviceData deviceData = DeviceData(
    sensorData: [],
    waterUsageData: [],
  );

  String filterType = 'day';
  String selectedFilterValue = '';
  List<SensorData> filteredRecords = [];
  Set<dynamic> filteredValues = {};
  double humidity = 0;
  double temperature = 0;
  double waterUsage = 0;
  bool _isLoading = true;

  /// Initializes the state of the DeviceDashBoard.
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 0, keepScrollOffset: true);
    // Initialize socket & fetch data
    initSocketAndFetchData();
  }

  /// Initializes the socket connection and fetches initial data from the server.
  void initSocketAndFetchData() {

    // Fetch initial data from server
    String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;
    url += '${Server.DEVICE_REST_URL}/$deviceId/data';

    BaseStorage.getStorageFactory().getToken().then((token) {
      http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'}).then((response) {
        print('Response status: ${response.statusCode}');
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          deviceData = DeviceData.fromJson(data);
          setState(() {
            if (deviceData.sensorData.isNotEmpty) {
              selectedFilterValue = deviceData.sensorData.last.timestamp.substring(0, 10);
              filteredRecords = FilterService.filterRecords(deviceData.sensorData, selectedFilterValue, filterType);
              humidity = FilterService.calculateAverage(filteredRecords, 'humidity');
              temperature = FilterService.calculateAverage(filteredRecords, 'temperature');
              waterUsage = FilterService.calculateWaterUsage(deviceData.waterUsageData, selectedFilterValue);
              filteredValues = FilterService.getFilterValues(deviceData.sensorData, filterType);
            }
          });
        }

        // Load device name
        BaseStorage.getStorageFactory().getDevices().then((deviceList) {
          for (var d in deviceList) {
            if (d.id == deviceId) {
              setState(() {
                deviceName = d.name;
              });
              break;
            }
          }

          // Get token again for socket init
          BaseStorage.getStorageFactory().getToken().then((token) {
            List<String> deviceIds = deviceList.map((d) => d.id).toList();
            SocketService.socket.emit('init', {
              'token': token,
              'devices': deviceIds,
            });

            setState(() {
              _isLoading = false;
            });
          });
        });
      }).catchError((error) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $error')),
        );
      });
    });

    // Initialize socket events
    SocketService.socket.on('export_response', (data) async {
      if (data.containsKey('file')) {
        final fileData = Uint8List.fromList(data['file']);
        await saveToStorage(context, fileData, "exported_data.xlsx");
      }
    });

    SocketService.socket.on('$deviceId/record', (data) {
      print('Received record for device $deviceId: $data');
      deviceData.sensorData.add( SensorData(
        timestamp: data['timestamp'],
        sensorData: data['sensor_data'],
      ));
      if (data['timestamp'].startsWith(selectedFilterValue)) {
        filteredRecords.add(SensorData(timestamp: data['timestamp'], sensorData: data['sensor_data']));
        setState(() {
          humidity = (humidity * (filteredRecords.length - 1) + data['sensor_data']['humidity']) / filteredRecords.length;
          temperature = (temperature * (filteredRecords.length - 1) + data['sensor_data']['temperature']) / filteredRecords.length;
        });
      }
    });

    SocketService.socket.on('$deviceId/water_usage', (data) {
      for (var record in deviceData.waterUsageData) {
        if (record.date == data['date']) {
          record.waterUsed += data['water_used'];
          break;
        }
      }
      if (selectedFilterValue.startsWith(data['date']) || data['date'].startsWith(selectedFilterValue)) {
        setState(() {
          waterUsage = waterUsage + data['water_used'];
        });
      }
    });
  }

  /// Saves the exported file to the device storage.
  /// @param context The build context of the application.
  /// @param fileData The data of the file to be saved.
  /// @param fileName The name of the file to be saved.
  /// @return A Future that completes when the file is saved.
  Future<void> saveToStorage(BuildContext context, Uint8List fileData, String fileName) async {
    FileDownloader.getFileDownloaderFactory().downloadFile(context, fileData, fileName);
  }

  /// Handles changes in the filter type and updates the filtered records and summary values.
  /// @param newValue The new filter type selected by the user.
  /// @return void
  void _onFilterTypeChange(String? newValue) {
    if (newValue == null) return;
    setState(() {
      filterType = newValue;
      filteredValues = FilterService.getFilterValues(deviceData.sensorData, filterType);
      selectedFilterValue = filteredValues.isNotEmpty ? filteredValues.last : '';
      filteredRecords = FilterService.filterRecords(deviceData.sensorData, selectedFilterValue, filterType);
      humidity = FilterService.calculateAverage(filteredRecords, 'humidity');
      temperature = FilterService.calculateAverage(filteredRecords, 'temperature');
      waterUsage = FilterService.calculateWaterUsage(deviceData.waterUsageData, selectedFilterValue);
    });
  }

  /// Opens a date picker to select a date and updates the filtered records and summary values.
  /// @return void
  void _onDatePick() async {
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
        filteredRecords = FilterService.filterRecords(deviceData.sensorData, formattedDate, filterType);
        humidity = FilterService.calculateAverage(filteredRecords, 'humidity');
        temperature = FilterService.calculateAverage(filteredRecords, 'temperature');
        waterUsage = FilterService.calculateWaterUsage(deviceData.waterUsageData, formattedDate);
      });
    }
  }

  /// Handles changes in the filter value and updates the filtered records and summary values.
  /// @param newValue The new filter value selected by the user.
  /// @return void
  void _onFilterValueChange(String? newValue) {
    if (newValue == null) return;
    setState(() {
      selectedFilterValue = newValue;
      filteredRecords = FilterService.filterRecords(deviceData.sensorData, newValue, filterType);
      humidity = FilterService.calculateAverage(filteredRecords, 'humidity');
      temperature = FilterService.calculateAverage(filteredRecords, 'temperature');
      waterUsage = FilterService.calculateWaterUsage(deviceData.waterUsageData, newValue);
    });
  }

  /// Disposes the socket listeners and scroll controller when the widget is removed from the widget tree.
  @override
  void dispose() {
    SocketService.socket.off('$deviceId/record');
    SocketService.socket.off('export_response');
    SocketService.socket.off('$deviceId/water_usage');
    _scrollController.dispose();
    super.dispose();
  }

  /// Builds the UI for the Device Dashboard page.
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: TopBar.buildTopBar(
        title: _isLoading ? "Loading..." : deviceName,
        context: context,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.02),
          child: Column(
            children: [
              // Filter Picker
              DateFilterPicker(
                filterType: filterType,
                selectedFilterValue: selectedFilterValue,
                filteredValues: filteredValues.cast<String>(),
                onFilterTypeChanged: _onFilterTypeChange,
                onDatePick: _onDatePick,
                onFilterValueChanged: _onFilterValueChange,
              ),

              SizedBox(height: screenHeight * 0.01),

              // Line Chart Placeholder
              _buildLineChart(screenWidth, screenHeight),

              SizedBox(height: screenHeight * 0.01),

              // Summary Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SummaryCardWidget(
                    title: 'Humidity',
                    value: humidity,
                    unit: '%',
                    color: Colors.blue,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  SummaryCardWidget(
                    title: 'Temperature',
                    value: temperature,
                    unit: '°C',
                    color: Colors.red,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  SummaryCardWidget(
                    title: 'Water Usage',
                    value: waterUsage,
                    unit: 'L',
                    color: Colors.green,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar.buildBottomNavBar(
          context: context,
          deviceId: deviceId,
          height: screenHeight * 0.08,
      )
    );
  }

  /// Builds the line chart widget to display sensor data.
  Widget _buildLineChart(double screenWidth, double screenHeight) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Charts.buildLineChart(
          title: 'Sensor Data',
          data: [
            ChartDataProcessor.getSensorDataSpots(filteredRecords, 'moisture', filterType),
            ChartDataProcessor.getSensorDataSpots(filteredRecords, 'humidity', filterType),
            ChartDataProcessor.getSensorDataSpots(filteredRecords, 'temperature', filterType),
          ],
          lineColors: [Colors.green, Colors.blue, Colors.red],
          xAxisLabels: filterType == 'year'
              ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
              : filterType == 'month'
              ? List.generate(31, (index) => (index + 1).toString())
              : [],
          headers: ['Moisture', 'Humidity', 'Temperature'],
          isScrollable: filterType == 'day',
          scrollController: _scrollController,
          minY: -30,
          maxY: 110,
          maxX: filterType == 'year'
              ? 12.0
              : filterType == 'month'
              ? 31.0
              : filteredRecords.length.toDouble(),
        ),
      ),
    );
  }
}