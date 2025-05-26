import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/components/schedule_dialog.dart';
import '../../util/constants.dart';
import 'date_filter_picker_test.dart';

void main() {
  testWidgets("Schedule Dialog Component", (WidgetTester tester) async {
    // Create a simple widget that triggers the dialog
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    ScheduleDialog.showScheduleDialog(
                      context: context,
                      deviceId: 'test_device_id',
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Tap the button to show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle(); // Wait for dialog to appear

    // Verify that the dialog is displayed
    expect(find.text('Schedule Irrigation'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
    expect(find.text('Select Time'), findsOneWidget);
  });
}

