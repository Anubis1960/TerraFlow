import 'package:flutter/material.dart';

class SummaryCardWidget extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final double screenWidth;
  final double screenHeight;

  const SummaryCardWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
    required this.screenWidth,
    required this.screenHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
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
            FittedBox(
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