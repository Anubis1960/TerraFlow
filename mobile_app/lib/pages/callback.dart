import 'package:flutter/material.dart';

class CallbackScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(ModalRoute.of(context)!.settings.name!);
    final email = uri.queryParameters['email'];

    if (email != null) {
      print('User email: $email');
      // Navigate to home screen
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/'));
    } else {
      // Handle error
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
    }

    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}