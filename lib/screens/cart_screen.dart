// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/model/cart_item_with_product.dart';
import 'package:my_ecommerce_app/services/cart_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  late Future<List<CartItemWithProduct>> _cartFuture;
  
  final TextEditingController _couponController = TextEditingController();
  double _discountPercent = 0;
  // This bool will be controlled by the FutureBuilder to enable/disable the checkout button.
  bool _isCartValidForCheckout = true; 

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }
  
  void _refreshCart() {
    setState(() {
      _cartFuture = _cartService.getCartItemsWithProductDetails();
      // Reset coupon on refresh
      _couponController.clear();
      _discountPercent = 0;
    });
  }

  // --- WIDGET BUILDERS ---

  Widget _buildCartItem(CartItemWithProduct item, {required VoidCallback onRemove}) {
    final bool isOutOfStock = !item.isInStock;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      color: isOutOfStock ? Colors.grey[200] : Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty) 
                ? Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                : Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
            ),
            title: Text(
              item.productName,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                decoration: isOutOfStock ? TextDecoration.lineThrough : TextDecoration.none,
                color: isOutOfStock ? Colors.grey[600] : Colors.black87,
              ),
            ),
            subtitle: Text("₹${item.price} x ${item.quantity}"),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[700]),
              onPressed: onRemove,
              tooltip: 'Remove item',
            ),
          ),
          if (isOutOfStock)
            Container(
              decoration: BoxDecoration(
                // ✅ FIXED: Replaced deprecated withOpacity with withAlpha
                color: Colors.black.withAlpha(128),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('OUT OF STOCK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            )
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: RefreshIndicator(
        onRefresh: () async => _refreshCart(),
        child: FutureBuilder<List<CartItemWithProduct>>(
          future: _cartFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            final cartItems = snapshot.data ?? [];
            if (cartItems.isEmpty) {
              return const Center(child: Text("Your cart is empty."));
            }

            final double totalPrice = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
            final double discountedTotal = totalPrice * (1 - _discountPercent / 100);
            
            _isCartValidForCheckout = cartItems.every((item) => item.isInStock);
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        return _buildCartItem(
                          cartItems[index],
                          onRemove: () async {
                             await _cartService.removeItemFromCart(cartItems[index].id);
                             _refreshCart();
                          }
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckoutSection(totalPrice, discountedTotal),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildCheckoutSection(double totalPrice, double discountedTotal) {
    // ✅ FIXED: Apply coupon logic moved here and renamed.
    void applyCoupon() {
        if (_couponController.text.trim().toLowerCase() == "save10") {
            setState(() => _discountPercent = 10);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coupon 'SAVE10' applied!")));
        } else {
            setState(() => _discountPercent = 0);
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid coupon.")));
        }
        // Hide keyboard after applying
        FocusScope.of(context).unfocus();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 10
            )
        ]
      ),
      child: Column(
        children: [
          // ✅ FIXED: Coupon UI restored here.
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                ),
                onPressed: applyCoupon, // Calls the local function
                child: const Text('Apply'),
              ),
            ],
          ),

          const Divider(height: 24),

          // Display Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("₹${discountedTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          
          const SizedBox(height: 10),

          // Checkout Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: _isCartValidForCheckout ? Theme.of(context).primaryColor : Colors.grey[500],
            ),
            onPressed: _isCartValidForCheckout
              ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen()))
              : null, 
            child: Text(
              _isCartValidForCheckout ? "Proceed to Checkout" : "Remove out of stock items",
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}