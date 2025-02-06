
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/util/routes.dart';
import 'package:mobile_app/util/socket_service.dart';
import 'package:mobile_app/components/schedule_dialog.dart';

class BottomNavBar{
  static Widget buildBottomNavBar({
    required BuildContext context,
    required String controllerId,
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
                    context.go(RouteURLs.HOME);
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
                      'controller_id': controllerId,
                    });
                  },
                  icon: Icon(Icons.water_drop, color: Colors.deepPurpleAccent),
                  tooltip: 'Trigger Irrigation',
                ),
                Flexible(
                  child: Text(
                    'Irrigation',
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
                    ScheduleDialog.showScheduleDialog(context: context, controllerId: controllerId);
                  },
                  icon: Icon(Icons.schedule, color: Colors.deepPurpleAccent),
                  tooltip: 'Schedule Irrigation',
                ),
                Flexible(
                  child: Text(
                    'Schedule',
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
                      'controller_id': controllerId,
                    });
                  },
                  icon: Icon(Icons.cloud_download, color: Colors.green),
                  tooltip: 'Export Data',
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