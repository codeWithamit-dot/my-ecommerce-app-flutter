// lib/services/cart_service.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/model/cart_item_with_product.dart';

class CartService {
  // Fetches all cart items for the current user and joins them with product data.
  Future<List<CartItemWithProduct>> getCartItemsWithProductDetails() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await supabase
          .from('cart')
          // The `*` selects all columns from `cart`,
          // and `products(*)` selects all columns from the joined `products` table.
          .select('*, products(*)') 
          .eq('user_id', userId);
          
      return response.map((item) => CartItemWithProduct.fromMap(item)).toList();
    } catch (e) {
      debugPrint("Error fetching cart items: $e");
      throw Exception("Could not load cart.");
    }
  }

  // Removes a single item from the cart.
  Future<void> removeItemFromCart(int cartItemId) async {
      await supabase.from('cart').delete().eq('id', cartItemId);
  }

  // Your existing static method to clear the entire cart after an order.
  static Future<void> clearCart() async {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase.from('cart').delete().eq('user_id', userId);
  }
}