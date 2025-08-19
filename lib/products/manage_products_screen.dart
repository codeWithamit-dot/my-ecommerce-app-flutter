// lib/products/manage_products_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  // ✅ FIX #1: Future ko State variable banaya, taaki setState() se use refresh kar sakein.
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    // initState mein hi future ko pehli baar call kiya
    _productsFuture = _fetchSellerProducts();
  }

  Future<List<Map<String, dynamic>>> _fetchSellerProducts() {
    final userId = supabase.auth.currentUser!.id;
    return supabase
        .from('products')
        .select()
        .eq('seller_id', userId)
        .order('created_at', ascending: false);
  }
  
  // Naya refresh function
  Future<void> _refreshProducts() async {
    setState(() {
      _productsFuture = _fetchSellerProducts();
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

    if (shouldDelete != true) return;

    try {
      await supabase.from('products').delete().eq('id', productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Colors.green));
        _refreshProducts(); // List ko refresh karo
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F5),
      body: SafeArea(
        // ✅ FIX #2: RefreshIndicator ko body ka sabse upar ka widget banaya.
        child: RefreshIndicator(
          onRefresh: _refreshProducts,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return CustomScrollView(slivers: [
                  SliverFillRemaining(child: Center(
                    child: Text("You haven't added any products yet.\nTap the '+' icon to add one!",
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600]))))]);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(products[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // --- UI Helper Widgets ---
  
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
                  if (wasUpdated == true) {
                    _refreshProducts();
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