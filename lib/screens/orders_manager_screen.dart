// lib/screens/orders_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_ecommerce_app/services/order_service.dart';
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
    setState(() {
      _ordersFuture = _orderService.fetchSellerOrders();
    });
  }
  
  // UI helper from CategoriesScreen
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF267873),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // Your existing functions, no changes needed here.
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Colors.green;
      case 'shipped': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'processing': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _showUpdateStatusDialog(String currentStatus, String orderId) {
    String? selectedStatus = currentStatus;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Order Status'),
            content: DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              items: ['processing', 'shipped', 'delivered', 'cancelled']
                  .map((status) => DropdownMenuItem(value: status, child: Text(status.toUpperCase())))
                  .toList(),
              onChanged: (value) => setDialogState(() => selectedStatus = value),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedStatus != null) {
                    Navigator.of(ctx).pop();
                    await _orderService.updateOrderStatus(orderId: orderId, newStatus: selectedStatus!);
                    _fetchOrders();
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ FIX: Rebuilt the card to be a clean ListTile with a PopupMenuButton
  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final String status = order['status'] ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: Icon(Icons.receipt_long_outlined, color: _getStatusColor(status), size: 30),
        title: Text(
          'Order #${order['id'].toString().substring(0, 8).toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${DateFormat.yMMMd().format(DateTime.parse(order['created_at']))} • Total: ₹${(order['total_amount'] as num).toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            Chip(
              label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              backgroundColor: _getStatusColor(status),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        isThreeLine: true,
        // ✅ FIX: Actions are now inside a clean popup menu
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view_details') {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(order: order),
              )).then((_) => _fetchOrders());
            } else if (value == 'update_status') {
              _showUpdateStatusDialog(status, order['id']);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'view_details',
              child: Text('View Details'),
            ),
            const PopupMenuItem<String>(
              value: 'update_status',
              child: Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE0F7F5),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('My Orders'),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _fetchOrders(),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _ordersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('An error occurred: ${snapshot.error}'));
                      }
                      final orders = snapshot.data ?? [];
                      if (orders.isEmpty) {
                        return const Center(
                          child: Text(
                            'You have no orders yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(context, orders[index]);
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
}