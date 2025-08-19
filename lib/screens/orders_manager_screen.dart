// lib/screens/orders_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_ecommerce_app/providers/user_role_provider.dart';
import 'package:my_ecommerce_app/services/order_service.dart';
import 'package:provider/provider.dart';
import 'order_details_screen.dart';

class OrdersManagerScreen extends StatefulWidget {
  const OrdersManagerScreen({super.key});

  @override
  State<OrdersManagerScreen> createState() => _OrdersManagerScreenState();
}

class _OrdersManagerScreenState extends State<OrdersManagerScreen> {
  final OrderService _orderService = OrderService();
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }
  
  void _fetchOrders() {
    // Sahi role check kiya ja raha hai
    final isSeller = context.read<UserRoleProvider>().role == 'seller';
    setState(() {
      _ordersFuture = isSeller 
          ? _orderService.fetchSellerOrders() // Sahi function
          : _orderService.fetchBuyerOrders();  // Sahi function
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSeller = context.watch<UserRoleProvider>().role == 'seller';
    
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildSectionHeader(isSeller ? 'Orders Received' : 'My Purchase History'),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _fetchOrders(),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _ordersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Center(child: Text('An error occurred: ${snapshot.error}'));
                      final orders = snapshot.data ?? [];
                      if (orders.isEmpty) return const Center(child: Text('You have no orders yet.', style: TextStyle(fontSize: 16, color: Colors.grey)));

                      return ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(context, orders[index], isSeller: isSeller);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order, {required bool isSeller}) {
    final String status = order['status'] ?? 'Unknown';
    final int orderId = order['id'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        leading: Icon(isSeller ? Icons.inventory_2_outlined : Icons.receipt_long_outlined, color: _getStatusColor(status), size: 30),
        title: Text('Order #${orderId.toString()}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Date: ${DateFormat.yMMMd().format(DateTime.parse(order['created_at']))} • Total: ₹${(order['total_amount'] as num).toStringAsFixed(2)}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view_details') {
              // ✅ FIX: 'order' parameter pass kiya gaya hai
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(order: order),
              )).then((_) => _fetchOrders());
            } else if (value == 'update_status' && isSeller) {
              _showUpdateStatusDialog(status, orderId);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(value: 'view_details', child: Text('View Details')),
            if (isSeller) const PopupMenuItem<String>(value: 'update_status', child: Text('Update Status')),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF267873), borderRadius: BorderRadius.circular(8)),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
  
  void _showUpdateStatusDialog(String currentStatus, int orderId) {
    String? selectedStatus = currentStatus;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Update Order Status'),
          content: DropdownButton<String>(
            value: selectedStatus, isExpanded: true,
            items: ['Processing', 'Shipped', 'Delivered', 'Cancelled']
                .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                .toList(),
            onChanged: (value) => setDialogState(() => selectedStatus = value),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedStatus != null) {
                  Navigator.of(ctx).pop();
                  // ✅ FIX: orderId ka type int hi bheja jaa raha hai
                  await _orderService.updateOrderStatus(orderId: orderId, newStatus: selectedStatus!);
                  _fetchOrders();
                }
              }, child: const Text('Update'),
            ),
          ],
        );},
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Colors.green;
      case 'shipped': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'processing': return Colors.blue;
      default: return Colors.grey;
    }
  }
}