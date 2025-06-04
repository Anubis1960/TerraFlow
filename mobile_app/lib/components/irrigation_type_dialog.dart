import 'package:flutter/material.dart';

import '../service/socket_service.dart';

class IrrigationTypeDialog {
  static void showIrrigationTypeDialog({
    required BuildContext context,
    required String deviceId,
  }) {
    List<String> type = ['MANUAL', 'AUTOMATIC', 'SCHEDULED'];
    String selectedType = type[0];
    List<String> scheduleType = ['DAILY', 'WEEKLY', 'MONTHLY'];
    String selectedScheduleType = scheduleType[0];
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    int pumpDurationSeconds = 5;


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Center(
                child: Text('Select Irrigation Type', style: TextStyle(fontSize: 20)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // DropdownMenu for selecting irrigation type
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownMenu<String>(
                      label: const Text('Irrigation Type'),
                      initialSelection: selectedType,
                      onSelected: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedType = newValue;
                          });
                        }
                      },
                      menuStyle: const MenuStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.white),
                        elevation: WidgetStatePropertyAll(8), // optional
                        surfaceTintColor: WidgetStatePropertyAll(Colors.white), // for Material 3
                        shadowColor: WidgetStatePropertyAll(Colors.black26), // optional
                      ),
                      dropdownMenuEntries: type
                          .map((value) => DropdownMenuEntry<String>(
                        value: value,
                        label: _getDisplayText(value),
                      ))
                          .toList(),

                    ),
                  ),


                  // Show time picker only if "SCHEDULED" is selected
                  if (selectedType == 'SCHEDULED') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: DropdownMenu<String>(
                        label: const Text("Schedule type"),
                        initialSelection: selectedScheduleType,
                        onSelected: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedScheduleType = newValue;
                            });
                          }
                        },
                        menuStyle: const MenuStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.white),
                          elevation: WidgetStatePropertyAll(8), // optional
                          surfaceTintColor: WidgetStatePropertyAll(Colors.white), // for Material 3
                          shadowColor: WidgetStatePropertyAll(Colors.black26), // optional
                        ),
                        dropdownMenuEntries: scheduleType
                            .map((value) => DropdownMenuEntry<String>(
                          value: value,
                          label: _getDisplayText(value),
                        ))
                            .toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr, // Force LTR
                        onChanged: (value) {
                          int seconds = int.tryParse(value) ?? 5;
                          setState(() {
                            pumpDurationSeconds = seconds;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Duration (seconds)",
                          hintText: "Enter seconds",
                          border: OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                      ),
                    ),
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
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.deepPurple,
                                    textStyle: TextStyle(fontSize: 20),
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                    ),

                  ],
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: Navigator.of(context).pop,
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () {
                    if (selectedType == 'SCHEDULED' && selectedScheduleType.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a time for scheduled irrigation')),
                      );
                      return;
                    }

                    var schedule = {
                      'type': "",
                      'time': "",
                    };

                    if (selectedType == 'SCHEDULED') {
                      schedule['type'] = selectedScheduleType;
                      schedule['time'] = '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}';
                      schedule['duration'] = pumpDurationSeconds.toString();
                    }

                    SocketService.socket.emit('irrigation_type', {
                      'device_id': deviceId,
                      'irrigation_type': selectedType,
                      'schedule': schedule
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper to make display names nicer
  static String _getDisplayText(String type) {
    switch (type) {
      case 'MANUAL':
        return 'Manual';
      case 'AUTOMATIC':
        return 'Automatic';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'DAILY':
        return 'Daily';
      case 'WEEKLY':
        return 'Weekly';
      case 'MONTHLY':
        return 'Monthly';
      default:
        return type;
    }
  }
}