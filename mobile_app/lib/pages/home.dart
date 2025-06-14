import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/entity/device.dart';
import 'package:mobile_app/service/socket_service.dart';
import 'package:mobile_app/util/storage/base_storage.dart';
import 'package:mobile_app/components/top_bar.dart';
import 'package:mobile_app/util/constants.dart';

/// The home screen that displays a list of devices and allows management actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<String> token;
  late Future<List<Device>> devices;
  final Set<Device> _selectedDeviceIds = {};

  @override
  void initState() {
    super.initState();
    token = BaseStorage.getStorageFactory().getToken();
    devices = _loadDevices();

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
      final List<Device> onDevice = await devices;

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
          List<dynamic> responseBody = jsonDecode(res.body);

          print('Response Body: $responseBody');

          List<Device> deviceObjects = responseBody.map((item) {
            return Device(
              id: item['id'] ?? '',
              name: item['name'] ?? '',
            );
          }).toList();

          await BaseStorage.getStorageFactory().saveDevices(deviceObjects);

          setState(() {
            devices = _loadDevices();
          });
        }
      }

      final List<Device> updatedDevices = await devices;

      Map<String, dynamic> data = {
        'token': onUser,
        'devices': updatedDevices.map((device) => device.id).toList(),
      };

      SocketService.socket.emit('init', data);
    });
  }

  /// Loads the list of devices from storage.
  Future<List<Device>> _loadDevices() async {
    return await BaseStorage.getStorageFactory().getDevices();
  }

  @override
  void dispose() {
    SocketService.socket.off('error');
    super.dispose();
  }

  /// Deletes a device from the server and updates the storage.
  /// @param device The device to delete.
  void _deleteDevice(Device device) async {
    final token = await BaseStorage.getStorageFactory().getToken();

    String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;
    url += '${Server.USER_REST_URL}/devices/${device.id}';
    var res = await http.delete(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      var storedDevices = await BaseStorage.getStorageFactory().getDevices();

      // Remove by ID instead of by object reference
      storedDevices.removeWhere((d) => d.id == device.id);

      await BaseStorage.getStorageFactory().saveDevices(storedDevices);

      setState(() {
        this.devices = _loadDevices(); // Refresh UI
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

  /// Deletes selected devices after confirmation.
  /// Prompts the user for confirmation before proceeding with deletion.
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
      for (Device device in _selectedDeviceIds) {
        _deleteDevice(device);
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
      body: ScaffoldMessenger(
        child: Builder(
          builder: (context) => Column(
            children: [
              Expanded(
                child: FutureBuilder<List<Device>>(
                  future: devices,
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
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      var devicesList = snapshot.data!;
                      return ListView.builder(
                        itemCount: devicesList.length,
                        itemBuilder: (context, index) {
                          Device device = devicesList[index];
                          bool isSelected = _selectedDeviceIds.contains(device);
                          return Padding(
                            padding: EdgeInsets.all(screenWidth * 0.02),
                            child: Card(
                              color: isSelected ? Colors.grey[300] : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              child: ListTile(
                                contentPadding: EdgeInsets.all(screenWidth * 0.04),
                                leading: Icon(
                                  Icons.devices,
                                  color: isSelected
                                      ? Colors.red
                                      : Colors.blueGrey.shade600,
                                ),
                                title: Text(
                                  'Name: ${device.name}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenHeight * 0.02,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.blueGrey.shade600,
                                ),
                                onTap: () {
                                  if (_selectedDeviceIds.isNotEmpty) {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedDeviceIds.remove(device);
                                      } else {
                                        _selectedDeviceIds.add(device);
                                      }
                                    });
                                  } else {
                                    context.go('${Routes.DEVICE}/${device.id}');
                                  }
                                },
                                onLongPress: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedDeviceIds.remove(device);
                                    } else {
                                      _selectedDeviceIds.add(device);
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
              SizedBox(height: screenHeight * 0.06),
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
              icon: const Icon(Icons.add_a_photo, size: 30, color: Colors.blueGrey),
              onPressed: () {
                context.go(Routes.DISEASE_CHECK);
              },
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 30, color: Colors.blueGrey),
              onPressed: () {
                _showAddDeviceDialog(context);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                size: 30,
                color: _selectedDeviceIds.isNotEmpty && _selectedDeviceIds.length == 1
                    ? Colors.blueGrey.shade600
                    : Colors.grey.shade400,
              ),
              onPressed: _selectedDeviceIds.isNotEmpty && _selectedDeviceIds.length == 1
                  ? () => _editDeviceName(context, _selectedDeviceIds.first)
                  : null,
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                size: 30,
                color: _selectedDeviceIds.isNotEmpty ? Colors.red : Colors.grey.shade400,
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

  /// Opens a dialog to edit the name of a device.
  /// @param context The build context.
  /// @param device The device to edit.
  /// @returns A future that resolves when the dialog is closed.
  void _editDeviceName(BuildContext context, Device device) async {
    final TextEditingController nameController = TextEditingController(text: device.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Device Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(nameController.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName != device.name) {
      try {
        final token = await BaseStorage.getStorageFactory().getToken();
        String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;
        url += '${Server.DEVICE_REST_URL}/${device.id}';

        var res = await http.patch(
          Uri.parse(url),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'name': newName}),
        );

        if (res.statusCode == 200) {
          // Update local storage
          List<Device> storedDevices = await BaseStorage.getStorageFactory().getDevices();
          final index = storedDevices.indexWhere((d) => d.id == device.id);
          if (index != -1) {
            storedDevices[index] = Device(id: device.id, name: newName);
            await BaseStorage.getStorageFactory().saveDevices(storedDevices);
          }

          setState(() {
            devices = _loadDevices(); // Refresh UI
            _selectedDeviceIds.clear(); // Clear selection after edit
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device name updated successfully.'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update device name.'), backgroundColor: Colors.redAccent),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  /// Shows a dialog to add a new device.
  /// @param context The build context.
  /// @return A future that resolves when the dialog is closed.
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
              onPressed: () async {
                final newDeviceId = deviceIdController.text.trim();
                if (newDeviceId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid device ID.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                if (newDeviceId.length != 24) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Device ID must be 24 characters long.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                // Close dialog immediately
                Navigator.of(context).pop();

                // Use a local variable to capture scaffold messenger early
                final messenger = ScaffoldMessenger.of(context);

                try {
                  final onValue = await token;

                  String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;
                  url += '${Server.USER_REST_URL}/';

                  var res = await http.patch(
                    Uri.parse(url),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                      'Authorization': 'Bearer $onValue',
                    },
                    body: jsonEncode(<String, String>{
                      'device_id': newDeviceId,
                    }),
                  );

                  if (res.statusCode == 201) {
                    var responseBody = jsonDecode(res.body);
                    Device newDevice = Device(
                      id: responseBody['id'],
                      name: responseBody['name'],
                    );

                    List<Device> devices = await BaseStorage.getStorageFactory().getDevices();

                    for (var device in devices) {
                      if (device.id == newDevice.id) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Device already exists.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                    }

                    print('Adding new device: ${newDevice.toMap()}');
                    devices.add(newDevice);
                    await BaseStorage.getStorageFactory().addDevice(newDevice);

                    setState(() {
                      this.devices = _loadDevices();
                    });

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Device added successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add device.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
