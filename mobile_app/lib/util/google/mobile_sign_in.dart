import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile_app/util/google/sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/util/constants.dart';
import 'package:mobile_app/util/storage/base_storage.dart';

class MobileSignIn extends GoogleSignInUtil {
  static final _googleSignIn = GoogleSignIn();

  @override
  Future<void> signIn(BuildContext context) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        final String accessToken = auth.accessToken ?? '';

        var req = await http.post(
          Uri.parse(Server.MOBILE_BASE_URL + Server.LOGIN_REST_URL),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, String>{
            'email': account.email,
            'access_token': accessToken,
          }),
        );

        if (req.statusCode == 200) {
          String token = jsonDecode(req.body)['token'];
          BaseStorage.getStorageFactory().saveData('token', token);
          context.go(Routes.HOME);
        } else {
          print('Login failed: ${req.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${req.body}')),
          );
        }
      }
    } catch (e) {
      print('Error during login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

GoogleSignInUtil getGoogleSignIn() => MobileSignIn();
