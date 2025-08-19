// lib/screens/seller_reviews_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:intl/intl.dart';

class SellerReviewsScreen extends StatefulWidget {
  final String? sellerId;
  const SellerReviewsScreen({super.key, this.sellerId});

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  late Future<List<Map<String, dynamic>>> _reviewsFuture;
  String _headerTitle = 'My Reviews';

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _fetchSellerReviews();
  }

  Future<List<Map<String, dynamic>>> _fetchSellerReviews() async {
    final targetSellerId = widget.sellerId ?? supabase.auth.currentUser?.id;

    if (targetSellerId == null) {
      throw Exception('Seller ID could not be determined.');
    }

    if (widget.sellerId != null && mounted) {
      setState(() => _headerTitle = 'Reviews for Seller');
    }
    
    // ✅ FIX: Yahan bhi Supabase ko saaf-saaf relationships bata diye gaye hain.
    return await supabase
        .from('reviews')
        .select('''
          *, 
          profiles:user_id(full_name), 
          products:product_id(name)
        ''')
        .eq('seller_id', targetSellerId)
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_headerTitle),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFE0F7F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() { _reviewsFuture = _fetchSellerReviews(); });
          },
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) return const Center(child: Text("No reviews found.", style: TextStyle(fontSize: 16, color: Colors.grey)));

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: reviews.length,
                itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    // Sahi join ke baad data seedha nikal jaayega
    final productData = review['products'] as Map<String, dynamic>?;
    final productName = productData?['name'] ?? 'Product Deleted';
    
    final userData = review['profiles'] as Map<String, dynamic>?;
    final userName = userData?['full_name'] ?? 'Anonymous';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(productName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis)),
              Text(DateFormat.yMMMd().format(DateTime.parse(review['created_at'])), style: TextStyle(color: Colors.grey[600], fontSize: 12))]),
            const Divider(height: 16),
            Row(children: [
              _buildStarRating((review['rating'] as int).toDouble()),
              const SizedBox(width: 8),
              Text('by $userName', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]))]),
            const SizedBox(height: 8),
            Text(review['review_text'] ?? 'No comment provided.', style: const TextStyle(fontSize: 15, height: 1.4))]))
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (index) => Icon(
          index < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 20)));
  }
}