// lib/screens/seller_store_screen.dart

import 'package:flutter/material.dart';

// Mock data models and service for demonstration purposes
class Seller {
  final String id;
  final String name;
  final String bannerUrl;
  final double rating;
  final int totalReviews;

  Seller({required this.id, required this.name, required this.bannerUrl, required this.rating, required this.totalReviews});
}

class ProductStub {
  final String id;
  final String name;
  final String imageUrl;
  final double price;

  ProductStub({required this.id, required this.name, required this.imageUrl, required this.price});
}

class MockSellerService {
  Future<Map<String, dynamic>> fetchSellerData(String sellerId) async {
    // In a real app, this would be a network request
    await Future.delayed(const Duration(seconds: 1));
    return {
      'seller': Seller(id: sellerId, name: 'GreenLeaf Organics', bannerUrl: 'https://via.placeholder.com/600x250/A5D6A7/000000?Text=GreenLeaf', rating: 4.8, totalReviews: 1254),
      'products': List.generate(15, (index) => ProductStub(id: 'prod_$index', name: 'Organic Product ${index + 1}', imageUrl: 'https://via.placeholder.com/150/C8E6C9/000000?Text=Product+${index+1}', price: (index * 10.5) + 20)),
    };
  }
}

// The Screen Widget
class SellerStoreScreen extends StatefulWidget {
  final String sellerId;

  const SellerStoreScreen({super.key, required this.sellerId});

  @override
  State<SellerStoreScreen> createState() => _SellerStoreScreenState();
}

class _SellerStoreScreenState extends State<SellerStoreScreen> {
  late Future<Map<String, dynamic>> _sellerDataFuture;
  final MockSellerService _sellerService = MockSellerService();

  @override
  void initState() {
    super.initState();
    _sellerDataFuture = _sellerService.fetchSellerData(widget.sellerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _sellerDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading store: ${snapshot.error}'));
          }

          final Seller seller = snapshot.data!['seller'];
          final List<ProductStub> products = snapshot.data!['products'];

          return CustomScrollView(
            slivers: [
              _buildSellerAppBar(seller),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Text('All Products', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              _buildProductsStore(products),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSellerAppBar(Seller seller) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      backgroundColor: Colors.teal[700],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(seller.name, style: const TextStyle(shadows: [Shadow(blurRadius: 2, color: Colors.black54)])),
        centerTitle: false,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              seller.bannerUrl,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                // ✅ FIX: Replaced deprecated `withOpacity` with `withAlpha`
                color: Colors.black.withAlpha(80),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  SliverPadding _buildProductsStore(List<ProductStub> products) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildListDelegate(
            [
              // ✅ FIX: Removed unnecessary `.toList()` from the spread operator
              ...products.map((product) => _buildProductCard(product)),
            ]
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductStub product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(bottom: 8.0),
            child: Text(
              '₹${product.price.toStringAsFixed(2)}',
              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}