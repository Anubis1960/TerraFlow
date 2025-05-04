import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/util/socket_service.dart';
import 'package:mobile_app/util/storage/base_storage.dart';
import 'package:mobile_app/components/top_navbar.dart';
import 'package:mobile_app/util/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<String> token;
  late Future<List<String>> deviceIds;

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

    token.then((onUser) {
      deviceIds.then((onDevice) async {
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
                deviceIds = _loadDeviceIds();
              });
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to load devices.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
        Map<String, dynamic> data = {
          'token': onUser,
          'devices': BaseStorage.getStorageFactory().getDeviceList(),
        };
        SocketService.socket.emit('init', data);
      });

    });
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


  Future<List<String>> _loadDeviceIds() async {
    return await BaseStorage.getStorageFactory().getDeviceList();
  }

  @override
  void dispose() {
    SocketService.socket.off('error');
    // SocketService.socket.off('devices');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: TopBar.buildTopBar(title: 'Devices', context: context),
      body: FutureBuilder<List<String>>(
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
                      fontSize: screenHeight * 0.025, // 2.5% of screen height
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02), // 2% of screen height
                  FloatingActionButton(
                    onPressed: () {
                      _showAddDeviceDialog(context);
                    },
                    backgroundColor: Colors.deepPurpleAccent,
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            );
          } else {
            var deviceIds = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: deviceIds.length,
                    itemBuilder: (context, index) {
                      var deviceId = deviceIds[index];
                      return Padding(
                        padding: EdgeInsets.all(screenWidth * 0.02), // 2% of screen width
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(screenWidth * 0.04), // 4% of screen width
                            title: Text(
                              'Device ID: $deviceId',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: screenHeight * 0.02, // 2% of screen height
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.deepPurpleAccent,
                            ),
                            onTap: () {
                              context.go('${Routes.DEVICE}/$deviceId');
                            },
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Delete Device'),
                                    content: Text('Are you sure you want to delete device ID: $deviceId?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          context.pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteDevice(deviceId);

                                          context.pop();
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04), // 4% of screen width
                  child: FloatingActionButton(
                    onPressed: () {
                      _showAddDeviceDialog(context);
                    },
                    backgroundColor: Colors.deepPurpleAccent,
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          }
        },
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
            ElevatedButton(
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
