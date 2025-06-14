import 'dart:ui';

import 'package:flutter/material.dart';

/// A widget that displays a summary card with a title, value, and unit.
class SummaryCardWidget extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final Color color; // This will be used for the dot indicator
  final double screenWidth;
  final double screenHeight;

  const SummaryCardWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
    required this.screenWidth,
    required this.screenHeight,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.02),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color, // Dynamic color passed in
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenHeight * 0.018,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade800, // Matches app-wide theme
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
              FittedBox(
                child: Text(
                  '${value.toStringAsFixed(2)} $unit',
                  style: TextStyle(
                    fontSize: screenHeight * 0.026,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}