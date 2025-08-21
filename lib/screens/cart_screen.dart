// Path: lib/screens/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/model/cart_item_with_product.dart';
import 'package:my_ecommerce_app/services/cart_service.dart';
import 'package:my_ecommerce_app/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  Future<List<CartItemWithProduct>>? _cartFuture;

  @override
  void initState() {
    super.initState();
    _fetchCartData();
  }
  
  void _fetchCartData() {
    setState(() {
      _cartFuture = _cartService.fetchCartItems();
    });
  }
  
  Future<void> _refreshCart() async {
    _fetchCartData();
  }

  void _updateQuantity(String cartItemId, int newQuantity) async {
    try {
      await _cartService.updateItemQuantity(cartItemId, newQuantity);
      _refreshCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shopping Cart'),
      ),
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _refreshCart,
        child: FutureBuilder<List<CartItemWithProduct>>(
          future: _cartFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Error: ${snapshot.error}"),
                ),
              );
            }
            final cartItems = snapshot.data ?? [];
            if (cartItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text("Your cart is empty.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text("Add some products to see them here."),
                  ],
                ),
              );
            }

            final double totalPrice = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
            final bool isCartValidForCheckout = cartItems.every((item) => item.isInStock);
            
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItemCard(cartItems[index]);
                    },
                  ),
                ),
                _buildCheckoutSection(context, totalPrice, isCartValidForCheckout),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildCartItemCard(CartItemWithProduct item) {
    final bool isOutOfStock = !item.isInStock;
    
    return Opacity(
      opacity: isOutOfStock ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(item.imageUrl, width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 40))
                  ),
                  if (isOutOfStock)
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: Colors.black.withAlpha(150), borderRadius: BorderRadius.circular(8)),
                      child: const Center(child: Text('OUT OF\nSTOCK', 
                        textAlign: TextAlign.center, 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.productName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                      decoration: isOutOfStock ? TextDecoration.lineThrough : TextDecoration.none), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("₹${item.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, color: Colors.green)),
                ])),
              Row(children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), 
                  onPressed: isOutOfStock ? null : () => _updateQuantity(item.id, item.quantity - 1), splashRadius: 20),
                Text(item.quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), 
                  onPressed: isOutOfStock ? null : () => _updateQuantity(item.id, item.quantity + 1), splashRadius: 20),
              ]),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCheckoutSection(BuildContext context, double totalPrice, bool isCartValid) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.1), blurRadius: 10, spreadRadius: 1)]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Total Price", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              FittedBox(fit: BoxFit.scaleDown,
                child: Text("₹${totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)))])),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
              backgroundColor: isCartValid ? Theme.of(context).primaryColor : Colors.grey, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: isCartValid ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())) : null,
            child: Text(isCartValid ? "Checkout" : "Unavailable", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}