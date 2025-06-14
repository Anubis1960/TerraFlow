/// Represents water usage data for a specific date.
class WaterUsage{
  double waterUsed;
  final String date;

  WaterUsage({
    required this.waterUsed,
    required this.date,
  });

  static WaterUsage fromJson(Map<String, dynamic> json) {
    return WaterUsage(
      waterUsed: json['water_used']?.toDouble() ?? 0.0,
      date: json['date'] as String? ?? '',
    );
  }
}