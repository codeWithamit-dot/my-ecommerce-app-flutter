// Path: lib/services/order_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/cart_item_with_product.dart';
import '../model/order_model.dart'; 

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> createOrder({
    required String userId,
    required double totalAmount,
    required String paymentMethod,
    required String paymentStatus,
    required Map<String, dynamic> shippingAddress,
    required List<CartItemWithProduct> cartItems,
  }) async {
    try {
      final orderItemsData = cartItems.map((cartItem) => {
        'product_id': cartItem.productId, 'quantity': cartItem.quantity,
        'price_per_item': cartItem.price, 'seller_id': cartItem.sellerId,
      }).toList();
      final orderData = {
        'user_id': userId, 'total_amount': totalAmount,
        'payment_method': paymentMethod, 'payment_status': paymentStatus,
        'shipping_address': shippingAddress, 'order_items_data': orderItemsData,
      };
      final response = await _supabase.rpc('create_new_order', params: { 'order_data': orderData });
      final newOrderId = response.toString();
      if (newOrderId.isEmpty || newOrderId == 'null') {
        throw Exception("Order creation failed: No Order ID returned.");
      }
      return newOrderId;
    } on PostgrestException catch (e) {
      throw Exception("Database error: ${e.message}");
    } catch (e) {
      throw Exception("An unknown error occurred while creating order: $e");
    }
  }

  Future<List<Order>> getMyOrders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await _supabase.rpc('get_orders_for_buyer', params: {'p_user_id': userId});
      final dataList = response as List;
      return dataList.map((json) => Order.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("❌ Error fetching buyer orders: $e");
      throw Exception("Could not load your orders.");
    }
  }

  Future<List<Order>> getSellerOrders() async {
    final sellerId = _supabase.auth.currentUser?.id;
    if (sellerId == null) return [];
    try {
      final response = await _supabase.rpc('get_orders_for_seller', params: {'p_seller_id': sellerId});
      final dataList = response as List;
      return dataList.map((json) => Order.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("❌ Error fetching seller orders: $e");
      throw Exception("Could not load seller orders.");
    }
  }
  
  /// Seller ke liye order status aur tracking details update karna.
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? trackingId,
    String? courierCompany,
  }) async {
    try {
      final updates = {'status': newStatus};
      if (newStatus == 'shipped' && trackingId != null && courierCompany != null) {
        updates['tracking_id'] = trackingId;
        updates['courier_company'] = courierCompany;
      }
      
      await _supabase.from('orders').update(updates).eq('id', int.parse(orderId));
    } on PostgrestException catch (e) {
      throw Exception("Database Error: ${e.message}");
    }
  }

  /// NAYA FUNCTION: Buyer ke liye order cancel karna.
  Future<String> cancelOrderByBuyer({required String orderId, required String reason}) async {
    try {
      final response = await _supabase.rpc(
        'cancel_order_by_buyer',
        params: {'p_order_id': int.parse(orderId), 'p_reason': reason},
      );
      return response as String;
    } catch (e) {
      debugPrint("Error cancelling order by buyer: $e");
      throw Exception("Could not cancel the order.");
    }
  }

  /// NAYA FUNCTION: Seller ke liye order cancel karna.
  Future<String> cancelOrderBySeller({required String orderId, required String reason}) async {
    try {
      final response = await _supabase.rpc(
        'cancel_order_by_seller',
        params: {'p_order_id': int.parse(orderId), 'p_reason': reason},
      );
      return response as String;
    } catch (e) {
      debugPrint("Error cancelling order by seller: $e");
      throw Exception("Could not cancel the order.");
    }
  }
}