// lib/screens/seller_reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';

class SellerReviewsScreen extends StatefulWidget {
  final String sellerId;
  const SellerReviewsScreen({super.key, required this.sellerId});

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  final _reviewController = TextEditingController();
  double _rating = 5.0;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('seller_reviews')
          .select()
          .eq('seller_id', widget.sellerId)
          .order('created_at', ascending: false);

      setState(() {
        _reviews = List<Map<String, dynamic>>.from(data as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching reviews: $e')),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) return;

    try {
      await supabase.from('seller_reviews').insert({
        'seller_id': widget.sellerId,
        'user_id': supabase.auth.currentUser!.id,
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
      _reviewController.clear();
      _rating = 5.0;
      _fetchReviews();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(review['review'] ?? ''),
        subtitle: Text('Rating: ${review['rating'] ?? 0} ⭐'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Reviews')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextFormField(
              controller: _reviewController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Write your review',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Rating:'),
                Slider(
                  value: _rating,
                  onChanged: (val) => setState(() => _rating = val),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$_rating',
                ),
                Text('$_rating ⭐'),
              ],
            ),
            ElevatedButton(
              onPressed: _submitReview,
              child: const Text('Submit Review'),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: _reviews.isEmpty
                        ? const Center(child: Text('No reviews yet.'))
                        : ListView.builder(
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) =>
                                _buildReviewItem(_reviews[index]),
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
