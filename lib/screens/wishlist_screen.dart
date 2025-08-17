// lib/screens/wishlist_screen.dart
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _wishlist = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('wishlist')
          .select('*, product:products(*)')
          .eq('user_id', userId);

      if (!mounted) return;
      setState(() {
        _wishlist = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading wishlist: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeFromWishlist(String wishlistId) async {
    try {
      await supabase.from('wishlist').delete().eq('id', wishlistId);
      if (!mounted) return;
      _loadWishlist();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Wishlist')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wishlist.isEmpty
              ? const Center(child: Text('No items in wishlist.'))
              : ListView.builder(
                  itemCount: _wishlist.length,
                  itemBuilder: (context, index) {
                    final item = _wishlist[index];
                    final product = item['product'];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: product['image_url'] != null
                            ? Image.network(
                                product['image_url'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported),
                        title: Text(product['name'] ?? ''),
                        subtitle: Text('₹${product['price'] ?? 'N/A'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFromWishlist(item['id']),
                        ),
                        onTap: () {
                          // Product detail page link
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
