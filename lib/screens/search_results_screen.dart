// Path: lib/screens/search_results_screen.dart

import 'package:flutter/material.dart';
import '../model/product_model.dart';
import '../products/product_detail_screen.dart';
import '../services/product_service.dart';
import 'search_filters_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchTerm;

  const SearchResultsScreen({super.key, required this.searchTerm});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = _productService.searchProducts(widget.searchTerm);
  }

  void _navigateToFilters() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchFiltersScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "${widget.searchTerm}"'),
      ),
      body: Column(
        children: [
          _buildControlsBar(),
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.filter_list),
            label: const Text('Filter'),
            onPressed: _navigateToFilters,
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.sort),
            label: const Text('Sort'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sorting feature coming soon!"))
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return FutureBuilder<List<Product>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Center(child: Text('No products found for "${widget.searchTerm}"'));
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(context, product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final firstImageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProductDetailScreen(productId: product.id),
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
                      errorBuilder: (_, __, ___) => Icon(Icons.broken_image, color: Colors.grey[400]),
                    )
                  : Container(color: Colors.grey[200], child: Icon(Icons.image_not_supported, color: Colors.grey[400])),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('₹${product.price}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}