// lib/products/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/services/review_service.dart';
import 'package:my_ecommerce_app/screens/seller_store_screen.dart'; // ✅ 1. Import the seller store screen

class ProductDetailScreen extends StatefulWidget {
  // Your product ID is a UUID (String), not an int.
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final Future<Map<String, dynamic>> _dataFuture;
  final ReviewService _reviewService = ReviewService();
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchPageData();
  }

  Future<Map<String, dynamic>> _fetchPageData() async {
    final results = await Future.wait([
      _fetchProductDetails(),
      _reviewService.getReviewsForProduct(widget.productId),
    ]);
    return {
      'product': results[0] as Map<String, dynamic>,
      'reviews': results[1] as List<Map<String, dynamic>>,
    };
  }

  Future<Map<String, dynamic>> _fetchProductDetails() async {
    // ✅ 2. Select the 'user_id' from the products table. This is the seller's ID.
    return await supabase
        .from('products')
        .select('*, user_id, stock_quantity, average_rating, review_count, profiles(store_name)')
        .eq('id', widget.productId)
        .single();
  }

  Future<void> _addToCart() async {
    setState(() => _isAddingToCart = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final existingCartItem = await supabase
          .from('cart')
          .select()
          .eq('user_id', userId)
          .eq('product_id', widget.productId)
          .maybeSingle();
          
      if (existingCartItem != null) {
        final newQuantity = (existingCartItem['quantity'] as int) + 1;
        await supabase.from('cart').update({'quantity': newQuantity}).eq('id', existingCartItem['id']);
      } else {
        await supabase.from('cart').insert({
          'user_id': userId,
          'product_id': widget.productId,
          'quantity': 1,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added to cart!'), backgroundColor: Colors.green));
      }
    } catch(e) {
      _showError("Failed to add product: ${e.toString()}");
    } finally {
      if(mounted) setState(() => _isAddingToCart = false);
    }
  }

  void _showError(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("Error: Could not load data. ${snapshot.error}"));
          }
          
          final data = snapshot.data!;
          final product = data['product'] as Map<String, dynamic>;
          final reviews = data['reviews'] as List<Map<String, dynamic>>;
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProductImage(product['image_url']),
                _buildProductInfo(product),
                _buildReviewsSection(reviews),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final product = snapshot.data!['product'];
          final stockQuantity = product['stock_quantity'] as int? ?? 0;
          return _buildBottomBar(stockQuantity);
        }
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildProductImage(String? imageUrl) {
    return Container(
      height: 300,
      color: Colors.grey[200],
      child: (imageUrl != null && imageUrl.isNotEmpty)
          ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))
          : const Center(child: Icon(Icons.image_not_supported)),
    );
  }

  Widget _buildProductInfo(Map<String, dynamic> product) {
    final storeName = (product['profiles'] as Map?)?['store_name'] ?? 'N/A';
    final averageRating = (product['average_rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = product['review_count'] as int? ?? 0;
    final stockQuantity = product['stock_quantity'] as int? ?? 0;
    // ✅ 3. Extract the seller's ID from the product data
    final String? sellerId = product['user_id']; 

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 4. Wrap the 'Sold by' Text in an InkWell to make it tappable
          InkWell(
            onTap: () {
              // Navigate to the seller store screen only if we have a seller ID
              if (sellerId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => SellerStoreScreen(sellerId: sellerId),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(4), // For a nice ripple effect
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sold by: $storeName', 
                    style: TextStyle(
                      color: Theme.of(context).primaryColor, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 16, color: Theme.of(context).primaryColor),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          Text(product['product_name'] ?? 'No Name', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildRatingAndStockRow(averageRating, reviewCount, stockQuantity),
          const SizedBox(height: 12),
          Text('\u20B9${product['price'] ?? 0}', style: TextStyle(fontSize: 24, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(product['description'] ?? 'No description available.', style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildRatingAndStockRow(double avgRating, int reviewCount, int stockQty) {
    return Row(
      children: [
        _buildStarRating(avgRating),
        const SizedBox(width: 8),
        if(reviewCount > 0)
          Text('($reviewCount ${reviewCount > 1 ? 'reviews' : 'review'})', style: TextStyle(color: Colors.grey[600])),
        const Spacer(),
        _buildStockStatusChip(stockQty),
      ],
    );
  }
  
  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _buildReviewsSection(List<Map<String, dynamic>> reviews) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text('Customer Reviews (${reviews.length})', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('No reviews yet. Be the first to write one!'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final review = reviews[index];
                final userName = (review['profiles'] as Map?)?['full_name'] ?? 'Anonymous';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildStarRating((review['rating'] as int).toDouble()),
                          const Spacer(),
                           Text(DateFormat.yMMMd().format(DateTime.parse(review['created_at']))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('by $userName', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(review['review_text'] ?? ''),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildStockStatusChip(int quantity) {
    if (quantity > 5) {
      return Chip(label: const Text('In Stock'), backgroundColor: Colors.green.withAlpha(25), side: const BorderSide(color: Colors.green));
    } else if (quantity > 0) {
      return Chip(label: Text('Only $quantity left!'), backgroundColor: Colors.orange.withAlpha(25), side: const BorderSide(color: Colors.orange));
    } else {
      return const Chip(label: Text('Out of Stock'), backgroundColor: Colors.redAccent, labelStyle: TextStyle(color: Colors.white));
    }
  }

  Widget _buildBottomBar(int quantity) {
    final bool canAddToCart = quantity > 0 && !_isAddingToCart;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(25), spreadRadius: 1, blurRadius: 5)
        ]
      ),
      child: ElevatedButton.icon(
        onPressed: canAddToCart ? _addToCart : null, 
        icon: _isAddingToCart
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: Text(
          _isAddingToCart ? 'Adding...' : (quantity > 0 ? 'Add to Cart' : 'Out of Stock'),
          style: const TextStyle(color: Colors.white)
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          backgroundColor: Theme.of(context).primaryColor,
          disabledBackgroundColor: Colors.grey, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}