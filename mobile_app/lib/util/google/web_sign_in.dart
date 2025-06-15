import 'package:flutter/cupertino.dart';
import 'dart:html' as html;
import 'sign_in.dart';
import 'package:mobile_app/util/constants.dart';

/// A class that handles Google sign-in for web applications.
class WebSignIn extends GoogleSignInUtil{

  /// The redirect URI for the Google sign-in process.
  final String redirectUri = Server.WEB_BASE_URL + Server.LOGIN_REST_URL;

  /// Initiates the Google sign-in process by redirecting the user to the Google authentication page.
  /// @param context The build context of the application.
  /// @return A [Future] that completes when the sign-in process is initiated.
  @override
  Future<void> signIn(BuildContext context) async {
    html.window.location.assign(redirectUri);
  }

  /// Signs out the user from the Google account.
  /// @return A [Future] that completes when the sign-out process is complete.
  @override
  Future<void> signOut() async{
    return;
  }
}

GoogleSignInUtil getGoogleSignIn() => WebSignIn();