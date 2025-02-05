import 'package:flutter/material.dart';
import 'package:mobile_app/util/socket_service.dart';
import '../util/storage/base_storage.dart';
import 'controller_dashboard.dart';
import 'login.dart';

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
    super.initState();
    print('Home Page init');
    userId = BaseStorage.getStorageFactory().getUserId();
    controllerIds = BaseStorage.getStorageFactory().getControllerList();

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

    SocketService.socket.on('controllers', (data) {
      BaseStorage.getStorageFactory().saveData('controller_ids', data['controllers']);
      setState(() {
        controllerIds = BaseStorage.getStorageFactory().getControllerList();
      });
    });

    userId.then((onUser) {
      controllerIds.then((onController) {
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
    print('Home Disposed');
    SocketService.socket.off('error');
    SocketService.socket.off('controllers');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Controllers',
          style: TextStyle(
            fontSize: screenHeight * 0.03, // 3% of screen height
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white), // Logout icon
            onPressed: () async {
              try {
                // Fetch user ID and controller IDs asynchronously
                final String userId = await BaseStorage.getStorageFactory().getUserId();
                final List<String> controllerIds = await BaseStorage.getStorageFactory().getControllerList();

                // Emit logout event via SocketService
                SocketService.socket.emit('logout', {
                  'user_id': userId,
                  'controllers': controllerIds,
                });

                // Clear user data from SharedPreferences
                await BaseStorage.getStorageFactory().clearAllData();

                // Navigate to the login page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              } catch (e) {
                // Handle any errors that occur during the async operations
                print('Error during logout: $e');
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: controllerIds,
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
                    'No controllers found.',
                    style: TextStyle(
                      fontSize: screenHeight * 0.025, // 2.5% of screen height
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02), // 2% of screen height
                  FloatingActionButton(
                    onPressed: () {
                      _showAddControllerDialog(context);
                    },
                    backgroundColor: Colors.deepPurpleAccent,
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
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
                        padding: EdgeInsets.all(screenWidth * 0.02), // 2% of screen width
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(screenWidth * 0.04), // 4% of screen width
                            title: Text(
                              'Controller ID: $controllerId',
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
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ControllerDashBoard(controllerId: controllerId),
                                ),
                              );
                            },
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Delete Controller'),
                                    content: Text('Are you sure you want to delete controller ID: $controllerId?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          userId.then((onValue) {
                                            Map<String, dynamic> data = {
                                              'controller_id': controllerId,
                                              'user_id': onValue,
                                            };
                                            SocketService.socket.emit('remove_controller', data);
                                          });

                                          setState(() {
                                            controllerIds.remove(controllerId);
                                          });

                                          Navigator.pop(context);
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
                      _showAddControllerDialog(context);
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

  void _showAddControllerDialog(BuildContext context) {
    final TextEditingController controllerIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Add Controller', style: TextStyle(fontSize: 18)),
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
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newControllerId = controllerIdController.text.trim();
                if (newControllerId.isNotEmpty) {
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
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
