// Path: lib/products/manage_products_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/screens/promotions/manage_coupons_screen.dart'; // ✅
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchSellerProducts();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _fetchSellerProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('products')
          .select()
          .eq('seller_id', userId)
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _allProducts = List<Map<String, dynamic>>.from(response);
          _filteredProducts = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching products: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }
  
  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final productName = product['name'] as String? ?? '';
        return productName.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteProduct(String productId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await supabase.from('products').delete().eq('id', productId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Colors.green));
      _fetchSellerProducts();
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red));
    }
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined), // Promotions / Coupons Icon
            tooltip: 'Manage Coupons',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageCouponsScreen())
              );
            },
          )
        ],
      ),
      backgroundColor: const Color(0xFFE0F7F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Search Your Products',
                  hintText: 'Enter product name...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                    : null,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchSellerProducts,
                child: _buildBodyContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allProducts.isEmpty) {
      return CustomScrollView(slivers: [
        SliverFillRemaining(child: Center(
          child: Text("You haven't added any products yet.",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600]))))]);
    }
    if (_filteredProducts.isEmpty) {
      return Center(child: Text('No products found for "${_searchController.text}"', 
        style: TextStyle(fontSize: 16, color: Colors.grey[600])));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_filteredProducts[index]);
      },
    );
  }
  
  Widget _buildProductCard(Map<String, dynamic> product) {
    final imageUrls = product['image_urls'] as List?;
    final firstImageUrl = (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls.first as String : null;
    final isApproved = product['is_approved'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            SizedBox(
              width: 80, height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: firstImageUrl != null
                    ? Image.network(firstImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported))
                    : const Icon(Icons.image_not_supported),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Price: ₹${product['price']} • Stock: ${product['stock_quantity'] ?? 0}'),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(isApproved ? 'Approved & Live' : 'Pending Review', style: const TextStyle(fontSize: 12)),
                    backgroundColor: isApproved ? Colors.green.shade100 : Colors.orange.shade100,
                    labelStyle: TextStyle(color: isApproved ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final wasUpdated = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => EditProductScreen(product: product)));
                  if (wasUpdated == true && mounted) {
                    _fetchSellerProducts();
                  }
                } else if (value == 'delete') {
                  _deleteProduct(product['id']);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'))),
                const PopupMenuItem<String>(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}