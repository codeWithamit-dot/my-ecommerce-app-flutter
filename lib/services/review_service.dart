// lib/services/review_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  final _client = Supabase.instance.client;

  // Fetches all reviews for a specific product, along with the reviewer's name
  // from the 'profiles' table.
  Future<List<Map<String, dynamic>>> getReviewsForProduct(String productId) async {
    try {
      final response = await _client
          .from('product_reviews')
          // Fetch all columns from reviews, and 'full_name' from profiles
          .select('*, profiles(full_name)')
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
      // Return an empty list on error to prevent the UI from crashing
      return [];
    }
  }

  // A function for submitting a new review (we will use this later).
  Future<void> addReview({
    required String productId,
    required int rating,
    required String reviewText,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("User must be logged in to post a review.");
    
    await _client.from('product_reviews').insert({
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
      'review_text': reviewText,
    });
  }
}