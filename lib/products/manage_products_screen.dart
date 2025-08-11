// lib/products/manage_products_screen.dart
import 'package:flutter/material.dart'; // <<<--- YAHAN GALTI THEEK KI GAYI HAI
import 'package:my_ecommerce_app/main.dart'; // <<<--- YAHAN GALTI THEEK KI GAYI HAI
import 'package:my_ecommerce_app/products/edit_product_screen.dart'; // <<<--- YAHAN GALTI THEEK KI GAYI HAI

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
  }

  Future<List<Map<String, dynamic>>> _loadProducts() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('products')
        .select()
        .eq('seller_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _deleteProduct(String productId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await supabase.from('products').delete().eq('id', productId);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Product deleted successfully!')));
      
      if (mounted) {
        setState(() {
          _productsFuture = _loadProducts();
        });
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error deleting product: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage My Products')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          }
          final products = snapshot.data;
          if (products == null || products.isEmpty) {
            return const Center(child: Text('You have not added any products yet.'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final imageUrls = (product['image_urls'] as List?) ?? [];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: imageUrls.isNotEmpty
                      ? Image.network(imageUrls[0], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported))
                      : const Icon(Icons.image),
                  ),
                  title: Text(product['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price: ₹${product['price']}'),
                      Text('Stock: ${product['stock_quantity']} left'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (product['is_approved'] as bool? ?? false) ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (product['is_approved'] as bool? ?? false) ? 'Approved' : 'Pending Approval',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                           final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
                           );
                           if (result == true) {
                              setState(() { _productsFuture = _loadProducts(); });
                           }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                           showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Are you sure?'),
                                content: Text('Do you want to permanently delete "${product['name']}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('No')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _deleteProduct(product['id']);
                                    },
                                    child: const Text('Yes', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                           );
                        },
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