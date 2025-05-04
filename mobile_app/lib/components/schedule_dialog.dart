import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/util/socket_service.dart';

class ScheduleDialog{
  static void showScheduleDialog({
    required BuildContext context,
    required String deviceId,
  }) {
    List<String> type = ['DAILY', 'WEEKLY', 'MONTHLY'];
    String selectedType = type[0];

    TimeOfDay selectedTime = TimeOfDay(hour: 0, minute: 0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Center(
                  child: Text('Schedule Irrigation', style: TextStyle(fontSize: 20))
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedType,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedType = newValue!;
                      });
                    },
                    items: type.map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text('Select Time'),
                    trailing: Text(
                      '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    onTap: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedTime = pickedTime;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final formattedTime = '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}';
                    SocketService.socket.emit('schedule_irrigation', {
                      'device_id': deviceId,
                      'schedule_type': selectedType,
                      'schedule_time': formattedTime,
                    });
                    context.pop();
                  },
                  child: const Text('Add'),
                ),
                ElevatedButton(
                  onPressed: () {
                    SocketService.socket.emit('remove_schedule', {
                      'device_id': deviceId,
                    });
                    context.pop();
                  },
                  child: const Text('Remove'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}