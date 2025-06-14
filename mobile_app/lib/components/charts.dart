import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// A utility class for building line charts using Syncfusion Flutter Charts.
class Charts {
  static Widget buildLineChart({
    required String title,
    required List<List<ChartData>> data,
    required List<Color> lineColors,
    required double minY,
    required double maxY,
    required List<String> xAxisLabels,
    required List<String> headers,
    bool isScrollable = false,
    Color backgroundColor = Colors.white,
    bool showGrid = false,
    double? maxX,
    ScrollController? scrollController,
  }) {
    scrollController ??= ScrollController(); // Ensure scrollController is initialized

    double targetPosition = (maxX ?? (xAxisLabels.length - 1).toDouble()) * 40.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController != null && scrollController.hasClients) {
        final ScrollPosition position = scrollController.position;
        final double currentOffset = position.pixels;
        final double maxOffset = position.maxScrollExtent;

        // Auto-scroll only if:
        // - User wasn't dragging
        // - Was already at/near the end OR it's the initial load
        if ((currentOffset >= maxOffset - 200)) {
          scrollController.animateTo(
            targetPosition,
            duration: const Duration(milliseconds: 2000),
            curve: Curves.easeInOut,
          );
        }
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
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: 400,
                child: Row(
                  children: [
                    Expanded(
                      child: isScrollable
                          ? Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: scrollController,
                          child: SizedBox(
                            width: maxX != null
                                ? (maxX + 5.0) * 40.0 // Add buffer of 5 extra points width
                                : (xAxisLabels.length + 5.0) * 40.0,
                            child: _buildLineChartContent(
                              data,
                              lineColors,
                              headers,
                              minY,
                              maxY,
                              xAxisLabels,
                              showGrid,
                              maxX: maxX,
                            ),
                          ),
                        ),
                      )
                          : _buildLineChartContent(
                        data,
                        lineColors,
                        headers,
                        minY,
                        maxY,
                        xAxisLabels,
                        showGrid,
                        maxX: maxX,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _buildLineChartContent(
      List<List<ChartData>> data,
      List<Color> lineColors,
      List<String> headers,
      double minY,
      double maxY,
      List<String> xAxisLabels,
      bool showGrid, {
        double? maxX,
      }) {
    // Tooltip Configuration
    TooltipBehavior tooltipBehavior = TooltipBehavior(
      enable: true,
      format: 'point.x : point.y',
      color: Color(0xFFCDE1F6),
      textStyle: const TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      header: 'Time : Value',
    );

    const shapes = [
      DataMarkerType.circle,
      DataMarkerType.rectangle,
      DataMarkerType.triangle,
      DataMarkerType.diamond,
      DataMarkerType.invertedTriangle,
    ];

    final List<LineSeries<ChartData, String>> seriesList =
    List.generate(data.length, (index) {
      return LineSeries<ChartData, String>(
        name: headers[index],
        dataSource: data[index],
        xValueMapper: (ChartData data, _) => data.x,
        yValueMapper: (ChartData data, _) => data.y,
        color: lineColors[index % lineColors.length],
        width: 3,
        markerSettings: MarkerSettings(
          isVisible: true,
          shape: shapes[index % shapes.length],
        ),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
        enableTooltip: true,
      );
    });

    return SfCartesianChart(
      tooltipBehavior: tooltipBehavior,
      primaryXAxis: CategoryAxis(
        labelPlacement: LabelPlacement.onTicks,
        majorGridLines: MajorGridLines(width: showGrid ? 1 : 0, color: Colors.black),
        labelStyle: const TextStyle(fontSize: 10, color: Colors.black54),
        labelIntersectAction: AxisLabelIntersectAction.rotate45,
        labelRotation: -45,
        interval: 3,
      ),
      primaryYAxis: NumericAxis(
        minimum: minY,
        maximum: maxY,
        interval: (maxY - minY) / 4,
        majorGridLines: MajorGridLines(width: showGrid ? 1 : 0, color: Colors.black),
        labelStyle: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      series: seriesList,
      legend: Legend(
        isVisible: true,
        position: LegendPosition.top,
        alignment: ChartAlignment.far,
        textStyle: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }
}

class ChartData {
  final String x;
  final double? y;

  ChartData(this.x, this.y);
}