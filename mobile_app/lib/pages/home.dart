import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/util/SocketService.dart';
import '../util/SharedPreferencesStorage.dart';
import 'controller_dashboard.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<String> userId;
  late Future<List<String>> controllerIds;

  @override
  void initState() {
    if (kDebugMode) {
      print('initState');
    }
    super.initState();
    userId = SharedPreferencesStorage.getUserId();
    controllerIds = SharedPreferencesStorage.getControllerList();

    SocketService.socket.on('error', (data) {
      if (kDebugMode) {
        print('Received error response: $data');
      }
      if (data['error_msg'] != null && data['error_msg'].isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error_msg']),
          ),
        );
      }
    });

    SocketService.socket.on('controllers', (data) {
      if (kDebugMode) {
        print('Received controllers response: $data');
      }
      SharedPreferencesStorage.saveControllerList(data['controllers']);
      setState(() {
        controllerIds = SharedPreferencesStorage.getControllerList();
      });
    });

    userId.then((onUser) {
      controllerIds.then((onController) {
        if (kDebugMode) {
          print('User ID: $onUser');
          print('Controller IDs: $onController');
        }
        Map<String, dynamic> data = {
          'user_id': onUser,
          'controllers': onController,
        };
        SocketService.socket.emit('init', data);
      });
    });
  }

  @override
  void dispose() {
    SocketService.socket.off('error');
    SocketService.socket.off('controllers');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('controllers'),
      ),
      body: FutureBuilder<List<String>>(
        future: controllerIds,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No controllers found.'),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FloatingActionButton(
                    onPressed: () {
                      // Open the add controller pop-up
                      _showAddControllerDialog(context);
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            );
          } else {
            var controllerIds = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: controllerIds.length,
                    itemBuilder: (context, index) {
                      final controllerId = controllerIds[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 4,
                          child: ListTile(
                            title: Text('Controller ID: $controllerId'),
                            onTap: () {
                              // Navigate to the dynamic page for this controllerId
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ControllerDashBoard(controllerId: controllerId),
                                ),
                              );
                            },
                            onLongPress: () {
                              // Show a confirmation dialog before deleting the controller ID
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Delete Controller'),
                                    content: Text('Are you sure you want to delete controller ID: $controllerId?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context); // Close the dialog
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // Remove the controller ID
                                          userId.then((onValue) {
                                            Map<String, dynamic> data = {
                                              'controller_id': controllerId,
                                              'user_id': onValue,
                                            };
                                            SocketService.socket.emit('remove_controller', data);
                                          });

                                          // Update the controllerIds list after deletion
                                          setState(() {
                                            controllerIds.remove(controllerId);
                                          });

                                          Navigator.pop(context); // Close the dialog
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
                  padding: const EdgeInsets.all(16.0),
                  child: FloatingActionButton(
                    onPressed: () {
                      // Open the add controller pop-up
                      _showAddControllerDialog(context);
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  void _showAddControllerDialog(BuildContext context) {
    final TextEditingController controllerIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add controller'),
          content: TextField(
            controller: controllerIdController,
            decoration: const InputDecoration(
              hintText: 'Enter controller ID',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newControllerId = controllerIdController.text.trim();
                if (newControllerId.isNotEmpty) {
                  // Save the new controller ID and update the UI
                  userId.then((onValue) {
                    Map<String, dynamic> data = {
                      'controller_id': newControllerId,
                      'user_id': onValue,
                    };
                    SocketService.socket.emit('add_controller', data);
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid controller ID.'),
                    ),
                  );
                }
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}