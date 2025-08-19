// lib/screens/order_history_screen.dart

import 'package:flutter/material.dart'; // ✅ FIX: Sabse zaroori import wapas add kar diya gaya hai.
import 'package:intl/intl.dart';
import 'package:my_ecommerce_app/screens/add_review_screen.dart';
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
      _ordersFuture = _orderService.fetchBuyerOrders();
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
  
  // ✅ FIX #2: Ab yeh function `sellerId` bhi leta hai
  Future<void> _navigateToAddReview(String productId, String productName, String sellerId) async {
    final reviewWasSubmitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (ctx) => AddReviewScreen(
        productId: productId,
        productName: productName,
        sellerId: sellerId, // sellerId pass kiya jaa raha hai
      )),
    );
    
    if (reviewWasSubmitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your review!')),
      );
    }
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
                final String orderId = order['id'].toString();
                final String status = order['status'] ?? 'Unknown';
                final DateTime date = DateTime.parse(order['created_at']);
                final double total = (order['total_amount'] as num).toDouble();
                final List items = order['order_items'] ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  child: ExpansionTile(
                    title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text("Order: #$orderId", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Chip(
                        label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        backgroundColor: _getStatusColor(status),
                      ),
                    ]),
                    subtitle: Text("Date: ${DateFormat.yMMMd().format(date)}"),
                    children: [
                      ...items.map((item) {
                        final productData = item['products'] as Map<String, dynamic>?;
                        final productName = productData?['name'] ?? 'Product not found';
                        final String productId = item['product_id'];
                        final String? sellerId = item['seller_id']; // `sellerId` order item se nikala

                        return Column(children: [
                            ListTile(
                              dense: true,
                              title: Text(productName),
                              subtitle: Text("Qty: ${item['quantity'] ?? 0}"),
                              trailing: Text("₹${((item['price_per_item'] as num? ?? 0.0) * (item['quantity'] as int? ?? 0)).toStringAsFixed(2)}"),
                            ),
                            if (status.toLowerCase() == 'delivered')
                              Padding(padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                                child: Align(alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                                    label: const Text('Write a Review'),
                                    onPressed: () {
                                      // ✅ FIX #3: Yahan call ko update kiya
                                      if (sellerId != null) {
                                        _navigateToAddReview(productId, productName, sellerId);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seller not found for this product.')));
                                      }
                                    },
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                      const Divider(indent: 16, endIndent: 16, height: 1),
                      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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