import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/components/charts.dart';
import '../../util/constants.dart';
import 'date_filter_picker_test.dart';


void main(){
  testWidgets("Charts Component", (WidgetTester tester) async {
    final mockContext = MockBuildContext();
    final chartData = {
      'labels': ['Jan', 'Feb', 'Mar'],
      'datasets': [
        {
          'label': 'Water Usage',
          'data': [10, 20, 30],
          'backgroundColor': ['#FF6384', '#36A2EB', '#FFCE56'],
        },
      ],
    };

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