// lib/screens/seller_store_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/products/product_detail_screen.dart';
import 'package:my_ecommerce_app/screens/seller_reviews_screen.dart';

class SellerStoreScreen extends StatefulWidget {
  final String sellerId;
  const SellerStoreScreen({super.key, required this.sellerId});

  @override
  State<SellerStoreScreen> createState() => _SellerStoreScreenState();
}

class _SellerStoreScreenState extends State<SellerStoreScreen> {
  late Future<Map<String, dynamic>> _sellerDataFuture;

  @override
  void initState() {
    super.initState();
    _sellerDataFuture = _fetchSellerData();
  }

  Future<Map<String, dynamic>> _fetchSellerData() async {
    try {
      final sellerResponse = await supabase
          .from('profiles')
          .select('full_name, business_name, about_business')
          .eq('id', widget.sellerId)
          .single();

      final productResponse = await supabase
          .from('live_products')
          .select()
          .eq('seller_id', widget.sellerId);

      return {
        'seller_info': sellerResponse,
        'products': List<Map<String, dynamic>>.from(productResponse)
      };
    } catch (e) {
      debugPrint('Error fetching seller data: $e');
      throw Exception('Could not load store data.');
    }
  }
  
  Widget _buildProductItem(Map<String, dynamic> product) {
    final imageUrls = product['image_urls'] as List?;
    final firstImageUrl = (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls.first as String : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        leading: (firstImageUrl != null)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(firstImageUrl, width: 50, height: 50, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported)),
              )
            : Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
        title: Text(product['name'] ?? ''),
        subtitle: Text('₹${product['price'] ?? '0'}'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => ProductDetailScreen(
                productId: product['id'] as String,
                isFromLiveProducts: true
              )
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _sellerDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData) return Center(child: Text('Error: ${snapshot.error ?? "Could not load store data."}'));
          
          final data = snapshot.data!;
          final sellerInfo = data['seller_info'] as Map<String, dynamic>;
          final products = data['products'] as List<Map<String, dynamic>>;
          final storeName = sellerInfo['business_name'] ?? 'Seller Store';

          return NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  title: Text(storeName),
                  pinned: true,
                  floating: true,
                ),
              ];
            },
            body: ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(storeName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(sellerInfo['about_business'] ?? 'No business description provided.'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('View Seller Reviews'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SellerReviewsScreen(sellerId: widget.sellerId))),
                      ),
                      const Divider(height: 32),
                      Text('All Products', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (products.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("This seller has no products yet.")))
                else
                  // ✅ FINAL FIX: Yahan se `.toList()` hata diya gaya hai.
                  ...products.map((prod) => _buildProductItem(prod)),
              ],
            ),
          );
        },
      )
    );
  }
}