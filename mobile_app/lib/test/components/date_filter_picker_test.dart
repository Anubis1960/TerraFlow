import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mobile_app/components/date_filter_picker.dart';

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  testWidgets("Date Filter", (WidgetTester tester) async{
    final filterType = 'day';
    final selectedFilterValue = '2023-10-01';
    final filteredValues = {'2023-10-01', '2023-10-02'};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DateFilterPicker(
            filterType: filterType,
            selectedFilterValue: selectedFilterValue,
            filteredValues: filteredValues,
            onFilterTypeChanged: (value) {},
            onDatePick: () {},
            onFilterValueChanged: (value) {},
          ),
        ),
      ),
    );

    expect(find.text(selectedFilterValue), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today), findsOneWidget);
  });
}