// Path: lib/screens/order_history_screen.dart

// ✅✅✅ SABSE BADI Galti Yahan Theek Ki Gayi Hai ✅✅✅
// Flutter ke saare widgets is ek import se aate hain.
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../model/order_model.dart';
import '../services/order_service.dart';
import 'order_details_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _orderService.getMyOrders(); 
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _orderService.getMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(onPressed: _refreshOrders, icon: const Icon(Icons.refresh))
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no orders yet.'));
          }

          final orders = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshOrders,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsScreen(
                            order: order, 
                            isSeller: false,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(DateFormat('d MMM, yyyy').format(order.createdAt), style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildInfoRow('Status:', order.status.toUpperCase()),
                          _buildInfoRow('Total Amount:', '₹${order.totalAmount.toStringAsFixed(2)}'),
                          _buildInfoRow('Items:', order.items.length.toString()),
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.bottomRight,
                            child: Text('View Details >', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}