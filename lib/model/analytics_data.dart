// lib/model/analytics_data.dart

class AnalyticsData {
  // Yeh Admin aur Seller, dono ke kaam aayega
  final double totalSales;
  
  // Yeh sirf Seller ke liye hai
  final int newOrdersCount;
  
  // Yeh sirf Admin ke liye hai
  final int totalUsers;
  final int activeUsers;

  AnalyticsData({
    required this.totalSales,
    this.newOrdersCount = 0, // Inhe optional bana do, default value 0 ke saath
    this.totalUsers = 0,
    this.activeUsers = 0,
  });
  
  // Yeh "factory constructor" Admin aur Seller, dono ka data handle kar sakta hai
  factory AnalyticsData.fromMap(Map<String, dynamic> map) {
    return AnalyticsData(
      totalSales: (map['total_sales'] as num?)?.toDouble() ?? 0.0,
      newOrdersCount: map['new_orders_count'] as int? ?? 0,
      totalUsers: map['total_users'] as int? ?? 0,
      activeUsers: map['active_users'] as int? ?? 0,
    );
  }
  
  // Agar koi error aaye to yeh ek empty object banayega
  factory AnalyticsData.empty() {
    return AnalyticsData(totalSales: 0.0);
  }
}