import 'package:flutter/material.dart';
import 'package:mobile_app/util/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/util/storage/base_storage.dart';

class CallbackScreen extends StatelessWidget {
  final Map<String, String> queryParams;

  const CallbackScreen({Key? key, required this.queryParams}) : super(key: key);

  Future<void> saveToken(String token) async {
    await BaseStorage.getStorageFactory().saveToken(token);
  }

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