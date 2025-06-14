import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/pages/register.dart'; // Adjust import path accordingly


void main() {

  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: child,
    );
  }

  group('RegisterScreen UI Components', () {
    testWidgets('Verify all UI elements are displayed',
            (WidgetTester tester) async {
          await tester.pumpWidget(createTestableWidget(const RegisterScreen()));

          // Check if scaffold is there
          expect(find.byType(Scaffold), findsOneWidget);

          // Check title text
          expect(find.text('Create Account'), findsOneWidget);

          // Check subtitle text
          expect(find.text('Register to get started'), findsOneWidget);

          expect(find.text('Email'), findsNWidgets(1));

          // Check Password field
          expect(find.text('Password'), findsNWidgets(1));

          expect(find.text('Confirm Password'), findsNWidgets(1));

          // Check Register button
          expect(find.text('Register'), findsOneWidget);

          // Check OR Divider
          expect(find.text('OR'), findsOneWidget);
        });
  });
}