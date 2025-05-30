import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/socket_service.dart';
import 'package:mobile_app/util/storage/base_storage.dart';
import 'package:mobile_app/components/top_bar.dart';
import 'package:mobile_app/util/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<String> token;
  late Future<List<String>> deviceIds;
  final Set<String> _selectedDeviceIds = {};

  @override
  void initState() {
    super.initState();
    token = BaseStorage.getStorageFactory().getToken();
    deviceIds = _loadDeviceIds();

    SocketService.socket.on('error', (data) {
      if (data['error_msg'] != null && data['error_msg'].isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error_msg']),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    token.then((onUser) async {
      final List<String> onDevice = await deviceIds; // ✅ Wait for the result

      if (onDevice.isEmpty) {
        String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;
        url += '${Server.USER_REST_URL}/devices';

        var res = await http.get(
          Uri.parse(url),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $onUser',
          },
        );

        if (res.statusCode == 200) {
          var devices = jsonDecode(res.body);
          if (devices.isNotEmpty) {
            BaseStorage.getStorageFactory().saveData('device_ids', devices);
            setState(() {
              deviceIds = _loadDeviceIds(); // reload future
            });
          }
        }
      }

      final List<String> updatedDeviceIds = await deviceIds;

      Map<String, dynamic> data = {
        'token': onUser,
        'devices': updatedDeviceIds,
      };

      SocketService.socket.emit('init', data);
    });
  }

  Future<List<String>> _loadDeviceIds() async {
    return await BaseStorage.getStorageFactory().getDeviceList();
  }

  @override
  void dispose() {
    SocketService.socket.off('error');
    super.dispose();
  }

  void _deleteDevice(String deviceId) async {
    final token = await BaseStorage.getStorageFactory().getToken();

    String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;
    url += '${Server.USER_REST_URL}/devices/$deviceId';
    var res = await http.delete(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      var deviceIds = await BaseStorage.getStorageFactory().getDeviceList();
      deviceIds.remove(deviceId);
      BaseStorage.getStorageFactory().saveData('device_ids', deviceIds);
      setState(() {
        this.deviceIds = _loadDeviceIds();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete device.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _deleteSelectedDevices() async {
    if (_selectedDeviceIds.isEmpty) return;

    // Confirm deletion
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Devices'),
        content: Text('Are you sure you want to delete ${_selectedDeviceIds.length} device(s)?'),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      for (var deviceId in _selectedDeviceIds) {
        _deleteDevice(deviceId);
      }
      setState(() {
        _selectedDeviceIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: TopBar.buildTopBar(title: 'Devices', context: context),
      // Wrap body in ScaffoldMessenger to control where SnackBar appears
      body: ScaffoldMessenger(
        child: Builder(
          builder: (context) => Column(
            children: [
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: deviceIds,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No devices found.',
                              style: TextStyle(
                                fontSize: screenHeight * 0.025,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      var deviceIds = snapshot.data!;
                      return ListView.builder(
                        itemCount: deviceIds.length,
                        itemBuilder: (context, index) {
                          var deviceId = deviceIds[index];
                          bool isSelected = _selectedDeviceIds.contains(deviceId);
                          return Padding(
                            padding: EdgeInsets.all(screenWidth * 0.02),
                            child: Card(
                              color: isSelected ? Colors.grey[300] : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              child: ListTile(
                                contentPadding:
                                EdgeInsets.all(screenWidth * 0.04),
                                leading: Icon(
                                  Icons.devices,
                                  color:
                                  isSelected ? Colors.red : const Color(0xFF4e54c8),
                                ),
                                title: Text(
                                  'Device ID: $deviceId',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenHeight * 0.02,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.deepPurpleAccent,
                                ),
                                onTap: () {
                                  if (_selectedDeviceIds.isNotEmpty) {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedDeviceIds.remove(deviceId);
                                      } else {
                                        _selectedDeviceIds.add(deviceId);
                                      }
                                    });
                                  } else {
                                    context.go('${Routes.DEVICE}/$deviceId');
                                  }
                                },
                                onLongPress: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedDeviceIds.remove(deviceId);
                                    } else {
                                      _selectedDeviceIds.add(deviceId);
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.08),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: screenHeight * 0.08,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.add_a_photo, size: 30, color: Colors.deepPurpleAccent),
              onPressed: () {
                context.go(Routes.DISEASE_CHECK);
              },
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 30, color: Colors.deepPurpleAccent),
              onPressed: () {
                _showAddDeviceDialog(context);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                size: 30,
                color: _selectedDeviceIds.isNotEmpty ? Colors.red : Colors.grey,
              ),
              onPressed: _selectedDeviceIds.isNotEmpty
                  ? _deleteSelectedDevices
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    final TextEditingController deviceIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Add Device', style: TextStyle(fontSize: 18)),
          content: TextField(
            controller: deviceIdController,
            decoration: const InputDecoration(
              hintText: 'Enter device ID',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newDeviceId = deviceIdController.text.trim();
                if (newDeviceId.isNotEmpty) {
                  if (newDeviceId.length != 24) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Device ID must be 24 characters long.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  token.then((onValue) {

                    String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;
                    url += '${Server.USER_REST_URL}/';
                    var res = http.patch(
                      Uri.parse(url),
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                        'Authorization': 'Bearer $onValue',
                      },
                      body: jsonEncode(<String, String>{
                        'device_id': newDeviceId,
                      }),
                    );
                    res.then((response) {
                      if (response.statusCode == 201) {
                        var deviceIds = BaseStorage.getStorageFactory().getDeviceList();
                        deviceIds.then((onDevice) {
                          for (var device in onDevice) {
                            if (device == newDeviceId) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Device already exists.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                          }
                          onDevice.add(newDeviceId);
                          BaseStorage.getStorageFactory().saveData('device_ids', onDevice);
                          setState(() {
                            this.deviceIds = _loadDeviceIds();
                          });
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device added successfully.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to add device.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    });
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid device ID.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
                context.pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
