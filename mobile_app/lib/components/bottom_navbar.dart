
import 'package:flutter/material.dart';
import 'package:mobile_app/components/irrigation_type_dialog.dart';
import 'package:mobile_app/service/socket_service.dart';

class BottomNavBar {
  static Widget buildBottomNavBar({
    required BuildContext context,
    required String deviceId,
  }) {
    return BottomAppBar(
      elevation: 0,
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
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
                  icon: Icon(Icons.water_drop, color: Colors.blueGrey),
                  tooltip: 'Trigger Irrigation',
                ),
                Flexible(
                  child: Text(
                    'Irrigate',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 14,
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
                    IrrigationTypeDialog.showIrrigationTypeDialog(
                        context: context, deviceId: deviceId);
                  },
                  icon: Icon(Icons.settings, color: Colors.blueGrey),
                  tooltip: 'Irrigation Settings',
                ),
                Flexible(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 14,
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
                      fontSize: 14,
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