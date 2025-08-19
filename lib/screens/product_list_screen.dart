// lib/screens/product_list_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/products/product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String categoryName;

  const ProductListScreen({super.key, required this.categoryName});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProductsByCategory();
  }

  Future<List<Map<String, dynamic>>> _fetchProductsByCategory() {
    return supabase
        .from('live_products') // Sirf live products dikhayenge
        .select()
        .eq('category', widget.categoryName) // Yahi hai asli jaadoo!
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFE0F7F5),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return Center(
              child: Text(
                'No products found in this category.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              ),
            );
          }
          
          // Yeh UI bilkul HomePageContent jaisa hai
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(context, products[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final imageUrls = product['image_urls'] as List?;
    final firstImageUrl = (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls.first as String : null;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            productId: product['id'],
            isFromLiveProducts: true,
          ),
        ));
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: (firstImageUrl != null)
                  ? Image.network(
                      firstImageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                    )
                  : Container(color: Colors.grey[200], child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400])),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product['name'] ?? 'No Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('₹${product['price'] ?? 0}', style: GoogleFonts.poppins(color: const Color(0xFF267873), fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}