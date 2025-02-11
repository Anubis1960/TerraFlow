import 'package:flutter/material.dart';
import 'sign_in_stud.dart'
  if (dart.library.html) 'web_sign_in.dart'
  if (dart.library.io) 'mobile_sign_in.dart';

abstract class GoogleSignInUtil {
  Future<void> signIn(BuildContext context);
  Future<void> signOut();

  static GoogleSignInUtil getGoogleSignInFactory() => getGoogleSignIn();
}