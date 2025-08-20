// lib/screens/wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/products/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late Future<List<Map<String, dynamic>>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _wishlistFuture = _loadWishlist();
  }
  
  Future<void> _refreshWishlist() async {
    setState(() {
      _wishlistFuture = _loadWishlist();
    });
  }
  
  Future<List<Map<String, dynamic>>> _loadWishlist() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await supabase
          .from('wishlist')
          .select('id, products!inner(*)') 
          .eq('buyer_id', userId)
          .eq('products.is_approved', true) 
          // ✅✅✅ YEH HAI FINAL FIX ✅✅✅
          // 'created_at' ko aapki table ke column 'added_at' se badal diya gaya hai.
          .order('added_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wishlist: ${e.toString()}')),
        );
      }
      return [];
    }
  }

  Future<void> _removeFromWishlist(String wishlistId) async {
    try {
      await supabase.from('wishlist').delete().eq('id', wishlistId);
      _refreshWishlist(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFE0F7F5),
      body: RefreshIndicator(
        onRefresh: _refreshWishlist,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _wishlistFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
            
            final wishlistItems = snapshot.data ?? [];
            if (wishlistItems.isEmpty) {
              return const Center(
                child: Text(
                  'Your wishlist is empty.\nTap the heart on a product to save it here!',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: wishlistItems.length,
              itemBuilder: (context, index) {
                final item = wishlistItems[index];
                final product = item['products'] as Map<String, dynamic>?;
                
                if (product == null) {
                  return const Card(child: ListTile(title: Text('This product is no longer available.')));
                }
                return _buildWishlistItemCard(item, product);
              },
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildWishlistItemCard(Map<String, dynamic> wishlistItem, Map<String, dynamic> product) {
    final imageUrls = product['image_urls'] as List?;
    final firstImageUrl = (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls.first.toString() : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: firstImageUrl != null
              ? Image.network(firstImageUrl, width: 60, height: 60, fit: BoxFit.cover)
              : Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
        ),
        title: Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('₹${product['price'] ?? 'N/A'}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red[700]),
          onPressed: () => _removeFromWishlist(wishlistItem['id']),
          tooltip: 'Remove from Wishlist',
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProductDetailScreen(
              productId: product['id'],
              isFromLiveProducts: true,
            )),
          );
        },
      ),
    );
  }
}