import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/pages/disease_check.dart';

void main() {
  group('DiseaseCheckScreen UI Tests', () {
    testWidgets('Renders all UI components correctly when no image is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiseaseCheckScreen(),
        ),
      );

      // Check for image selection card with placeholder icon
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);

      // Check instruction text
      expect(find.text('Tap to select an image from your gallery'), findsOneWidget);

      // Ensure loading indicator is NOT visible initially
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}