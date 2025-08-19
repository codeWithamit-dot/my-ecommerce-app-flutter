// lib/screens/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart'; // supabase ko use karne ke liye
import 'product_list_screen.dart'; // nayi screen ko import kiya

class CategoriesScreen extends StatefulWidget {
  // ✅ Isko StatefulWidget mein badal diya taaki data fetch kar sakein
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Future variable banaya data fetch karne ke liye
  late final Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchUniqueCategories();
  }

  // ✅ YEH HAI NAYA MAGIC FUNCTION!
  // Yeh `live_products` table se saari unique categories laayega.
  Future<List<String>> _fetchUniqueCategories() async {
    try {
      final response = await supabase
          .from('live_products')
          .select('category'); // Saari categories laayega, duplicates Dart mein hatayenge

      // Supabase se mila data List<Map<String, dynamic>> jaisa hota hai
      final categories = response
          .map((item) => item['category'] as String)
          .where((category) => category.isNotEmpty) // Khali categories ko ignore karo
          .toSet() // `toSet()` se duplicates apne aap hat jaate hain
          .toList();

      return categories;
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Shop by Category'), // Title update kiya
              Expanded(
                // ✅ Ab hum FutureBuilder use kar rahe hain
                child: FutureBuilder<List<String>>(
                  future: _categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final categories = snapshot.data ?? [];
                    if (categories.isEmpty) {
                      return const Center(child: Text("No product categories found."));
                    }
                    
                    return ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryCard(context, categories[index]);
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

  // --- UI Helper Widgets (onTap ka logic badla hai) ---

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF267873), borderRadius: BorderRadius.circular(8)),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String category) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.label_important_outline, color: Color(0xFF267873)),
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        // ✅ FIX: Ab yeh SnackBar ke bajaye ProductListScreen par le jaayega
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => ProductListScreen(categoryName: category),
            ),
          );
        },
      ),
    );
  }
}