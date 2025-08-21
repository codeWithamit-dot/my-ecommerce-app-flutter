// Path: lib/services/coupon_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/coupon_model.dart';
import '../model/cart_item_with_product.dart';

class CouponService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createSellerCoupon({
    required String code,
    required String discountType,
    required double discountValue,
    double minPurchaseAmount = 0.0,
    DateTime? validUntil,
  }) async {
    final sellerId = _supabase.auth.currentUser?.id;
    if (sellerId == null) throw const AuthException('User must be logged in to create a coupon.');
    final newCoupon = {
      'code': code.toUpperCase().trim(),
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_purchase_amount': minPurchaseAmount,
      'valid_until': validUntil?.toIso8601String(),
      'seller_id': sellerId,
    };
    try {
      await _supabase.from('coupons').insert(newCoupon);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('This coupon code already exists. Please choose another one.');
      }
      throw Exception('Database Error: ${e.message}');
    }
  }

  Future<List<Coupon>> fetchMySellerCoupons() async {
    final sellerId = _supabase.auth.currentUser?.id;
    if (sellerId == null) return [];
    try {
      final response = await _supabase
          .from('coupons')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return response.map((json) => Coupon.fromJson(json)).toList();
    } catch(e) {
      debugPrint("Error fetching seller coupons: $e");
      throw Exception("Could not fetch your coupons.");
    }
  }
  
  Future<List<Coupon>> fetchCouponsBySeller(String sellerId) async {
    try {
      final response = await _supabase
          .from('coupons')
          .select()
          .eq('seller_id', sellerId)
          .eq('is_active', true)
          .or('valid_until.is.null,valid_until.gt.${DateTime.now().toIso8601String()}'); // Expired coupons mat dikhao
      return response.map((json) => Coupon.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetching coupons by seller ID: $e");
      return [];
    }
  }

  Future<void> updateCouponStatus(String couponId, bool isActive) async {
     try {
       await _supabase
          .from('coupons')
          .update({'is_active': isActive})
          .eq('id', couponId);
     } catch(e) {
       debugPrint("Error updating coupon status: $e");
       throw Exception("Could not update coupon status.");
     }
  }

  Future<Map<String, dynamic>> validateAndApplyCoupon({
    required String code,
    required List<CartItemWithProduct> cartItems
  }) async {
    if (code.trim().isEmpty) throw Exception("Please enter a coupon code.");
    final response = await _supabase
      .from('coupons')
      .select()
      .eq('code', code.toUpperCase().trim())
      .maybeSingle();

    if (response == null) throw Exception("Invalid coupon code.");
    
    final coupon = Coupon.fromJson(response);
    if (!coupon.isActive) throw Exception("This coupon is not active.");
    if (coupon.validUntil != null && coupon.validUntil!.isBefore(DateTime.now())) throw Exception("This coupon has expired.");

    double applicableAmount = 0;
    if (coupon.sellerId != null) {
      applicableAmount = cartItems.where((item) => item.sellerId == coupon.sellerId).fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    } else {
      applicableAmount = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    }
    
    if (applicableAmount <= 0) throw Exception("This coupon is not applicable to any items in your cart.");
    if (applicableAmount < coupon.minPurchaseAmount) throw Exception("A minimum purchase of ₹${coupon.minPurchaseAmount.toStringAsFixed(0)} on eligible items is required.");
    
    double discountAmount = 0;
    if (coupon.discountType == 'percentage') {
      discountAmount = (applicableAmount * coupon.discountValue) / 100;
    } else {
      discountAmount = coupon.discountValue;
    }

    // Ensure discount isn't more than the applicable amount
    if(discountAmount > applicableAmount) {
      discountAmount = applicableAmount;
    }

    return {'discount_amount': discountAmount, 'coupon': coupon};
  }
}