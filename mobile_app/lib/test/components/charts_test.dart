import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/components/charts.dart';


void main(){
  testWidgets("Charts Component", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Charts.buildLineChart(
            title: "Water Usage Over Time", data: [], lineColors: [], minY: -30, maxY: 110, xAxisLabels: [], headers: [],
          ),
        ),
      ),
    );

    expect(find.text("Water Usage Over Time"), findsOneWidget);
  });
}