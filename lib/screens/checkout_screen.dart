// lib/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart'; 
import 'package:my_ecommerce_app/services/cart_service.dart';
import 'package:my_ecommerce_app/services/order_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // ✅ Import Razorpay

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;
  late final Future<Map<String, dynamic>> _dataFuture;

  // ✅ 1. Initialize Razorpay
  late Razorpay _razorpay;
  
  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchCheckoutData();
    
    // ✅ 2. Setup Razorpay instance and listeners
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }
  
  @override
  void dispose() {
    // ✅ 3. Always clear the Razorpay listeners
    _razorpay.clear();
    super.dispose();
  }

  // --- Razorpay Handlers ---

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("✅ PAYMENT SUCCESSFUL: ${response.paymentId}");
    // We get all the data needed for order creation and call the method here.
    _dataFuture.then((data) {
      final List cartData = data['cart_data']; 
      final Map<String, dynamic> profile = data['profile'];
      
      // Pass the REAL payment ID to our order creation function.
      _createOrderInDatabase(cartData, profile, response.paymentId!);
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("❌ PAYMENT FAILED: ${response.message}");
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red)
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("📦 EXTERNAL WALLET: ${response.walletName}");
    // You can handle this or just let the flow continue
  }
  
  // A single, robust function to fetch all necessary data.
  Future<Map<String, dynamic>> _fetchCheckoutData() async {
    // ... This function does not change ...
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) throw Exception("User is not logged in.");
    
    final cartResponse = await supabase.from('cart').select('*, products:product_id (*)').eq('user_id', currentUser.id);
    final profileData = await supabase.from('profiles').select('full_name, address, phone').eq('id', currentUser.id).single();
    
    return {'cart_data': cartResponse, 'profile': profileData};
  }

  // Calculate the total amount from the raw cart data.
  double _calculateTotal(List cartData) {
    // ... This function does not change ...
    if (cartData.isEmpty) return 0.0;
    return cartData.fold(0.0, (sum, item) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (item['quantity'] as int?) ?? 0;
      return sum + (price * quantity);
    });
  }

  // ✅ 4. The main "Place Order" button now triggers Razorpay, not direct order creation
  Future<void> _startPayment(List rawCartData, Map<String, dynamic> profile) async {
    setState(() => _isLoading = true);
    
    final totalAmount = _calculateTotal(rawCartData);
    final userEmail = supabase.auth.currentUser?.email ?? 'test@example.com';
    final userPhone = profile['phone'] as String? ?? '9999999999';

    // All currency values must be in the smallest unit (paise for INR).
    final amountInPaise = (totalAmount * 100).round();

    final options = {
      'key': 'rzp_test_nK4gZg9kZ8XvQy', // <-- IMPORTANT: Replace with YOUR Razorpay Key ID
      'amount': amountInPaise,
      'name': 'My E-Commerce App', // Your app's name
      'description': 'Order Payment',
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
      },
    };
    
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay: $e");
      setState(() => _isLoading = false);
    }
  }

  // ✅ 5. This is the new function that creates the order AFTER payment is successful.
  // It replaces your old `_placeOrder` function's logic.
  Future<void> _createOrderInDatabase(List rawCartData, Map<String, dynamic> profile, String paymentId) async {
    final totalAmount = _calculateTotal(rawCartData);

    try {
      final List<Map<String, dynamic>> cartItemsForDb = [];
      for(final item in rawCartData) {
        final product = item['products'] as Map<String, dynamic>?;
        if (product == null || product['user_id'] == null) {
          throw Exception("Product details missing for a cart item.");
        }
        cartItemsForDb.add({
          'product_id': item['product_id'], 'seller_id': product['user_id'],
          'quantity': item['quantity'], 'price': item['price']
        });
      }

      final shippingAddress = {'name': profile['full_name'], 'address': profile['address']};

      await _orderService.createOrder(
        cartItemsForDb: cartItemsForDb, 
        totalAmount: totalAmount, 
        shippingAddress: shippingAddress, 
        paymentId: paymentId // Using the REAL payment ID
      );

      await CartService.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!'), backgroundColor: Colors.green)
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating order: ${e.toString()}'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading checkout data: ${snapshot.error}'));
          }
          
          final data = snapshot.data!;
          final List cartData = data['cart_data']; 
          final Map<String, dynamic> profile = data['profile'];
          final double totalAmount = _calculateTotal(cartData);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Delivery address and order summary... (no changes here)
                Text('Delivery Address', style: Theme.of(context).textTheme.titleLarge),
                // ... (your existing UI)
                const SizedBox(height: 24),
                Text('Order Summary', style: Theme.of(context).textTheme.titleLarge),
                // ... (your existing UI)

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:', style: Theme.of(context).textTheme.headlineSmall),
                      Text('₹${totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).primaryColor)),
                    ],
                  ),
                ),
                ElevatedButton(
                  // ✅ The button now calls `_startPayment`
                  onPressed: (_isLoading || cartData.isEmpty) ? null : () => _startPayment(cartData, profile),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                      : const Text('Proceed to Pay', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ],
            ),
          );
        },
      )
    );
  }
}