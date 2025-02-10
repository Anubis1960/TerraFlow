import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

class LoginSc extends StatelessWidget {
  final String redirectUri = 'http://localhost:5000/login';

  const LoginSc({super.key});

  Future<void> _loginWithGoogle(BuildContext context) async {
    try {
      final result = await FlutterWebAuth.authenticate(
        url: 'http://localhost:5000/login',
        callbackUrlScheme: 'http',
      );

      print('Login result: $result');
    } catch (e) {
      print('Error during login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _loginWithGoogle(context),
          child: Text('Login with Google'),
        ),
      ),
    );
  }
}

