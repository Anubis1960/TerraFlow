import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../util/SocketService.dart';
import '../util/SharedPreferencesStorage.dart';
import 'home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void initState() {
    if (kDebugMode) {
      print('initState');
    }
    super.initState();

    SocketService.socket.on('register', (data) {
      if (kDebugMode) {
        print('Received register response: $data');
      }
      if (data['user_id'] != null && data['user_id'].isNotEmpty) {
        SharedPreferencesStorage.saveUserId(data['user_id']);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      } else {
        if (data['error'] != null && data['error'].isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error']),
            ),
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid email or password.'),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    SocketService.socket.off('register');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 16.0),
            TextField(
              controller: email,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                if (email.text.isEmpty || password.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields.'),
                    ),
                  );
                  return;
                }
                Map<String, String> registerJson = {
                  'email': email.text,
                  'password': password.text,
                };
                SocketService.socket.emit('register', registerJson);
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}