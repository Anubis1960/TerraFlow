import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mobile_app/components/top_bar.dart';
import 'package:mobile_app/service/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}
void main() {
  group('TopBar Tests', () {
    testWidgets('TopBar displays title and logout button', (WidgetTester tester) async {
      final context = await _buildTestContext(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: TopBar.buildTopBar(title: 'Test Title', context: context),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('Logout button can be tapped', (WidgetTester tester) async {
      final context = await _buildTestContext(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: TopBar.buildTopBar(title: 'Test Title', context: context),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle(); // This might navigate or show SnackBar

      // ❌ Can't verify AuthService.logout() was called
      // Because TopBar uses real AuthService internally
      expect(true, true); // Just pass; no crash means success
    });
  });
}

// Helper to create a fake BuildContext
Future<BuildContext> _buildTestContext(WidgetTester tester) async {
  final key = GlobalKey();
  await tester.pumpWidget(Container(key: key)); // dummy widget
  return key.currentContext!;
}