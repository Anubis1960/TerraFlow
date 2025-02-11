import 'package:flutter/cupertino.dart';
import 'dart:html' as html;
import 'sign_in.dart';
import 'package:mobile_app/util/constants.dart';

class WebSignIn extends GoogleSignInUtil{
  final String redirectUri = Server.WEB_BASE_URL + Server.LOGIN_REST_URL;

  @override
  Future<void> signIn(BuildContext context) async {
    html.window.location.assign(redirectUri);
  }

  @override
  Future<void> signOut() async{
    return;
  }
}

GoogleSignInUtil getGoogleSignIn() => WebSignIn();