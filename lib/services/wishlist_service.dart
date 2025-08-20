// lib/services/wishlist_service.dart

import '../main.dart'; // ✅ FINAL FIX: Import path ko theek kar diya gaya hai.

class WishlistService {
  
  Future<bool> isProductWishlisted(String productId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await supabase
        .from('wishlist')
        .select('id')
        .eq('buyer_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
        
    return response != null;
  }

  Future<void> addToWishlist(String productId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await supabase.from('wishlist').insert({
      'buyer_id': userId,
      'product_id': productId,
    });
  }

  Future<void> removeFromWishlist(String productId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await supabase
        .from('wishlist')
        .delete()
        .eq('buyer_id', userId)
        .eq('product_id', productId);
  }
}