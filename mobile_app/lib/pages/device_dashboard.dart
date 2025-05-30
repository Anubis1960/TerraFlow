import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../components/bottom_navbar.dart';
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

class DeviceDashBoard extends StatefulWidget {
  final dynamic deviceId;
  const DeviceDashBoard({super.key, required this.deviceId});

  @override
  State<DeviceDashBoard> createState() => _DeviceDashBoardState(deviceId);
}

class _DeviceDashBoardState extends State<DeviceDashBoard> {
  final dynamic deviceId;
  String deviceName = 'Device Dashboard';
  late ScrollController _scrollController;

  _DeviceDashBoardState(this.deviceId);

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 0, keepScrollOffset: true);
    // Initialize socket & fetch data
    initSocketAndFetchData();
  }

  void initSocketAndFetchData() {

    // Fetch initial data from server
    String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;
    url += '${Server.DEVICE_REST_URL}/$deviceId/data';

    BaseStorage.getStorageFactory().getToken().then((token) {
      http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'}).then((response) {
        print('Response status: ${response.statusCode}');
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          setState(() {
            deviceData = data;
            if (deviceData['record'].isNotEmpty) {
              selectedFilterValue = deviceData['record'].last['timestamp'].substring(0, 10);
              filteredRecords = FilterService.filterRecords(deviceData['record'], selectedFilterValue, filterType);
              humidity = FilterService.calculateAverage(filteredRecords, 'humidity');
              temperature = FilterService.calculateAverage(filteredRecords, 'temperature');
              waterUsage = FilterService.calculateWaterUsage(deviceData['water_usage'], selectedFilterValue);
              filteredValues = FilterService.getFilterValues(deviceData['record'], filterType);
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

    SocketService.socket.on('record', (data) {
      deviceData['record'].add(data);
      if (data['timestamp'].startsWith(selectedFilterValue)) {
        filteredRecords.add(data);
        setState(() {
          humidity = FilterService.calculateAverage(filteredRecords, 'humidity');
          temperature = FilterService.calculateAverage(filteredRecords, 'temperature');
        });
      }
    });

    SocketService.socket.on('water_usage', (data) {
      for (var record in deviceData['water_usage']) {
        if (record['date'] == data['date']) {
          record['usage'] += data['water_usage'];
          return;
        }
      }
      if (data['date'].startsWith(selectedFilterValue)) {
        setState(() {
          waterUsage = FilterService.calculateWaterUsage(deviceData['water_usage'], selectedFilterValue);
        });
      }
    });
  }

  Future<void> saveToStorage(BuildContext context, Uint8List fileData, String fileName) async {
    FileDownloader.getFileDownloaderFactory().downloadFile(context, fileData, fileName);
  }

  void _onFilterTypeChange(String? newValue) {
    if (newValue == null) return;
    setState(() {
      filterType = newValue;
      filteredValues = FilterService.getFilterValues(deviceData['record'], filterType);
      selectedFilterValue = filteredValues.isNotEmpty ? filteredValues.last : '';
      filteredRecords = FilterService.filterRecords(deviceData['record'], selectedFilterValue, filterType);
      humidity = FilterService.calculateAverage(filteredRecords, 'humidity');
      temperature = FilterService.calculateAverage(filteredRecords, 'temperature');
      waterUsage = FilterService.calculateWaterUsage(deviceData['water_usage'], selectedFilterValue);
    });
  }

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
        filteredRecords = FilterService.filterRecords(deviceData['record'], formattedDate, filterType);
        humidity = FilterService.calculateAverage(filteredRecords, 'humidity');
        temperature = FilterService.calculateAverage(filteredRecords, 'temperature');
        waterUsage = FilterService.calculateWaterUsage(deviceData['water_usage'], formattedDate);
      });
    }
  }

  void _onFilterValueChange(String? newValue) {
    if (newValue == null) return;
    setState(() {
      selectedFilterValue = newValue;
      filteredRecords = FilterService.filterRecords(deviceData['record'], newValue, filterType);
      humidity = FilterService.calculateAverage(filteredRecords, 'humidity');
      temperature = FilterService.calculateAverage(filteredRecords, 'temperature');
      waterUsage = FilterService.calculateWaterUsage(deviceData['water_usage'], newValue);
    });
  }

  @override
  void dispose() {
    SocketService.socket.off('record');
    SocketService.socket.off('export_response');
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: TopBar.buildTopBar(title: _isLoading ? "Loading..." : deviceName, context: context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.02),
          child: Column(
            children: [
              DateFilterPicker(
                filterType: filterType,
                selectedFilterValue: selectedFilterValue,
                filteredValues: filteredValues.cast<String>(),
                onFilterTypeChanged: _onFilterTypeChange,
                onDatePick: _onDatePick,
                onFilterValueChanged: _onFilterValueChange,
              ),
              SizedBox(height: screenHeight * 0.01),
              _buildLineChart(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.01),
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
      bottomNavigationBar: SizedBox(
        height: screenHeight * 0.135,
        child: BottomNavBar.buildBottomNavBar(context: context, deviceId: deviceId),
      ),
    );
  }

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