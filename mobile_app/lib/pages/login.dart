import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/util/storage/base_storage.dart';
import 'package:mobile_app/util/constants.dart';
import 'package:mobile_app/util/google/sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('Login Page init');
  }

  @override
  void dispose() {
    print('Login Page Disposed');
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  Future<void> _loginWithGoogle(BuildContext context) async {
    var googleSignIn = GoogleSignInUtil.getGoogleSignInFactory();
    await googleSignIn.signIn(context);
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

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
                const Icon(Icons.lock_outline, size: 100, color: Colors.blue),
                SizedBox(height: screenHeight * 0.02),
                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: screenHeight * 0.01),
                const Text(
                  'Login to continue',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: screenHeight * 0.03),
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
                SizedBox(height: screenHeight * 0.02),
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
                SizedBox(height: screenHeight * 0.03),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (emailController.text.isEmpty ||
                          passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                      Map<String, String> loginJson = {
                        'email': emailController.text,
                        'password': passwordController.text,
                      };

                      String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;

                      url += Server.LOGIN_REST_URL;

                      var res = await http.post(
                        Uri.parse(url),
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: jsonEncode(loginJson),
                      );

                      if (res.statusCode == 200) {
                        var data = jsonDecode(res.body);
                        BaseStorage.getStorageFactory().saveData('token', data['token']);
                        BaseStorage.getStorageFactory().saveData('controller_ids', data['controllers']);
                        context.go(Routes.HOME);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invalid email or password.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    child: const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // 🔹 Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      // White background like Google's button
                      foregroundColor: Colors.black,
                      // Text color
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors
                            .grey), // Add border
                      ),
                    ),
                    onPressed: () => _loginWithGoogle(context),
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      // Add a Google logo image in assets
                      height: 24,
                    ),
                    label: const Text(
                        'Sign in with Google', style: TextStyle(fontSize: 16)),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),
                TextButton(
                  onPressed: () {
                    context.go(Routes.REGISTER);
                  },
                  child: const Text('Don’t have an account? Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}