// lib/services/order_service.dart

import 'package:flutter/foundation.dart'; // ✅ FINAL FIX: The import is corrected. This will solve all errors.
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final _client = Supabase.instance.client;

  Future<void> createOrder({
    required List<Map<String, dynamic>> cartItemsForDb,
    required double totalAmount,
    required Map<String, dynamic> shippingAddress,
    required String paymentId,
  }) async {
    try {
      await _client.rpc('create_new_order', params: {
        'p_user_id': _client.auth.currentUser!.id,
        'p_total_amount': totalAmount,
        'p_shipping_address': shippingAddress,
        'p_payment_id': paymentId,
        'p_cart_items': cartItemsForDb,
      });
    } catch (e) {
      debugPrint('Error creating order: $e');
      throw Exception('Could not create order.');
    }
  }
  
  Future<List<Map<String, dynamic>>> fetchBuyerOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      return await _client
          .from('orders')
          .select('*, order_items ( *, products ( name ) )')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    } catch (e) {
      debugPrint('Error fetching buyer orders: $e');
      throw Exception('Could not fetch your order history.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSellerOrders() async {
    final sellerId = _client.auth.currentUser?.id;
    if (sellerId == null) return [];
    
    try {
      final orderItemsResponse = await _client
          .from('order_items')
          .select('order_id')
          .eq('seller_id', sellerId);
      
      if (orderItemsResponse.isEmpty) return [];

      final orderIds = orderItemsResponse.map((item) => item['order_id']).toSet().toList();

      if (orderIds.isEmpty) return [];

      // Using the filter method which is stable across versions.
      return await _client
          .from('orders')
          .select()
          .filter('id', 'in', orderIds)
          .order('created_at', ascending: false);
          
    } catch (e) {
      debugPrint('Error fetching seller orders: $e');
      throw Exception('Could not fetch your new orders.');
    }
  }
  
  Future<void> updateOrderStatus({required int orderId, required String newStatus}) async {
    try {
        await _client.from('orders').update({'status': newStatus}).eq('id', orderId);
    } catch(e) {
        debugPrint('Error updating order status: $e');
        throw Exception('Could not update order status.');
    }
  }
}