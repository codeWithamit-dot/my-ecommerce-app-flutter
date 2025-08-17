// lib/services/analytics_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_ecommerce_app/model/analytics_data.dart'; // पैकेज-रिलेटिव इम्पोर्ट का उपयोग करें

class AnalyticsService {
  final SupabaseClient client;

  AnalyticsService(this.client);

  Future<AnalyticsData?> fetchAnalytics() async {
    try {
      // ✅ ठीक किया गया: .execute() हटा दिया गया है
      final data = await client.rpc('fetch_analytics');

      if (data != null) {
        // RPC का डेटा सीधे Map के रूप में आता है
        return AnalyticsData.fromMap(data as Map<String, dynamic>);
      }
      return null;
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint("Analytics fetch error: ${error.message}");
      }
      return null;
    }
  }
}