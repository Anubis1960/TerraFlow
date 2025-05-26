import 'dart:ui';

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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(),
            Colors.white.withValues(),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.01), // Increased padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: screenHeight * 0.018,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.008),
                FittedBox(
                  child: Text(
                    value.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: screenHeight * 0.024,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}