// lib/screens/home_page_content.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ecommerce_app/main.dart'; // supabase client ke liye
import 'package:my_ecommerce_app/products/product_detail_screen.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  Future<List<Map<String, dynamic>>> _fetchLiveProducts() {
    return supabase
        .from('live_products')
        .select()
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F5),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchLiveProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error fetching products: ${snapshot.error}", style: GoogleFonts.irishGrover(color: Colors.black54, fontSize: 18)));
          
          final products = snapshot.data ?? [];
          if (products.isEmpty) return Center(child: Text('No products found.\nStay tuned for new arrivals!', textAlign: TextAlign.center, style: GoogleFonts.irishGrover(color: Colors.black54, fontSize: 18)));
          
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.7,
              crossAxisSpacing: 12, mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final imageUrls = product['image_urls'] as List?;
              final firstImageUrl = (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls.first as String : null;

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      // ✅ FIX: Ab yeh call bilkul sahi hai
                      builder: (context) => ProductDetailScreen(
                        productId: product['id'], 
                        isFromLiveProducts: true
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Expanded(
                        child: (firstImageUrl != null)
                            ? Image.network(firstImageUrl, fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 40, color: Colors.grey[400]))
                            : Container(color: Colors.grey[200], child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400])),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(product['name'] ?? 'No Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('₹${product['price'] ?? 0}', style: GoogleFonts.poppins(color: const Color(0xFF267873), fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}