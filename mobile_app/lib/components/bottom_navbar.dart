
import 'package:flutter/material.dart';
import 'package:mobile_app/components/irrigation_type_dialog.dart';
import 'package:mobile_app/service/socket_service.dart';

/// A widget that builds a bottom navigation bar with buttons for irrigation control and data export.
class BottomNavBar {

  /// Builds the bottom navigation bar with buttons for triggering irrigation, scheduling irrigation, and exporting data.
  /// @param context The BuildContext for the widget tree.
  /// @param deviceId The ID of the device for which the irrigation and export actions will be performed.
  /// @return A [Container] widget containing the navigation buttons.
  static Widget buildBottomNavBar({
    required BuildContext context,
    required String deviceId,
    double height = 60.0,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () {
              SocketService.socket.emit('trigger_irrigation', {
                'device_id': deviceId,
              });
            },
            icon: Icon(Icons.water_drop, color: Colors.blueGrey, size: 30),
            tooltip: 'Trigger Irrigation',
          ),
          IconButton(
            onPressed: () {
              IrrigationTypeDialog.showIrrigationTypeDialog(
                  context: context, deviceId: deviceId);
            },
            icon: Icon(Icons.settings, color: Colors.blueGrey, size: 30),
            tooltip: 'Irrigation Settings',
          ),
          IconButton(
            onPressed: () {
              SocketService.socket.emit('export', {
                'device_id': deviceId,
              });
            },
            icon: Icon(Icons.cloud_download, color: Colors.green, size: 30),
            tooltip: 'Export Excel',
          ),
        ],
      ),
    );
  }
}