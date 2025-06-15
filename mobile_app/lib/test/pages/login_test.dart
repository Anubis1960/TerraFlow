import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/pages/login.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('Renders all login UI components', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });
  });
}