import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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
        scrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 800),
          curve: Curves.linear,
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
                                ? maxX * 40.0
                                : xAxisLabels.length * 40.0,
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
      bool showGrid,{
        double? maxX,
      }) {
    // Debugging: Print data to verify consistency
    for (int i = 0; i < data.length; i++) {
      for (int j = 0; j < data[i].length; j++) {
      }
    }

    // Tooltip Configuration
    TooltipBehavior tooltipBehavior = TooltipBehavior(
      enable: true,
      format: 'point.x : point.y',
      color: Colors.deepPurple,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      header: ' Time : Value',
    );

    const shapes = [
      DataMarkerType.circle,
      DataMarkerType.rectangle,
      DataMarkerType.triangle,
      DataMarkerType.diamond,
      DataMarkerType.invertedTriangle,
    ];

    // Generate LineSeries for each dataset
    final List<LineSeries<ChartData, String>> seriesList =
    List.generate(data.length, (index) {

      return LineSeries<ChartData, String>(
        name: headers[index], // Assign a name to each series
        dataSource: data[index],
        xValueMapper: (ChartData data, _) => data.x,
        yValueMapper: (ChartData data, _) => data.y,
        color: lineColors[index % lineColors.length],
        width: 3,
        markerSettings: MarkerSettings(
            isVisible: true,
            shape: shapes[index % shapes.length], // Cycle through shapes
        ),
        dataLabelSettings: const DataLabelSettings(
            isVisible: false,

        ),
        enableTooltip: true,
      );
    });

    for (int i = 0; i < seriesList.length; i++) {
    }

    return SfCartesianChart(
      tooltipBehavior: tooltipBehavior,
      enableAxisAnimation: true,
      primaryXAxis: CategoryAxis(
        labelPlacement: LabelPlacement.onTicks, // Align labels with ticks
        majorGridLines: MajorGridLines(width: showGrid ? 1 : 0, color: Colors.black),
        labelStyle: const TextStyle(fontSize: 10, color: Colors.black54),
        labelIntersectAction: AxisLabelIntersectAction.rotate45, // Rotate labels if overlapping
        labelRotation: -45,
        interval: 3, // Show every label
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
        position: LegendPosition.auto,
        alignment: ChartAlignment.center,
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