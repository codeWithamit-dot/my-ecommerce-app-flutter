// lib/services/review_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getReviewsForProduct(String productId) async {
    try {
      // ✅ FIX: Ab Supabase ko pata hai ki `profiles` ko `user_id` se jodna hai.
      final response = await _client
          .from('reviews')
          .select('*, profiles:user_id(full_name)') 
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
      return [];
    }
  }

  Future<void> addReview({
    required String productId,
    required String sellerId,
    required int rating,
    required String reviewText,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("User must be logged in to post a review.");
    
    await _client.from('reviews').insert({
      'product_id': productId,
      'user_id': userId,
      'seller_id': sellerId,
      'rating': rating,
      'review_text': reviewText,
    });
  }
}