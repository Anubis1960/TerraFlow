
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/entity/device.dart';
import '../util/constants.dart';
import '../util/google/sign_in.dart';
import '../util/storage/base_storage.dart';

class AuthService{

  Future<bool> login(String email, String password) async {
    Map<String, String> loginJson = {
      'email': email,
      'password': password,
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
      BaseStorage.getStorageFactory().saveToken(data['token']);
      print(data);
      List<Device> devices = (data['devices'] as List)
          .map((device) => Device.fromMap(device))
          .toList();
      BaseStorage.getStorageFactory().saveDevices(devices);
      return true;
    } else {
      return false;
    }
  }


  Future<void> loginWithGoogle(BuildContext context) async {
    var googleSignIn = GoogleSignInUtil.getGoogleSignInFactory();
    await googleSignIn.signIn(context);
  }


  Future<bool> register(String email, String password) async {
    Map<String, String> registerJson = {
      'email': email,
      'password': password,
    };

    String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;

    url += Server.REGISTER_REST_URL;



    bool? res = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(registerJson),
    ).then((res) {
        if (res.statusCode == 200) {
          var data = jsonDecode(res.body);
          if (data['token'] != null && data['token'].isNotEmpty) {
            BaseStorage.getStorageFactory().saveToken(data['token']);
            return true;
          }
        }
        else {
          return false;
        }
      },
    ).catchError((error) {
      return false;
    }
    );
    return res != null && res == true;
  }


  Future<bool> logout() async {
    try {
      final String token = await BaseStorage.getStorageFactory().getToken();
      final List<Device> devices = await BaseStorage.getStorageFactory().getDevices();

      String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;

      List<String> deviceIds = devices.map((device) => device.id).toList();

      url += '/logout';

      await http.post(
        Uri.parse(url),
        headers: <String, String> {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, List<String>>{
          'deviceIds': deviceIds,
        }),
      ).then((res) {
        if (res.statusCode == 200) {
          // Successfully logged out
        } else {
          // Handle error response
        }
      });

      // Clear user data from SharedPreferences
      await BaseStorage.getStorageFactory().clearAllData();

      await GoogleSignInUtil.getGoogleSignInFactory().signOut();

      return true;
    } catch (e) {
      return false;
    }
  }
}