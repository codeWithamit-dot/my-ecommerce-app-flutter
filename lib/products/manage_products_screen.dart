// lib/products/manage_products_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_ecommerce_app/products/edit_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  // --- No changes to your logic or functions ---
  Future<List<Map<String, dynamic>>> _fetchSellerProducts() {
    final userId = supabase.auth.currentUser!.id;
    return supabase
        .from('products')
        .select()
        .eq('seller_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> _deleteProduct(int productId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
            'Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await supabase.from('products').delete().eq('id', productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green),
        );
        setState(() {});
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  // ✅ UI WIDGETS
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF267873),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SizedBox(
          width: 55,
          height: 55,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(product['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported)),
          ),
        ),
        title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Price: ₹${product['price']} • Stock: ${product['stock_quantity'] ?? 0}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => EditProductScreen(product: product)))
                .then((wasUpdated) { if (wasUpdated == true) setState(() {}); });
            } else if (value == 'delete') {
              _deleteProduct(product['id']);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete')),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ UI UPDATE: Themed AppBar and background color
      backgroundColor: const Color(0xFFE0F7F5),
      appBar: AppBar(
        title: const Text('Manage My Products'),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              _buildSectionHeader('Your Listed Products'),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchSellerProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return const Center(child: Text("You haven't added any products yet."));
                    }
                    
                    // ✅ UI UPDATE: Using the new styled card
                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(products[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}