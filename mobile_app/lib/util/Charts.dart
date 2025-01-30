import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class Charts {
  static Widget buildLineChart({
    required String title,
    required List<FlSpot> spots,
    required Color lineColor,
    required double minY,
    required double maxY,
    required List<String> xAxisLabels,
    bool isScrollable = false,
    Color backgroundColor = Colors.white,
    bool showGrid = false,
    double? maxX,
    ScrollController? scrollController,
  }) {
    double targetPosition = 0;

    // Check if a scroll controller is passed
    if (scrollController != null) {
      targetPosition = (maxX ?? (xAxisLabels.length - 1).toDouble()) * 40.0; // Adjust based on maxX
    }

    // Update the scroll position after the widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController != null && scrollController.hasClients) {
        // Smooth scroll to the target position (right end)
        scrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      double value = maxY - (maxY - minY) * (index / 4);
                      return Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: isScrollable
                      ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: scrollController,
                    child: SizedBox(
                      width: maxX != null ? maxX * 40.0 : xAxisLabels.length * 40.0,
                      child: _buildLineChartContent(
                        spots,
                        lineColor,
                        minY,
                        maxY,
                        xAxisLabels,
                        showGrid,
                        maxX: maxX,
                      ),
                    ),
                  )
                      : _buildLineChartContent(
                    spots,
                    lineColor,
                    minY,
                    maxY,
                    xAxisLabels,
                    showGrid,
                    maxX: maxX,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildLineChartContent(
      List<FlSpot> spots,
      Color lineColor,
      double minY,
      double maxY,
      List<String> xAxisLabels,
      bool showGrid, {
        double? maxX,
      }) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX ?? (xAxisLabels.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < xAxisLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      xAxisLabels[index],
                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.2),
            ),
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}


