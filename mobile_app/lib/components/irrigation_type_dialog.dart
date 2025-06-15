import 'package:flutter/material.dart';

import '../service/socket_service.dart';

/// A dialog to select the type of irrigation and its settings.
class IrrigationTypeDialog {

  /// Shows a dialog for selecting the irrigation type and its settings.
  /// @param context The BuildContext for the dialog.
  /// @param deviceId The ID of the device for which the irrigation type is being set.
  /// @return [void]
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Center(
                child: Text(
                  'Select Irrigation Type',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown for irrigation type
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
                      menuStyle: MenuStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        elevation: WidgetStateProperty.all(8),
                        surfaceTintColor: WidgetStateProperty.all(Colors.white),
                        shadowColor: WidgetStateProperty.all(Colors.black26),
                      ),
                      dropdownMenuEntries: type
                          .map((value) => DropdownMenuEntry<String>(
                        value: value,
                        label: _getDisplayText(value),
                      ))
                          .toList(),
                    ),
                  ),

                  // Conditional fields for "SCHEDULED"
                  if (selectedType == 'SCHEDULED') ...[
                    // Schedule Type Dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: DropdownMenu<String>(
                        label: const Text("Schedule Type"),
                        initialSelection: selectedScheduleType,
                        onSelected: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedScheduleType = newValue;
                            });
                          }
                        },
                        menuStyle: MenuStyle(
                          backgroundColor: WidgetStateProperty.all(Colors.white),
                          elevation: WidgetStateProperty.all(8),
                          surfaceTintColor: WidgetStateProperty.all(Colors.white),
                          shadowColor: WidgetStateProperty.all(Colors.black26),
                        ),
                        dropdownMenuEntries: scheduleType
                            .map((value) => DropdownMenuEntry<String>(
                          value: value,
                          label: _getDisplayText(value),
                        ))
                            .toList(),
                      ),
                    ),

                    // Duration Input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          int seconds = int.tryParse(value) ?? 5;
                          setState(() {
                            pumpDurationSeconds = seconds;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Duration (seconds)",
                          hintText: "Enter seconds",
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueGrey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueGrey.shade400),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                      ),
                    ),

                    // Time Picker
                    ListTile(
                      title: const Text('Select Time'),
                      trailing: Text(
                        '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: Colors.blueGrey),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blueGrey,
                                    textStyle: const TextStyle(fontSize: 16),
                                    padding: EdgeInsets.all(12),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: Navigator.of(context).pop,
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    var schedule = <String, String>{};

                    if (selectedType == 'SCHEDULED' && selectedScheduleType.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a time for scheduled irrigation')),
                      );
                      return;
                    }

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


  /// Returns a display text for the irrigation type.
  /// @param type The type of irrigation.
  /// @return A [String] representing the display text for the irrigation type.
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