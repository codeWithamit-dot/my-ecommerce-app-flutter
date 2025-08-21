// Path: lib/screens/search_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../model/product_model.dart';
import '../products/product_detail_screen.dart';
import '../services/product_service.dart';
import 'search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  
  List<Product> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  
  @override
  void initState() {
    super.initState();
  }

  /// Live search ke liye, jab user type kar raha ho.
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().length < 2) {
        if (mounted) setState(() => _suggestions = []);
        return;
      }
      if (mounted) setState(() => _isLoading = true);

      _productService.searchProducts(query).then((results) {
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isLoading = false;
          });
        }
      });
    });
  }

  /// Jab user keyboard par search button dabaye.
  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      // Ab hum user ko nayi result screen par bhejenge
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SearchResultsScreen(searchTerm: query),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true, // Keyboard apne aap khul jayega
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Search for products, brands...',
            hintStyle: TextStyle(color: Colors.white.withAlpha(200)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged(''); // Suggestions saaf karne ke liye
                  },
                )
              : null,
          ),
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmitted,
        ),
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.trim().isEmpty) {
      // Shuruaati screen
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Start typing to see product suggestions.',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    
    if (_suggestions.isEmpty && !_isLoading) {
       return Center(child: Text('No results found for "${_searchController.text}"'));
    }

    // Suggestions ki list
    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final product = _suggestions[index];
        return ListTile(
          leading: SizedBox(
            width: 50,
            height: 50,
            child: product.imageUrls.isNotEmpty 
              ? Image.network(product.imageUrls.first, fit: BoxFit.cover, 
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported))
              : const Icon(Icons.image_not_supported),
          ),
          title: Text(product.name),
          subtitle: Text('in ${product.category}', style: const TextStyle(color: Colors.grey)),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: product.id),
            ));
          },
        );
      },
    );
  }
}