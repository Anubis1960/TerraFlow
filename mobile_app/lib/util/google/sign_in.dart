import 'package:flutter/material.dart';
import 'sign_in_stud.dart'
  if (dart.library.html) 'web_sign_in.dart'
  if (dart.library.io) 'mobile_sign_in.dart';

/// A utility class for handling Google sign-in functionality across different platforms.
abstract class GoogleSignInUtil {

  /// Signs in the user using Google authentication.
  Future<void> signIn(BuildContext context);

  /// Signs out the user from the Google account.
  Future<void> signOut();

  /// Returns the appropriate Google sign-in implementation based on the platform.
  static GoogleSignInUtil getGoogleSignInFactory() => getGoogleSignIn();
}