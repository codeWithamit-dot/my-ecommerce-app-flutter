// lib/screens/seller_store_screen.dart
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/products/product_detail_screen.dart'; // ✅ Import the product detail screen
import 'package:my_ecommerce_app/screens/seller_reviews_screen.dart';

class SellerStoreScreen extends StatefulWidget {
  final String sellerId;
  const SellerStoreScreen({super.key, required this.sellerId});

  @override
  State<SellerStoreScreen> createState() => _SellerStoreScreenState();
}

class _SellerStoreScreenState extends State<SellerStoreScreen> {
  // Use a Future to manage state more cleanly with FutureBuilder
  late Future<Map<String, dynamic>> _sellerDataFuture;

  @override
  void initState() {
    super.initState();
    _sellerDataFuture = _fetchSellerData();
  }

   Future<Map<String, dynamic>> _fetchSellerData() async {
    try {
      // Query 1: Get the seller's profile information.
      final sellerResponse = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.sellerId)
          .single();

      // Query 2: Get all products listed by this seller.
      final productResponse = await supabase
          .from('products')
          .select()
          .eq('user_id', widget.sellerId);

      // Return both results in a single map.
      return {
        'seller_info': sellerResponse,
        'products': List<Map<String, dynamic>>.from(productResponse)
      };
    } catch (e) {
      debugPrint('Error fetching seller data: $e');
      throw Exception('Could not load store data.');
    }
  }
  
  // A helper widget to build each product item card
  Widget _buildProductItem(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: (product['image_url'] != null && product['image_url'].isNotEmpty)
            ? Image.network(product['image_url'], width: 50, height: 50, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),)
            : Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
        title: Text(product['product_name'] ?? ''),
        subtitle: Text('₹${product['price'] ?? '0'}'),
        onTap: () {
          // ✅ Navigate to the ProductDetailScreen when a product is tapped
          Navigator.of(context).push(
            MaterialPageRoute(
              // The product ID must be a String (UUID)
              builder: (ctx) => ProductDetailScreen(productId: product['id'] as String)
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(), // AppBar will get title from FutureBuilder
      body: FutureBuilder<Map<String, dynamic>>(
        future: _sellerDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error: ${snapshot.error ?? "Could not load store data."}'));
          }
          
          final data = snapshot.data!;
          final sellerInfo = data['seller_info'] as Map<String, dynamic>;
          final products = data['products'] as List<Map<String, dynamic>>;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(sellerInfo['store_name'] ?? 'Seller Store'),
                pinned: true,
                automaticallyImplyLeading: false, // Prevents a second back button
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sellerInfo['store_name'] ?? 'No Store Name',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(sellerInfo['about_business'] ?? 'No business description provided.'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('View All Seller Reviews'),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                              builder: (_) => SellerReviewsScreen(sellerId: widget.sellerId),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('All Products', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
              // Use SliverList for better performance with long lists
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: _buildProductItem(products[index]),
                  ),
                  childCount: products.length,
                ),
              ),
            ],
          );
        },
      )
    );
  }
}