// lib/screens/analytics_dashboard_screen.dart

import 'package:flutter/material.dart';
// पैकेज-रिलेटिव इम्पोर्ट का उपयोग करें
import 'package:my_ecommerce_app/services/analytics_service.dart';
import 'package:my_ecommerce_app/model/analytics_data.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final AnalyticsService analyticsService;

  const AnalyticsDashboardScreen({required this.analyticsService, super.key});

  @override
  // ✅ ठीक किया गया: linter की चेतावनी हटाने के लिए स्टेट क्लास को पब्लिक बनाया गया
  AnalyticsDashboardScreenState createState() => AnalyticsDashboardScreenState();
}

class AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  AnalyticsData? data;

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    final fetched = await widget.analyticsService.fetchAnalytics();
    if (mounted) { // सुनिश्चित करें कि विजेट अभी भी ट्री में है
      setState(() => data = fetched);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Dashboard')),
      body: RefreshIndicator(
        onRefresh: fetchAnalytics,
        child: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(child: ListTile(title: const Text('Total Sales'), trailing: Text('\$${data!.totalSales.toStringAsFixed(2)}'))),
          Card(child: ListTile(title: const Text('Total Users'), trailing: Text('${data!.totalUsers}'))),
          Card(child: ListTile(title: const Text('Active Users (Last 7 days)'), trailing: Text('${data!.activeUsers}'))),
        ],
      ),
    );
  }
}