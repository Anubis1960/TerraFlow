import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Charts {
  static Widget buildLineChart({
    required String title,
    required List<ChartData> data,
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
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
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
                Expanded(
                  child: isScrollable
                      ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: scrollController,
                    child: SizedBox(
                      width: maxX != null ? maxX * 40.0 : xAxisLabels.length * 40.0,
                      child: _buildLineChartContent(
                        data,
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
                    data,
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
      List<ChartData> data,
      Color lineColor,
      double minY,
      double maxY,
      List<String> xAxisLabels,
      bool showGrid, {
        double? maxX,
      }) {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        labelPlacement: LabelPlacement.onTicks,
        majorGridLines: MajorGridLines(width: showGrid ? 1 : 0, color: Colors.black),
        labelStyle: const TextStyle(fontSize: 10, color: Colors.black54),
        maximum: maxX ?? (xAxisLabels.length - 1).toDouble(),
        // Map x-axis labels to their respective values
        labelIntersectAction: AxisLabelIntersectAction.rotate45,
        arrangeByIndex: true, // Ensure labels are displayed in the correct order
      ),
      primaryYAxis: NumericAxis(
        minimum: minY,
        maximum: maxY,
        interval: (maxY - minY) / 4, // Set a fixed interval to avoid doubled values
        majorGridLines: MajorGridLines(width: showGrid ? 1 : 0, color: Colors.black),
        labelStyle: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      series: <LineSeries<ChartData, String>>[
        LineSeries<ChartData, String>(
          dataSource: data,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          color: lineColor,
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true),
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),
      ],
    );
  }
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}