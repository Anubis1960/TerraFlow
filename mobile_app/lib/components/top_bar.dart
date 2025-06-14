
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/util/constants.dart';
import 'package:mobile_app/service/auth_service.dart';

class TopBar{

  /// Handles the logout process.
  /// @param context The BuildContext of the current widget.
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
      // Replace IconButton with your app icon as the leading widget
      leading: GestureDetector(
        onTap: () {
          context.go(Routes.HOME);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/no-bg.png', // Your app icon or logo
            width: 28,
            height: 28,
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.blueGrey,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            _handleLogout(context);
          },
        ),
      ],
    );
  }
}