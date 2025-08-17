// lib/screens/order_history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_ecommerce_app/screens/add_review_screen.dart'; // ✅ Import the new screen
import 'package:my_ecommerce_app/services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = _orderService.fetchUserOrders();
    });
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

  // ✅ New helper function to navigate to the Add Review screen
  void _navigateToAddReview(String productId, String productName) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => AddReviewScreen(
        productId: productId,
        productName: productName,
      )),
    ).then((reviewWasSubmitted) {
      // Optional: You could show a message or refresh something here if needed.
      if (reviewWasSubmitted == true) {
        // Potentially refresh data if you want to show that review is complete.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order History & Tracking")),
      body: RefreshIndicator(
        onRefresh: () async => _refreshOrders(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error fetching orders: ${snapshot.error}"));
            }

            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return const Center(child: Text("You haven't placed any orders yet."));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final String orderId = order['id'].toString().substring(0, 8).toUpperCase();
                final String status = order['status'] ?? 'Unknown';
                final DateTime date = DateTime.parse(order['created_at']);
                final double total = (order['total_amount'] as num).toDouble();
                final List items = order['order_items'] ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Order: #$orderId", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Chip(
                          label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          backgroundColor: _getStatusColor(status),
                        ),
                      ],
                    ),
                    subtitle: Text("Date: ${DateFormat.yMMMd().format(date)}"),
                    children: [
                      ...items.map((item) {
                        final productData = item['products'] as Map<String, dynamic>?;
                        final productName = productData?['product_name'] ?? 'Product not found';
                        
                        // IMPORTANT: Ensure you are selecting 'product_id' in your `order_items` fetch
                        final String productId = item['product_id'];

                        return Column(
                          children: [
                            ListTile(
                              dense: true,
                              title: Text(productName),
                              subtitle: Text("Qty: ${item['quantity'] ?? 0}"),
                              trailing: Text("₹${((item['price'] as num?)?.toDouble() ?? 0.0 * (item['quantity'] as int? ?? 0)).toStringAsFixed(2)}"),
                            ),

                            // ✅ NEW: The conditional "Write a Review" button
                            if (status.toLowerCase() == 'delivered')
                              Padding(
                                padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                                    label: const Text('Write a Review'),
                                    onPressed: () => _navigateToAddReview(productId, productName),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                      const Divider(indent: 16, endIndent: 16, height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}