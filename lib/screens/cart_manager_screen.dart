// lib/screens/cart_manager_screen.dart

import 'package:flutter/material.dart';

class CartManagerScreen extends StatelessWidget {
  const CartManagerScreen({super.key});

  // Dummy cart items for now
  final List<Map<String, dynamic>> cartItems = const [
    {
      'name': 'Wireless Earbuds',
      'price': 2499,
      'quantity': 1,
    },
    {
      'name': 'Sports Shoes',
      'price': 1799,
      'quantity': 2,
    },
    {
      'name': 'Cooking Pan Set',
      'price': 1299,
      'quantity': 1,
    },
  ];

  // ✅ UI UPDATE: Reusing the header style from CategoriesScreen
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

  Widget _buildCartItemCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.shopping_bag_outlined,
            color: Color(0xFF267873)),
        title: Text(
          item['name'],
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        subtitle: Text(
          '₹${item['price']}  •  Qty: ${item['quantity']}',
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('View details for ${item['name']}')),
          );
        },
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10), // Padding to avoid edge
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF267873),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () {
          // Navigate to checkout page
        },
        child: const Text(
          'Proceed to Checkout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ UI UPDATE: Removed Scaffold and AppBar, added background color to a Container
    return Container(
      color: const Color(0xFFE0F7F5),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ UI UPDATE: Added the styled header
              _buildSectionHeader('My Cart'),
              Expanded(
                // ✅ UI UPDATE: Handling empty cart case
                child: cartItems.isEmpty 
                  ? const Center(child: Text("Your cart is empty.", style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItemCard(context, cartItems[index]);
                    },
                  ),
              ),
              // ✅ UI UPDATE: Show checkout button only if cart has items
              if (cartItems.isNotEmpty)
                _buildCheckoutButton(),
            ],
          ),
        ),
      ),
    );
  }
}