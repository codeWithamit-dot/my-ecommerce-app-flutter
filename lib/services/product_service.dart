// Path: lib/services/product_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/product_model.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Supabase me banaye gaye naye, fast 'search_products' function ko call karta hai.
  Future<List<Product>> searchProducts(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      return [];
    }

    try {
      final response = await _supabase.rpc(
        'search_products',
        params: {'search_term': searchTerm.trim()},
      );

      final productList = (response as List)
          .map((data) => Product.fromJson(data as Map<String, dynamic>))
          .toList();

      return productList;
      
    } on PostgrestException catch (e) {
      debugPrint("Supabase error searching products: ${e.message}");
      return []; 
    } catch (e) {
      debugPrint("Generic error searching products: $e");
      return [];
    }
  }

  // Yahan aap future mein aur bhi product-related functions daal sakte hain.
}