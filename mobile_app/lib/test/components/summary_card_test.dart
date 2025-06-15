import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/components/summary_card.dart';


void main() {
  group('SummaryCardWidget Tests', () {
    testWidgets('SummaryCardWidget displays title, value, and color', (WidgetTester tester) async {
      final screenWidth = 400.0;
      final screenHeight = 800.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCardWidget(
              title: 'Test Title',
              value: 123.45,
              unit: 'units',
              color: Colors.blue,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('123.45 units'), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);
    });
  });
}