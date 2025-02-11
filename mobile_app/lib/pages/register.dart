import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/util/storage/base_storage.dart';
import 'package:mobile_app/util/constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('Register Page init');
  }

  @override
  void dispose() {
    print('Register Page Disposed');
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08, // 8% of screen width
              vertical: screenHeight * 0.02, // 2% of screen height
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add,
                  size: screenHeight * 0.12, // 12% of screen height
                  color: Colors.blue,
                ),
                SizedBox(height: screenHeight * 0.02), // 2% of screen height
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: screenHeight * 0.03, // 3% of screen height
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01), // 1% of screen height
                Text(
                  'Register to get started',
                  style: TextStyle(
                    fontSize: screenHeight * 0.018, // 1.8% of screen height
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03), // 3% of screen height
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02), // 2% of screen height
                TextField(
                  obscureText: true,
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02), // 2% of screen height
                TextField(
                  obscureText: true,
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03), // 3% of screen height
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02, // 2% of screen height
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (emailController.text.isEmpty || passwordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      if (passwordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      Map<String, String> registerJson = {
                        'email': emailController.text,
                        'password': passwordController.text,
                      };

                      String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;

                      url += Server.REGISTER_REST_URL;

                      var res = await http.post(
                        Uri.parse(url),
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: jsonEncode(registerJson),
                      );

                      if (res.statusCode == 200) {
                        var data = jsonDecode(res.body);
                        if (data['token'] != null && data['token'].isNotEmpty) {
                          BaseStorage.getStorageFactory().saveData('token', data['token']);
                          context.go(Routes.HOME);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(data['error_msg'] ?? 'Invalid email or password.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to register.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Register',
                      style: TextStyle(
                        fontSize: screenHeight * 0.02, // 2% of screen height
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02), // 2% of screen height
                TextButton(
                  onPressed: () {
                    context.go(Routes.LOGIN);
                  },
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: screenHeight * 0.018, // 1.8% of screen height
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
