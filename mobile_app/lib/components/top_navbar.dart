import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/util/constants.dart';
import 'package:mobile_app/util/socket_service.dart';
import 'package:mobile_app/util/storage/base_storage.dart';
import 'package:mobile_app/util/google/sign_in.dart';

class TopBar{
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
            try {
              // Fetch user ID and controller IDs asynchronously
              final String token = await BaseStorage.getStorageFactory().getToken();
              final List<String> controllerIds = await BaseStorage.getStorageFactory().getControllerList();

              // Emit logout event via SocketService
              SocketService.socket.emit('logout', {
                'token': token,
                'controllers': controllerIds,
              });

              // SocketService.socket.disconnect();

              // Clear user data from SharedPreferences
              await BaseStorage.getStorageFactory().clearAllData();

              await GoogleSignInUtil.getGoogleSignInFactory().signOut();


              // Navigate to the login page
              context.go(Routes.LOGIN);
            } catch (e) {
              // Handle any errors that occur during the async operations
              print('Error during logout: $e');
            }
          },
        ),
      ],
    );
  }
}