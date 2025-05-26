
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/util/constants.dart';
import 'package:mobile_app/service/auth_service.dart';

class TopBar{

  static void _handleLogout(BuildContext context) async {
    var authService = AuthService();
    bool res = await authService.logout();
    if (res) {
      context.go(Routes.LOGIN);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed')),
      );
    }
  }


  static PreferredSizeWidget buildTopBar({
    required String title,
    required BuildContext context,
  }) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.home, color: Colors.white),
        onPressed: () {
          context.go(Routes.HOME);
        },
      ),
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
            _handleLogout(context);
          },
        ),
      ],
    );
  }
}