// lib/screens/add_review_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/services/review_service.dart';

// --- StarRating helper widget mein koi badlav nahi ---
class StarRating extends StatefulWidget {
  final Function(int rating) onRatingChanged;
  const StarRating({super.key, required this.onRatingChanged});

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  int _rating = 0;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) {
      return IconButton(onPressed: () { setState(() => _rating = index + 1); widget.onRatingChanged(_rating); },
        icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 40));
    }));
  }
}

// --- AddReviewScreen ka main code ---
class AddReviewScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String sellerId; // ✅ FIX #1: Ab 'sellerId' bhi chahiye hoga

  const AddReviewScreen({
    super.key, 
    required this.productId, 
    required this.productName,
    required this.sellerId, // 'sellerId' zaroori hai
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _reviewController = TextEditingController();
  final _reviewService = ReviewService();
  int _selectedRating = 0;
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a star rating.'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isLoading = true);
    try {
      // ✅ FIX #2: `sellerId` ko bhi ab review ke saath bheja ja raha hai
      await _reviewService.addReview(
        productId: widget.productId, 
        sellerId: widget.sellerId,
        rating: _selectedRating, 
        reviewText: _reviewController.text.trim()
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your review!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit review: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('What is your rating for:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(widget.productName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            StarRating(onRatingChanged: (rating) { _selectedRating = rating; }),
            const SizedBox(height: 30),
            TextField(controller: _reviewController,
              decoration: const InputDecoration(labelText: 'Your Review (Optional)', border: OutlineInputBorder(), alignLabelWithHint: true),
              maxLines: 5),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitReview,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Theme.of(context).primaryColor),
              child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('Submit Review', style: TextStyle(color: Colors.white, fontSize: 18))
            )]
        )
      )
    );
  }
}