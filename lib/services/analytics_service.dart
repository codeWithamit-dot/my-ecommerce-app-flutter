// lib/services/analytics_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/analytics_data.dart'; // Sahi relative import

class AnalyticsService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AnalyticsData?> fetchAnalytics(String? userRole) async {
    try {
      final Map<String, dynamic> data;
      
      // Agar user seller hai, to seller wala function call karo
      if (userRole == 'seller') {
        data = await _client.rpc('get_seller_dashboard_analytics').single();
      } 
      // Agar user admin hai (future ke liye), to admin wala
      else if (userRole == 'admin') {
        data = await _client.rpc('fetch_analytics').single();
      }
      // Agar buyer hai ya koi role nahi, to kuch mat lao
      else {
        return AnalyticsData.empty(); // Ek khali data object
      }
      
      // Data ko model mein convert karo
      return AnalyticsData.fromMap(data);

    } catch (e) {
      if (kDebugMode) {
        debugPrint("Analytics fetch error: $e");
      }
      return AnalyticsData.empty();
    }
  }
}