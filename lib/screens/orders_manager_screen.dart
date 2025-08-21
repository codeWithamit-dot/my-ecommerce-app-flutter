import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/model/order_model.dart';
import 'package:my_ecommerce_app/services/order_service.dart';
import 'package:my_ecommerce_app/screens/order_details_screen.dart'; // ✅ Import the details screen

class OrdersManagerScreen extends StatefulWidget {
  const OrdersManagerScreen({super.key});

  @override
  _OrdersManagerScreenState createState() => _OrdersManagerScreenState();
}

class _OrdersManagerScreenState extends State<OrdersManagerScreen> {
  final OrderService _orderService = OrderService();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _orderService.getSellerOrders();
  }
  
  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _orderService.getSellerOrders();
    });
  }

  // We are removing the _showUpdateStatusDialog from this screen
  // because this logic is now handled inside OrderDetailsScreen.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Your Orders'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshOrders)
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${snapshot.error}'),
            ));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no new orders.'));
          } else {
            final orders = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refreshOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final sellerItemCount = order.items.length;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text('Order #${order.id}'),
                      subtitle: Text('Items: $sellerItemCount - Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
                      trailing: Chip(
                        label: Text(order.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: _getStatusColor(order.status),
                      ),
                      // ✅✅✅ THE MAIN FIX IS HERE ✅✅✅
                      // Now, tapping this will open the detailed screen
                      onTap: () async {
                        // We wait for the details screen to pop
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(
                              order: order,
                              isSeller: true, // Tell the screen a seller is viewing it
                            ),
                          )
                        );
                        // If the result is true, it means an update happened, so refresh the list
                        if (result == true && mounted) {
                           _refreshOrders();
                        }
                      },
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'new': return Colors.blue;
      case 'preparing': return Colors.orange;
      case 'shipped': return Colors.indigo;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}