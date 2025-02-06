import 'package:flutter/material.dart';

class SummaryCard{
  static Widget buildSummaryCard({
    required String title,
    required double value,
    required Color color,
    required double screenWidth,
    required double screenHeight}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.02), // 2% of screen width
        child: Column(
          mainAxisSize: MainAxisSize.min, // Adapts to content height
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: screenHeight * 0.018, // 1.8% of screen height
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.008), // 0.8% of screen height
            FittedBox( // Ensures text scales properly
              child: Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: screenHeight * 0.022, // 2.2% of screen height
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}