import 'package:flutter/material.dart';
import '../util/SocketService.dart';
import '../util/SharedPreferencesStorage.dart';
import 'home.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('Register Page init');
    SocketService.socket.on('register_response', (data) {
      if (data['user_id'] != null && data['user_id'].isNotEmpty) {
        SharedPreferencesStorage.saveUserId(data['user_id']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error_msg'] ?? 'Invalid email or password.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    print('Register Page Disposed');
    emailController.dispose();
    passwordController.dispose();
    SocketService.socket.off('register_response');
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
                    onPressed: () {
                      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                      Map<String, String> registerJson = {
                        'email': emailController.text,
                        'password': passwordController.text,
                      };
                      SocketService.socket.emit('register', registerJson);
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
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
