import 'package:flutter/material.dart';

/// A widget that provides a date filter picker with options for selecting a date or filtering by day, month, or year.
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Filter Type Selector
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blueGrey.shade400,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String>(
                value: filterType,
                onChanged: onFilterTypeChanged,
                items: ['day', 'month', 'year'].map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Center(
                      child: Text(
                        value.toUpperCase(),
                        style: TextStyle(
                          color: Colors.blueGrey.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                isExpanded: true,
                underline: const SizedBox.shrink(),
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.blueGrey.shade700,
                ),
                dropdownColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Date Picker or Value Selector
          Expanded(
            flex: 3,
            child: filterType == 'day'
                ? _buildDateButton(context)
                : _buildValueDropdown(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueGrey.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(
            color: Colors.blueGrey.shade400,
          ),
          textStyle: const TextStyle(fontSize: 16),
        ),
        onPressed: onDatePick,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(
              selectedFilterValue.isEmpty ? "Select Date" : selectedFilterValue,
              style: TextStyle(
                color: selectedFilterValue.isEmpty
                    ? Colors.grey
                    : Colors.blueGrey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueDropdown(BuildContext context) {
    final String displayValue = filteredValues.contains(selectedFilterValue)
        ? selectedFilterValue
        : filteredValues.isNotEmpty ? filteredValues.first : "No data";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blueGrey.shade400,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButton<String>(
        value: displayValue,
        onChanged: filteredValues.isNotEmpty ? onFilterValueChanged : null,
        items: filteredValues.isNotEmpty
            ? filteredValues.map((value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList()
            : [
          const DropdownMenuItem<String>(
            value: "No data",
            child: Center(
              child: Text(
                "No data",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        ],
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: filteredValues.isNotEmpty
              ? Colors.blueGrey
              : Colors.grey,
        ),
        dropdownColor: Colors.white,
      ),
    );
  }
}