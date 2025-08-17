// lib/models/analytics_data.dart

class AnalyticsData {
  final double totalSales;
  final int totalUsers;
  final int activeUsers;

  AnalyticsData({
    required this.totalSales,
    required this.totalUsers,
    required this.activeUsers,
  });

  // Supabase RPC से मिले JSON को Dart ऑब्जेक्ट में बदलने के लिए
  factory AnalyticsData.fromMap(Map<String, dynamic> map) {
    return AnalyticsData(
      totalSales: (map['total_sales'] ?? 0.0).toDouble(),
      totalUsers: map['total_users'] ?? 0,
      activeUsers: map['active_users'] ?? 0,
    );
  }
}