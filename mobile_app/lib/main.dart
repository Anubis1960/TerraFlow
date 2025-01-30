import 'package:flutter/material.dart';
import 'package:mobile_app/pages/login.dart';
import './util/SharedPreferencesStorage.dart';
import 'pages/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SharedPreferencesStorage.getUserId().then((userId) {
      print('User ID: $userId');
      if (userId != '' && userId.isNotEmpty) {
        runApp(MaterialApp(
          title: 'Flutter Auth App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: const Home(),
        ));
      } else {
        runApp(MaterialApp(
          title: 'Flutter Auth App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: const LoginPage(),
        ));
      }
    });
    return MaterialApp(
      title: 'Flutter Auth App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}