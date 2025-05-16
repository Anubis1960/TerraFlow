import 'package:flutter/material.dart';

class DateFilterPicker extends StatelessWidget {
  final String filterType;
  final String selectedFilterValue;
  final Set<String> filteredValues;
  final Function(String?) onFilterTypeChanged;
  final VoidCallback onDatePick;
  final Function(String?) onFilterValueChanged;

  const DateFilterPicker({
    super.key,
    required this.filterType,
    required this.selectedFilterValue,
    required this.filteredValues,
    required this.onFilterTypeChanged,
    required this.onDatePick,
    required this.onFilterValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            value: filterType,
            onChanged: onFilterTypeChanged,
            items: ['day', 'month', 'year'].map((value) => DropdownMenuItem(
              value: value,
              child: Center(child: Text(value, textAlign: TextAlign.center)),
            )).toList(),
            isExpanded: true,
            style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
            dropdownColor: Colors.white,
            icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
          ),
        ),
        const SizedBox(width: 10),
        if (filterType == 'day')
          Expanded(
            child: TextButton.icon(
              onPressed: onDatePick,
              icon: Icon(Icons.calendar_today, size: 16),
              label: Text(
                selectedFilterValue.isEmpty ? "Select Date" : selectedFilterValue,
                style: TextStyle(color: Colors.black),
              ),
            ),
          )
        else
          Expanded(
            child: DropdownButton<String>(
              value: filteredValues.contains(selectedFilterValue)
                  ? selectedFilterValue
                  : filteredValues.isNotEmpty ? filteredValues.first : '',
              onChanged: onFilterValueChanged,
              items: filteredValues.isNotEmpty
                  ? filteredValues.map((value) => DropdownMenuItem<String>(
                value: value,
                child: Center(child: Text(value, textAlign: TextAlign.center)),
              )).toList()
                  : [],
              isExpanded: true,
              style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurpleAccent),
            ),
          ),
      ],
    );
  }
}