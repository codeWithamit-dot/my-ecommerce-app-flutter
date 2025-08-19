// lib/services/cart_service.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import '../model/cart_item_with_product.dart';

class CartService {
  
  // ✅ FIX: 'static' yahan se hata diya gaya hai
  Future<List<CartItemWithProduct>> fetchCartItems() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await supabase
          .from('cart')
          .select('*, products(*)') 
          .eq('buyer_id', userId);
          
      return response.map((item) => CartItemWithProduct.fromMap(item)).toList();
    } catch (e) {
      debugPrint("Error fetching cart items: $e");
      throw Exception("Could not load cart.");
    }
  }

  Future<void> removeItemFromCart(String cartItemId) async {
      await supabase.from('cart').delete().eq('id', cartItemId);
  }
  
  Future<void> updateItemQuantity(String cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItemFromCart(cartItemId);
    } else {
      await supabase.from('cart').update({'quantity': newQuantity}).eq('id', cartItemId);
    }
  }

  static Future<void> clearCart() async {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase.from('cart').delete().eq('buyer_id', userId);
  }
}