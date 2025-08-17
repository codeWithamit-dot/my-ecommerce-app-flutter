// lib/screens/search_screen.dart

// ✅ FIXED PERMANENTLY: The import statement is 'dart:async' with a colon.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/products/product_detail_screen.dart';
import 'search_filters_screen.dart';

enum SortOption { relevance, priceAsc, priceDesc, ratingDesc }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Future<List<Map<String, dynamic>>>? _productsFuture;
  // The 'Timer' class comes from 'dart:async' and will now be recognized.
  Timer? _debounce;
  
  String? _selectedCategory;
  RangeValues? _selectedPriceRange;
  SortOption _currentSortOption = SortOption.relevance;
  
  @override
  void initState() {
    super.initState();
    _productsFuture = Future.value([]); 
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _productsFuture = Future.value([]));
      return;
    }
    
    dynamic queryBuilder = supabase
        .from('products')
        .select()
        .ilike('product_name', '%${query.trim()}%');

    if (_selectedCategory != null) {
      queryBuilder = queryBuilder.eq('category', _selectedCategory!);
    }
    if (_selectedPriceRange != null) {
      queryBuilder = queryBuilder.gte('price', _selectedPriceRange!.start);
      queryBuilder = queryBuilder.lte('price', _selectedPriceRange!.end);
    }
    
    switch (_currentSortOption) {
      case SortOption.priceAsc:
        queryBuilder = queryBuilder.order('price', ascending: true);
        break;
      case SortOption.priceDesc:
        queryBuilder = queryBuilder.order('price', ascending: false);
        break;
      case SortOption.ratingDesc:
        queryBuilder = queryBuilder.order('average_rating', ascending: false);
        break;
      case SortOption.relevance:
        break;
    }

    setState(() {
      _productsFuture = queryBuilder as Future<List<Map<String, dynamic>>>;
    });
  }
  
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _openFilterScreen() async {
    final newFilters = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (ctx) => SearchFiltersScreen(
        initialCategory: _selectedCategory,
        initialPriceRange: _selectedPriceRange,
      )),
    );

    if (newFilters != null) {
      setState(() {
        _selectedCategory = newFilters['category'];
        _selectedPriceRange = newFilters['priceRange'];
      });
      _performSearch(_searchController.text);
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
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Search for products...',
            hintStyle: TextStyle(color: Colors.white.withAlpha(200)),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: Column(
        children: [
          _buildControlsBar(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }
  
  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.filter_list),
            label: const Text('Filter'),
            onPressed: _openFilterScreen,
          ),
          DropdownButton<SortOption>(
            value: _currentSortOption,
            onChanged: (SortOption? newValue) {
              if (newValue != null) {
                setState(() => _currentSortOption = newValue);
                _performSearch(_searchController.text);
              }
            },
            items: const [
              DropdownMenuItem(value: SortOption.relevance, child: Text('Relevance')),
              DropdownMenuItem(value: SortOption.priceAsc, child: Text('Price: Low to High')),
              DropdownMenuItem(value: SortOption.priceDesc, child: Text('Price: High to Low')),
              DropdownMenuItem(value: SortOption.ratingDesc, child: Text('Highest Rated')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (_searchController.text.trim().isEmpty) {
            return const Center(child: Text('Search for products, brands and more.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Center(child: Text('No products found for "${_searchController.text}"'));
        }
        
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: SizedBox(
                width: 50, height: 50,
                child: Image.network(product['image_url'], fit: BoxFit.cover, errorBuilder: (_,__,___)=> const Icon(Icons.image)),
              ),
              title: Text(product['product_name']),
              subtitle: Text('\u20B9${product['price']}'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(productId: product['id']),
                ));
              },
            );
          },
        );
      },
    );
  }
}