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
  late Future<List<String>> controllerIds;

  @override
  void initState() {
    super.initState();
    print('Home Page init');
    token = BaseStorage.getStorageFactory().getToken();
    controllerIds = _loadControllerIds();

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
        controllerIds = _loadControllerIds();
      });
    });

    token.then((onUser) {
      controllerIds.then((onController) {
        Map<String, dynamic> data = {
          'token': onUser,
          'controllers': onController,
        };
        SocketService.socket.emit('init', data);
      });
    });
  }

  void _deleteController(String controllerId) async {
    // TODO - FIX DELETE CONTROLLER
    final token = await BaseStorage.getStorageFactory().getToken();

    Map<String, dynamic> data = {
      'controller_id': controllerId,
      'token': token,
    };
    SocketService.socket.emit('remove_controller', data);

    setState(() {
      controllerIds = _loadControllerIds();
    });
  }


  Future<List<String>> _loadControllerIds() async {
    return await BaseStorage.getStorageFactory().getControllerList();
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
      appBar: TopBar.buildTopBar(title: 'Controllers', context: context),
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
                      var controllerId = controllerIds[index];
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
                              context.go('${Routes.CONTROLLER}/$controllerId');
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
                                          context.pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteController(controllerId);

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
                context.pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newControllerId = controllerIdController.text.trim();
                if (newControllerId.isNotEmpty) {
                  if (newControllerId.length != 24) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Controller ID must be 24 characters long.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  token.then((onValue) {
                    Map<String, dynamic> data = {
                      'controller_id': newControllerId,
                      'token': onValue,
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
