import 'package:flutter/material.dart';
import 'package:mobile_app/pages/login.dart';
import 'util/storage/base_storage.dart';
import 'pages/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: BaseStorage.getStorageFactory().getUserId(),
        builder: (context, snapshot) {
          // Check if the future is still loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Check if the user ID is valid
          final userId = snapshot.data ?? '';
          if (userId.isNotEmpty) {
            return const Home();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}