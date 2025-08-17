// lib/screens/store_screen.dart
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';

class StoreScreen extends StatefulWidget {
  final String sellerId;
  const StoreScreen({super.key, required this.sellerId});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _sellerData;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    try {
      final seller = await supabase.from('profiles').select().eq('id', widget.sellerId).single();
      final products = await supabase.from('products').select().eq('seller_id', widget.sellerId);

      if (mounted) {
        setState(() {
          _sellerData = seller;
          _products = List<Map<String, dynamic>>.from(products);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading seller: ${e.toString()}')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_sellerData?['store_name'] ?? 'Store')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seller Info
                  Text(
                    _sellerData?['store_name'] ?? '',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_sellerData?['about_business'] ?? '', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),

                  // Products
                  const Text('Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: product['image_url'] != null
                              ? Image.network(product['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                              : const Icon(Icons.image_not_supported),
                          title: Text(product['name'] ?? ''),
                          subtitle: Text('₹${product['price'] ?? 'N/A'}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Product detail page ka link
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
