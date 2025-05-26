import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/components/irrigation_type_dialog.dart';

void main() {
  group('IrrigationTypeDialog Tests', () {
    testWidgets('IrrigationTypeDialog displays title and dropdowns', (WidgetTester tester) async {
      // Wrap the dialog trigger inside a MaterialApp and Scaffold
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      IrrigationTypeDialog.showIrrigationTypeDialog(
                        context: context,
                        deviceId: 'test_device',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap the button to show the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle(); // Wait for dialog to appear

      // Now verify that dialog content appears
      expect(find.text('Select Irrigation Type'), findsOneWidget);
      expect(find.byType(DropdownMenu<String>), findsOneWidget);
    });
  });
}