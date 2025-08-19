// lib/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart'; 
import 'package:my_ecommerce_app/model/cart_item_with_product.dart';
import 'package:my_ecommerce_app/services/cart_service.dart';
import 'package:my_ecommerce_app/services/order_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();
  bool _isLoading = false;
  late final Future<Map<String, dynamic>> _dataFuture;
  late Razorpay _razorpay;
  
  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchCheckoutData();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }
  
  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("✅ PAYMENT SUCCESSFUL: ${response.paymentId}");
    _dataFuture.then((data) {
      final List<CartItemWithProduct> cartItems = data['cart_items']; 
      final Map<String, dynamic> profile = data['profile'];
      _createOrderInDatabase(cartItems, profile, response.paymentId!);
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("❌ PAYMENT FAILED: ${response.message}");
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red));
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("📦 EXTERNAL WALLET: ${response.walletName}");
  }
  
  Future<Map<String, dynamic>> _fetchCheckoutData() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) throw Exception("User is not logged in.");
    
    final cartItems = await _cartService.fetchCartItems(); 
    final profileData = await supabase.from('profiles').select('full_name, shipping_address_line1, shipping_address_line2, shipping_pincode, contact_number').eq('id', currentUser.id).single();
    
    return {'cart_items': cartItems, 'profile': profileData};
  }

  double _calculateTotal(List<CartItemWithProduct> cartItems) {
    return cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _startPayment(List<CartItemWithProduct> cartItems, Map<String, dynamic> profile) async {
    setState(() => _isLoading = true);
    final totalAmount = _calculateTotal(cartItems);
    final userEmail = supabase.auth.currentUser?.email ?? 'test@example.com';
    final userPhone = profile['contact_number'] as String? ?? '9999999999';

    final options = {
      'key': 'rzp_test_nK4gZg9kZ8XvQy',
      'amount': (totalAmount * 100).round(),
      'name': 'My E-Commerce App',
      'description': 'Order Payment',
      'prefill': {'contact': userPhone, 'email': userEmail},
    };
    
    try { _razorpay.open(options); } 
    catch (e) { debugPrint("Error opening Razorpay: $e"); if(mounted) setState(() => _isLoading = false); }
  }

  Future<void> _createOrderInDatabase(List<CartItemWithProduct> cartItems, Map<String, dynamic> profile, String paymentId) async {
    final totalAmount = _calculateTotal(cartItems);
    try {
      final List<Map<String, dynamic>> cartItemsForDb = cartItems.map((item) => {
          'product_id': item.productId, 'seller_id': item.sellerId,
          'quantity': item.quantity, 'price_per_item': item.price
      }).toList();
      final shippingAddress = {'name': profile['full_name'], 'address_line_1': profile['shipping_address_line1'],
        'address_line_2': profile['shipping_address_line2'], 'pincode': profile['shipping_pincode']};
      
      await _orderService.createOrder(cartItemsForDb: cartItemsForDb, totalAmount: totalAmount, shippingAddress: shippingAddress, paymentId: paymentId);
      await CartService.clearCart();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully!'), backgroundColor: Colors.green));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating order: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Your Order')),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData) return Center(child: Text('Error loading data: ${snapshot.error}'));
          
          final List<CartItemWithProduct> cartItems = snapshot.data!['cart_items']; 
          final Map<String, dynamic> profile = snapshot.data!['profile'];
          final double totalAmount = _calculateTotal(cartItems);

          return Column(
            children: [
              Expanded(
                child: ListView(padding: const EdgeInsets.all(12),
                  children: [
                    _buildSectionCard(title: 'Delivery Address',
                      child: Text('${profile['full_name'] ?? ''}\n${profile['shipping_address_line1'] ?? ''}\n${profile['shipping_address_line2'] ?? ''}\n${profile['shipping_pincode'] ?? ''}',
                        style: const TextStyle(fontSize: 16, height: 1.5))),
                    const SizedBox(height: 16),
                    _buildSectionCard(title: 'Order Summary', child: _buildOrderSummaryList(cartItems)),
                  ],
                ),
              ),
              _buildCheckoutBottomBar(totalAmount, cartItems, profile),
            ],
          );
        },
      )
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20), child,
        ],),
      ),
    );
  }

  Widget _buildOrderSummaryList(List<CartItemWithProduct> cartItems) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cartItems.length,
      separatorBuilder: (context, index) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4), Text('Qty: ${item.quantity}', style: TextStyle(color: Colors.grey[600])),
          ])),
          Text('₹${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600))]);},
    );
  }

  Widget _buildCheckoutBottomBar(double totalAmount, List<CartItemWithProduct> cartItems, Map<String, dynamic> profile) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16),
      // ✅ FINAL FIX: `const` and `withAlpha` ke saath
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 10,
            spreadRadius: 1
          )
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total Amount:', style: Theme.of(context).textTheme.titleLarge),
            Text('₹${totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor))]),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (_isLoading || cartItems.isEmpty) ? null : () => _startPayment(cartItems, profile),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Proceed to Pay', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}