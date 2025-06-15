/// Represents water usage data for a specific date.
class WaterUsage{
  double waterUsed;
  final String date;

  /// Creates a WaterUsage object with the specified water usage and date.
  /// @param waterUsed The amount of water used in liters.
  /// @param date The date of the water usage in 'YYYY/MM' format.
  WaterUsage({
    required this.waterUsed,
    required this.date,
  });

  /// Converts the JSON map to a WaterUsage object.
  /// @param json The JSON map to convert.
  /// @return A [WaterUsage] object created from the JSON map.
  static WaterUsage fromJson(Map<String, dynamic> json) {
    return WaterUsage(
      waterUsed: json['water_used']?.toDouble() ?? 0.0,
      date: json['date'] as String? ?? '',
    );
  }
}