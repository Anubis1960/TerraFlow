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
    super.initState();
    userId = SharedPreferencesStorage.getUserId();
    controllerIds = SharedPreferencesStorage.getControllerList();

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
      SharedPreferencesStorage.saveControllerList(data['controllers']);
      setState(() {
        controllerIds = SharedPreferencesStorage.getControllerList();
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
    SocketService.socket.off('error');
    SocketService.socket.off('controllers');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 8,
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text(
          'Controllers',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                controllerIds = SharedPreferencesStorage.getControllerList();
              });
            },
          )
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
                  const Text(
                    'No controllers found.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FloatingActionButton(
                      onPressed: () {
                        _showAddControllerDialog(context);
                      },
                      backgroundColor: Colors.deepPurpleAccent,
                      child: const Icon(Icons.add),
                    ),
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
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              'Controller ID: $controllerId',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.deepPurpleAccent,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
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
                  padding: const EdgeInsets.all(16.0),
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
