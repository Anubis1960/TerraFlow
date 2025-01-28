import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class Charts {
  static Widget buildBarChart({
    required String title,
    required List<BarChartGroupData> barGroups,
    required List<String> xAxisLabels,
    Color barColor = Colors.blue,
    Color backgroundColor = Colors.white,
    bool showGrid = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
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
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(show: showGrid),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            index < xAxisLabels.length ? xAxisLabels[index] : '',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
                barGroups: barGroups,
                barTouchData: BarTouchData(enabled: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildLineChart({
    required String title,
    required List<FlSpot> spots,
    required Color lineColor,
    required double minY,
    required double maxY,
    required List<String> xAxisLabels,
    bool isScrollable = false,
    Color backgroundColor = Colors.white,
    bool showGrid = true,
    double? maxX, // Add maxX parameter
    ScrollController? scrollController, // Add scrollController parameter
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
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
            height: 300,
            child: isScrollable
                ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: scrollController, // Pass the scrollController
              child: SizedBox(
                width: maxX != null ? maxX * 10.0 : xAxisLabels.length * 10.0 + 40.0, // Adjust width based on maxX
                child: Padding(
                  padding: const EdgeInsets.only(right: 40.0), // Add padding to the right
                  child: _buildLineChartContent(
                    spots,
                    lineColor,
                    minY,
                    maxY,
                    xAxisLabels,
                    showGrid,
                    maxX: maxX, // Pass maxX to the chart content
                  ),
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
              maxX: maxX, // Pass maxX to the chart content
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
      bool showGrid,
      {double? maxX} // Add maxX parameter
      ) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX, // Use maxX or default to the number of labels
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(show: showGrid),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    index < xAxisLabels.length ? xAxisLabels[index] : '',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey,
            width: 1,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
          ),
        ],
      ),
    );
  }
}