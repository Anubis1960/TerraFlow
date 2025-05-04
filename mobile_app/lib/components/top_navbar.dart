import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/util/constants.dart';
import 'package:mobile_app/util/storage/base_storage.dart';
import 'package:mobile_app/util/google/sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class TopBar{

  static void _handle_logout(BuildContext context) async {
    try {
      final String token = await BaseStorage.getStorageFactory().getToken();
      final List<String> deviceIds = await BaseStorage.getStorageFactory().getDeviceList();

      String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;

      url += '/logout';

      await http.post(
        Uri.parse(url),
        headers: <String, String> {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, List<String>>{
          'device_ids': deviceIds,
        }),
      ).then((res) {
        if (res.statusCode == 200) {
          // Successfully logged out
          print('Logout successful');
        } else {
          // Handle error response
          print('Logout failed: ${res.body}');
        }
      });

      // Clear user data from SharedPreferences
      await BaseStorage.getStorageFactory().clearAllData();

      await GoogleSignInUtil.getGoogleSignInFactory().signOut();

      // Navigate to the login page
      context.go(Routes.LOGIN);
    } catch (e) {
      // Handle any errors that occur during the async operations
      print('Error during logout: $e');
    }
  }


  static PreferredSizeWidget buildTopBar({
    required String title,
    required BuildContext context,
  }){
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.deepPurpleAccent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: Colors.white), // Logout icon
          onPressed: () async {
            _handle_logout(context);
          },
        ),
      ],
    );
  }
}