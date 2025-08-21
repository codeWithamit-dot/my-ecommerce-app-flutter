// Path: lib/services/cart_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/cart_item_with_product.dart';

class CartService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Adds an item to the cart using the new bulletproof SQL function.
  Future<void> addItemToCart(String productId) async {
    try {
      // ✅ FIX: Calls the new, simpler function that handles everything on the backend.
      await _supabase.rpc(
        'add_item_to_cart',
        params: {
          'p_product_id': productId,
          'p_quantity': 1,
        }
      );
    } on PostgrestException catch(e) {
      debugPrint("Supabase error adding to cart: ${e.message}");
      throw Exception("Could not add item to cart. Please try again.");
    }
  }

  /// Fetches all cart items using the new bulletproof SQL function.
  Future<List<CartItemWithProduct>> fetchCartItems() async {
    try {
      // ✅ FIX: This now calls our reliable 'get_cart_items_for_user' function.
      final response = await _supabase.rpc('get_cart_items_for_user');
      final cartData = response as List;
      return cartData.map((item) => CartItemWithProduct.fromMap(item as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      debugPrint("❌ FAILED TO FETCH CART. Real Error: ${e.message}");
      throw Exception("Could not load your cart.");
    }
  }

  // The functions below are much simpler now because they don't need cartId.
  // The RLS policies we set up will handle security.

  Future<void> removeItemFromCart(String cartItemId) async {
    await _supabase.from('cart_items').delete().eq('id', cartItemId);
  }
  
  Future<void> updateItemQuantity(String cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItemFromCart(cartItemId);
    } else {
      await _supabase.from('cart_items').update({'quantity': newQuantity}).eq('id', cartItemId);
    }
  }

  Future<void> clearCart() async {
    // We get the cartId to be able to delete all items for the user's cart
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    final cartResponse = await _supabase.from('cart').select('id').eq('user_id', userId).single();
    final cartId = cartResponse['id'];

    if (cartId != null) {
      await _supabase.from('cart_items').delete().eq('cart_id', cartId);
    }
  }
}