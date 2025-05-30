import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/components/bottom_navbar.dart';
import '../../util/constants.dart';
import 'date_filter_picker_test.dart';

void main() {
  testWidgets("Bottom Navbar Component", (WidgetTester tester) async {
    final mockContext = MockBuildContext();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomNavBar.buildBottomNavBar(context: mockContext, deviceId: 'test_device_id' )
        ),
      ),
    );

    // Verify Trigger Irrigation button
    expect(find.byIcon(Icons.water_drop), findsOneWidget);
    // Verify Settings button
    expect(find.byIcon(Icons.settings), findsOneWidget);
    // Verify Logout button
    expect(find.byIcon(Icons.cloud_download), findsOneWidget);
    // Verify the presence of the Floating Action Button
  });
}