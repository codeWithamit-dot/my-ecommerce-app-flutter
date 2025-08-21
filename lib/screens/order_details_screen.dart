// Path: lib/screens/order_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_ecommerce_app/model/order_model.dart';
import 'package:my_ecommerce_app/services/order_service.dart';

class OrderDetailsScreen extends StatefulWidget { // Changed to StatefulWidget
  final Order order;
  final bool isSeller;

  const OrderDetailsScreen({super.key, required this.order, required this.isSeller});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderService _orderService = OrderService();
  late Order _currentOrder; // To hold mutable order state

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  // Seller ke liye: Status update karne ya tracking details daalne ka dialog
  void _showSellerUpdateDialog() {
    String selectedStatus = _currentOrder.status;
    final statusOptions = ['new', 'preparing', 'shipped', 'delivered', 'cancelled'];
    final courierController = TextEditingController(text: _currentOrder.courierCompany);
    final trackingIdController = TextEditingController(text: _currentOrder.trackingId);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Order'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedStatus = val);
                    },
                  ),
                  if (selectedStatus == 'shipped') ...[
                    const SizedBox(height: 16),
                    TextFormField(controller: courierController, decoration: const InputDecoration(labelText: 'Courier Company')),
                    TextFormField(controller: trackingIdController, decoration: const InputDecoration(labelText: 'Tracking ID')),
                  ] else if (selectedStatus == 'cancelled') ... [
                    const SizedBox(height: 16),
                    TextFormField(controller: trackingIdController, decoration: const InputDecoration(labelText: 'Reason for Cancellation')), // Reusing controller for reason
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(child: const Text('Close'), onPressed: () => Navigator.of(context).pop()),
              ElevatedButton(child: const Text('Save Changes'), onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  if (selectedStatus == 'cancelled') {
                    await _orderService.cancelOrderBySeller(orderId: _currentOrder.id, reason: trackingIdController.text);
                  } else {
                    await _orderService.updateOrderStatus(
                      orderId: _currentOrder.id, newStatus: selectedStatus,
                      courierCompany: courierController.text,
                      trackingId: trackingIdController.text
                    );
                  }
                  
                  navigator.pop();
                  messenger.showSnackBar(const SnackBar(content: Text('Order Updated!'), backgroundColor: Colors.green));
                  // Refresh the previous screen by popping with a result
                  Navigator.of(context).pop(true); // Return true to indicate a change
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              })
            ],
          );
        },
      ),
    );
  }
  
  // Buyer ke liye: Order cancel karne ka dialog
  void _showBuyerCancelDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: TextFormField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason for cancellation (optional)')
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go Back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Cancellation'), 
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                final result = await _orderService.cancelOrderByBuyer(orderId: _currentOrder.id, reason: reasonController.text);
                
                navigator.pop();
                
                if (result.toLowerCase().contains('success')) {
                  messenger.showSnackBar(const SnackBar(content: Text('Order Cancelled'), backgroundColor: Colors.green));
                   Navigator.of(context).pop(true); // Return true to indicate a change
                } else {
                   messenger.showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.orange));
                }

              } catch (e) {
                 messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            }
          ),
        ]
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${_currentOrder.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // If the user is a seller, show the buyer's full shipping details
          if (widget.isSeller) ...[
            _buildInfoCard('Buyer Details', [
              _buildDetailRow('Name:', _currentOrder.shippingAddress['name'] ?? 'N/A'),
              _buildDetailRow('Phone:', _currentOrder.shippingAddress['phone'] ?? 'N/A'),
              _buildDetailRow('Address:', '${_currentOrder.shippingAddress['address_line_1'] ?? ''}\n${_currentOrder.shippingAddress['address_line_2'] ?? ''}\n${_currentOrder.shippingAddress['pincode'] ?? ''}'),
            ]),
            const SizedBox(height: 16),
          ],
          
          _buildInfoCard('Order Summary', [
            _buildDetailRow('Order ID:', _currentOrder.id),
            _buildDetailRow('Order Date:', DateFormat('d MMM, yyyy').format(_currentOrder.createdAt)),
            _buildDetailRow('Status:', _currentOrder.status.toUpperCase()),
            _buildDetailRow('Total Amount:', '₹${_currentOrder.totalAmount.toStringAsFixed(2)}'),
            _buildDetailRow('Payment:', '${_currentOrder.paymentMethod.toUpperCase()} (${_currentOrder.paymentStatus.toUpperCase()})'),
            // Agar tracking ID hai to use dikhao
            if(_currentOrder.trackingId != null && _currentOrder.trackingId!.isNotEmpty)
              _buildDetailRow('Tracking ID:', _currentOrder.trackingId!),
          ]),
          const SizedBox(height: 16),
          _buildOrderItemsCard(context, _currentOrder.items),
          const SizedBox(height: 16),
          if (widget.isSeller)
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Manage Order"),
              onPressed: _showSellerUpdateDialog,
            )
          else
             ElevatedButton.icon(
              icon: const Icon(Icons.cancel),
              label: const Text("Cancel Order"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _currentOrder.status == 'new' || _currentOrder.status == 'preparing' ? _showBuyerCancelDialog : null,
            ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String title, List<Widget> details) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20, thickness: 1),
            ...details,
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard(BuildContext context, List<OrderItem> items) {
     return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text('Items in this Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const Divider(height: 20, thickness: 1),
             if (items.isEmpty)
              const ListTile(title: Text('No items found for this order.'))
             else 
              // ✅ FIX: unnecessary '.toList()' removed from the spread
              ...items.map((item) {
                final product = item.product;
                return ListTile(
                  leading: product.imageUrls.isNotEmpty 
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(product.imageUrls.first, width: 50, height: 50, fit: BoxFit.cover),
                        ) 
                      : const Icon(Icons.image_not_supported),
                  title: Text(product.name),
                  subtitle: Text('Price: ₹${item.pricePerItem.toStringAsFixed(2)}'),
                  trailing: Text('Qty: ${item.quantity}'),
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
          Text('$title ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}