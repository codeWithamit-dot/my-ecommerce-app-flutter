// lib/screens/order_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  // ✅ FIXED: Renamed parameter from 'orderData' to match the calling screen
  final Map<String, dynamic> order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final shippingInfo = order['shipping_address'] as Map<String, dynamic>? ?? {};
    final List items = order['order_items'] ?? [];
    
    return Scaffold(
      appBar: AppBar(title: Text('Order #${order['id'].toString().substring(0, 8).toUpperCase()}')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoCard('Order Summary', [
            _buildDetailRow('Order ID:', order['id']),
            _buildDetailRow('Order Date:', DateFormat.yMMMd().format(DateTime.parse(order['created_at']))),
            _buildDetailRow('Status:', (order['status'] as String? ?? 'N/A').toUpperCase()),
            _buildDetailRow('Total Amount:', '₹${(order['total_amount'] as num).toStringAsFixed(2)}'),
          ]),
          const SizedBox(height: 20),
          _buildInfoCard('Shipping Address', [
            _buildDetailRow('Customer Name:', shippingInfo['name'] ?? 'N/A'),
            _buildDetailRow('Address:', shippingInfo['address'] ?? 'Not Provided'),
          ]),
          const SizedBox(height: 20),
          _buildOrderItemsCard(context, items),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String title, List<Widget> details) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...details,
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard(BuildContext context, List items) {
     return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text('Order Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const Divider(),
             if (items.isEmpty)
              const ListTile(title: Text('Item details not available.'))
             else 
              ...items.map((item) {
                final productData = item['products'] as Map<String, dynamic>?;
                final productName = productData?['product_name'] ?? 'Product not found';
                return ListTile(
                  title: Text(productName),
                  trailing: Text('Qty: ${item['quantity']}'),
                );
              })
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}