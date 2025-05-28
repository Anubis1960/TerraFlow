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

          final iconFinder = find.descendant(
            of: find.byWidgetPredicate((widget) =>
            widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle),
            matching: find.byIcon(Icons.person_add),
          );

          expect(iconFinder, findsOneWidget);

          // Check title text
          expect(find.text('Create Account'), findsOneWidget);

          // Check subtitle text
          expect(find.text('Register to get started'), findsOneWidget);

          // Check Email field with label
          expect(find.widgetWithText(TextField, 'Enter your email'), findsOneWidget);
          expect(find.text('Email'), findsNWidgets(1));

          // Check Password field
          expect(
              find.widgetWithText(TextField, 'Enter your password'), findsOneWidget);
          expect(find.text('Password'), findsNWidgets(1));

          // Check Confirm Password field
          expect(find.widgetWithText(TextField, 'Confirm your password'),
              findsOneWidget);
          expect(find.text('Confirm Password'), findsNWidgets(1));

          // Check Register button
          expect(find.text('Register'), findsOneWidget);

          // Check OR Divider
          expect(find.text('OR'), findsOneWidget);

          // Check Back to Login button
          expect(find.text('Back to Login'), findsOneWidget);
        });
  });
}