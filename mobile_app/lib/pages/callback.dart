import 'package:flutter/material.dart';
import 'package:mobile_app/util/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/util/storage/base_storage.dart';


/// CallbackScreen is used to handle the callback from the authentication provider.
class CallbackScreen extends StatelessWidget {
  final Map<String, String> queryParams;

  const CallbackScreen({Key? key, required this.queryParams}) : super(key: key);

  /// Saves the token to the storage.
  /// @param token The authentication token to be saved.
  /// @return A [Future] that completes when the token is saved.
  Future<void> saveToken(String token) async {
    await BaseStorage.getStorageFactory().saveToken(token);
  }

  /// Builds the widget tree for the CallbackScreen.
  @override
  Widget build(BuildContext context) {
    if (queryParams.containsKey("token")) {
      String token = queryParams["token"]!;
      saveToken(token);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(Routes.HOME); // Redirect to home after saving the token
      });
    }
    else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(Routes.LOGIN); // Redirect to login if no token is found
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text("Callback Screen")),
      body: Center(
        child: Text("Query Params: ${queryParams.toString()}"),
      ),
    );
  }

}