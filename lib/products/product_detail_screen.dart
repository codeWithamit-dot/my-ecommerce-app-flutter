// lib/products/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../screens/add_review_screen.dart';
import '../services/review_service.dart';
import '../screens/seller_store_screen.dart';
import '../services/wishlist_service.dart'; // ✅ FINAL FIX: Import path ko theek kar diya gaya hai

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final bool isFromLiveProducts;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.isFromLiveProducts = false,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Map<String, dynamic>> _dataFuture;
  final ReviewService _reviewService = ReviewService();
  final WishlistService _wishlistService = WishlistService();
  bool _isAddingToCart = false;
  bool _isWishlisted = false;
  bool _isLoadingWishlist = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchPageData();
  }

  Future<Map<String, dynamic>> _fetchPageData() async {
    final results = await Future.wait([
      _fetchProductDetails(),
      _reviewService.getReviewsForProduct(widget.productId),
      _wishlistService.isProductWishlisted(widget.productId),
    ]);
    
    if (mounted) {
      setState(() {
        _isWishlisted = results[2] as bool;
        _isLoadingWishlist = false;
      });
    }

    return {
      'product': results[0] as Map<String, dynamic>,
      'reviews': results[1] as List<Map<String, dynamic>>,
    };
  }

  Future<Map<String, dynamic>> _fetchProductDetails() {
    final tableName = widget.isFromLiveProducts ? 'live_products' : 'products';
    return supabase.from(tableName).select('*, profiles:seller_id(full_name)').eq('id', widget.productId).single();
  }
  
  Future<void> _toggleWishlist() async {
    setState(() => _isLoadingWishlist = true);
    try {
      if (_isWishlisted) {
        await _wishlistService.removeFromWishlist(widget.productId);
      } else {
        await _wishlistService.addToWishlist(widget.productId);
      }
      if (mounted) {
        setState(() => _isWishlisted = !_isWishlisted);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoadingWishlist = false);
    }
  }

  void _navigateToAddReview(String productId, String productName, String sellerId) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AddReviewScreen(productId: productId, productName: productName, sellerId: sellerId)));
  }

  Future<void> _addToCart() async { 
    setState(() => _isAddingToCart = true); 
    try { 
      final userId = supabase.auth.currentUser!.id;
      final existingCartItem = await supabase.from('cart').select().eq('buyer_id', userId).eq('product_id', widget.productId).maybeSingle();
      if (existingCartItem != null) { 
        final newQuantity = (existingCartItem['quantity'] as int) + 1;
        await supabase.from('cart').update({'quantity': newQuantity}).eq('id', existingCartItem['id']);
      } else { 
        await supabase.from('cart').insert({'buyer_id': userId, 'product_id': widget.productId, 'quantity': 1});
      }
      if (mounted) { 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added to cart!'), backgroundColor: Colors.green));
      }
    } catch(e) { 
      if (mounted) { 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add product: ${e.toString()}"), backgroundColor: Colors.red)); 
      }
    } finally { 
      if(mounted) { 
        setState(() => _isAddingToCart = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) { 
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData) return Center(child: Text("Error: Could not load data. ${snapshot.error}"));
          final data = snapshot.data!; 
          final product = data['product'] as Map<String, dynamic>; 
          final reviews = data['reviews'] as List<Map<String, dynamic>>;
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(product),
              _buildProductInfoSliver(product, reviews),
              _buildReviewsSliver(reviews),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture, 
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink(); 
          final product = snapshot.data!['product'];
          return _buildBottomBar(product['stock_quantity'] as int? ?? 0);
        }
      )
    );
  }

  SliverAppBar _buildSliverAppBar(Map<String, dynamic> product) {
    return SliverAppBar(
      expandedHeight: 320.0,
      floating: false, pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 1,
      leading: const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircleAvatar(backgroundColor: Colors.white, child: BackButton(color: Colors.black)),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: _isLoadingWishlist 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: Icon(
                    _isWishlisted ? Icons.favorite : Icons.favorite_border,
                    color: _isWishlisted ? Colors.redAccent : Colors.grey,
                  ), 
                  onPressed: _toggleWishlist
                )
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(background: _buildImageGallery(product['image_urls'] as List?)),
    );
  }

  Widget _buildImageGallery(List<dynamic>? imageUrls) {
    final images = imageUrls?.map((e) => e.toString()).toList() ?? [];
    if (images.isEmpty) return const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 60));
    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (index) => setState(() => _currentImageIndex = index),
          itemBuilder: (context, index) => Image.network(
            images[index], 
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 60)),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 10, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.map((url) {
                int index = images.indexOf(url);
                return Container(
                  width: 8.0, height: 8.0,
                  margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index ? const Color.fromRGBO(0, 0, 0, 0.9) : const Color.fromRGBO(0, 0, 0, 0.4),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  SliverToBoxAdapter _buildProductInfoSliver(Map<String, dynamic> product, List<Map<String, dynamic>> reviews) {
    final sellerName = (product['profiles'] as Map?)?['full_name'] ?? 'N/A';
    final sellerId = product['seller_id'] as String?;
    final averageRating = (product['average_rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = product['review_count'] as int? ?? 0;
    final stockQuantity = product['stock_quantity'] as int? ?? 0;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRatingAndStockRow(averageRating, reviewCount, stockQuantity),
            const SizedBox(height: 12),
            InkWell(
              onTap: () { if (sellerId != null) { Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => SellerStoreScreen(sellerId: sellerId))); } },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(children: [Text('Sold by: $sellerName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 8), const Icon(Icons.open_in_new, size: 16, color: Colors.blueAccent)])),
            ),
            const SizedBox(height: 8),
            Text(product['name'] ?? 'No Name', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('₹${product['price'] ?? 0}', style: TextStyle(fontSize: 28, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
            const Divider(height: 40),
            Text('Description', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(product['description'] ?? 'No description available.', style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black54)),
            const Divider(height: 40),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Customer Reviews (${reviews.length})', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {
                final sellerId = product['seller_id']; if (sellerId != null) {
                  _navigateToAddReview(widget.productId, product['name'], sellerId);
                }}, child: const Text('Write a Review'))
            ]),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReviewsSliver(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) {
      return const SliverToBoxAdapter(
        // ✅ FINAL FIX: Added 'const' to fix the linter warning.
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text('No reviews yet. Be the first to write one!'),
        ),
      );
    }
    return SliverList(delegate: SliverChildBuilderDelegate(
      (context, index) {
        final review = reviews[index];
        final userName = (review['profiles'] as Map?)?['full_name'] ?? 'Anonymous';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [_buildStarRating((review['rating'] as int).toDouble()),
                const Spacer(),
                Text(DateFormat.yMMMd().format(DateTime.parse(review['created_at']))),
              ]),
              const SizedBox(height: 8),
              Text('by $userName', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(review['review_text'] ?? ''),
            ],
          ),
        );
      }, childCount: reviews.length,
    ));
  }

  Widget _buildRatingAndStockRow(double avgRating, int reviewCount, int stockQty) { return Row(children: [
      _buildStarRating(avgRating), const SizedBox(width: 8),
      if (reviewCount > 0) Text('($reviewCount ${reviewCount > 1 ? 'reviews' : 'review'})', style: TextStyle(color: Colors.grey[600])),
      const Spacer(), _buildStockStatusChip(stockQty)]);}
  
  Widget _buildStarRating(double rating) { return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (index) => Icon(index < rating.round() ? Icons.star : Icons.star_border, color: Colors.amber, size: 20)));}
  
  Widget _buildStockStatusChip(int quantity) {
    if (quantity > 5) {return const Chip(label: Text('In Stock'), backgroundColor: Colors.green, labelStyle: TextStyle(color: Colors.white));} 
    else if (quantity > 0) {return Chip(label: Text('Only $quantity left!'), backgroundColor: Colors.orange, labelStyle: const TextStyle(color: Colors.white));} 
    else {return const Chip(label: Text('Out of Stock'), backgroundColor: Colors.redAccent, labelStyle: TextStyle(color: Colors.white));}}

  Widget _buildBottomBar(int quantity) { final bool canAddToCart = quantity > 0 && !_isAddingToCart;
    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(top: 8),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: Colors.grey.shade300))),
      child: ElevatedButton.icon(
        onPressed: canAddToCart ? _addToCart : null, 
        icon: _isAddingToCart ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: Text(_isAddingToCart ? 'Adding...' : (quantity > 0 ? 'Add to Cart' : 'Out of Stock'), style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          backgroundColor: const Color(0xFF267873), disabledBackgroundColor: Colors.grey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}