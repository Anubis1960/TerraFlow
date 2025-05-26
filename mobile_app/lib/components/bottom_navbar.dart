
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/components/irrigation_type_dialog.dart';
import 'package:mobile_app/util/constants.dart';
import 'package:mobile_app/service/socket_service.dart';

class BottomNavBar{
  static Widget buildBottomNavBar({
    required BuildContext context,
    required String deviceId,
}){
    return BottomAppBar(
      elevation: 0,
      color: Colors.white,
      shape: CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Home Button
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    // Navigate to Home Screen
                    context.go(Routes.HOME);
                  },
                  icon: Icon(Icons.home, color: Colors.deepPurpleAccent),
                  tooltip: 'Home',
                ),
                Flexible(
                  child: Text(
                    'Home',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 14, // Adjusted font size
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center, // Center the text
                  ),
                ),
              ],
            ),
          ),
          // Trigger Irrigation Button
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    SocketService.socket.emit('trigger_irrigation', {
                      'device_id': deviceId,
                    });
                  },
                  icon: Icon(Icons.water_drop, color: Colors.deepPurpleAccent),
                  tooltip: 'Trigger Irrigation',
                ),
                Flexible(
                  child: Text(
                    'Irrigate',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 14, // Adjusted font size
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Schedule Irrigation Button
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    IrrigationTypeDialog.showIrrigationTypeDialog(context: context, deviceId: deviceId);
                  },
                  icon: Icon(Icons.settings, color: Colors.deepPurpleAccent),
                  tooltip: 'Irrigation Settings',
                ),
                Flexible(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 14, // Adjusted font size
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Export Data Button
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    SocketService.socket.emit('export', {
                      'device_id': deviceId,
                    });
                  },
                  icon: Icon(Icons.cloud_download, color: Colors.green),
                  tooltip: 'Export Excel',
                ),
                Flexible(
                  child: Text(
                    'Export',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14, // Adjusted font size
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}