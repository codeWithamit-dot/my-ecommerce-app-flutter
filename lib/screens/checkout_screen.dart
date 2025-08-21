// Path: lib/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/model/cart_item_with_product.dart';
import 'package:my_ecommerce_app/model/coupon_model.dart';
import 'package:my_ecommerce_app/services/cart_service.dart';
import 'package:my_ecommerce_app/services/coupon_service.dart';
import 'package:my_ecommerce_app/services/order_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

enum PaymentMethod { cod, online }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Services
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();
  final CouponService _couponService = CouponService();
  
  // State
  late final Future<Map<String, dynamic>> _dataFuture;
  bool _isLoading = false;
  PaymentMethod _paymentMethod = PaymentMethod.online;

  // Razorpay
  late Razorpay _razorpay;

  // Coupon State
  final _couponController = TextEditingController();
  Coupon? _appliedCoupon;
  double _discountAmount = 0.0;
  String? _couponErrorText;
  bool _isCouponLoading = false;

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
    _couponController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("✅ PAYMENT SUCCESSFUL: ${response.paymentId}");
    _dataFuture.then((data) => _createOrderInDatabase(data: data, paymentStatus: 'paid'));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("❌ PAYMENT FAILED: ${response.message}");
    if (mounted) setState(() => _isLoading = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red));
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

  double _calculateSubtotal(List<CartItemWithProduct> cartItems) => cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  double _getGrandTotal(double subtotal) => (subtotal - _discountAmount) < 0 ? 0 : (subtotal - _discountAmount);

  Future<void> _applyCoupon(List<CartItemWithProduct> cartItems) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_couponController.text.trim().isEmpty) return;

    setState(() { _isCouponLoading = true; _couponErrorText = null; });
    try {
      final result = await _couponService.validateAndApplyCoupon(code: _couponController.text, cartItems: cartItems);
      setState(() {
        _discountAmount = result['discount_amount'];
        _appliedCoupon = result['coupon'];
      });
    } catch(e) {
      setState(() { _couponErrorText = e.toString().replaceFirst('Exception: ', ''); _discountAmount = 0.0; _appliedCoupon = null; });
    } finally {
      if(mounted) setState(() => _isCouponLoading = false);
    }
  }

  void _placeOrder(Map<String, dynamic> data) {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    if (_paymentMethod == PaymentMethod.cod) {
      _createOrderInDatabase(data: data, paymentStatus: 'unpaid');
    } else {
      _startRazorpayPayment(data['cart_items'], data['profile']);
    }
  }

  Future<void> _startRazorpayPayment(List<CartItemWithProduct> cartItems, Map<String, dynamic> profile) async {
    final subtotal = _calculateSubtotal(cartItems);
    final totalAmount = _getGrandTotal(subtotal);
    final userEmail = supabase.auth.currentUser?.email ?? 'test@example.com';
    final userPhone = profile['contact_number'] as String? ?? '9999999999';

    final options = {
      'key': 'rzp_test_KEY_ID', // Replace with your key
      'amount': (totalAmount * 100).round(),
      'name': 'My E-Commerce App',
      'prefill': {'contact': userPhone, 'email': userEmail},
    };
    try { _razorpay.open(options); } 
    catch (e) { 
      debugPrint("Error opening Razorpay: $e"); 
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createOrderInDatabase({required Map<String, dynamic> data, required String paymentStatus}) async {
    final subtotal = _calculateSubtotal(data['cart_items']);
    final totalAmount = _getGrandTotal(subtotal);
    final currentUserId = supabase.auth.currentUser!.id;
    final Map<String, dynamic> profile = data['profile'];
    final List<CartItemWithProduct> cartItems = data['cart_items'];

    try {
      final shippingAddress = { 'name': profile['full_name'], 'address_line_1': profile['shipping_address_line1'], 'address_line_2': profile['shipping_address_line2'], 'pincode': profile['shipping_pincode'], 'phone': profile['contact_number'] };
      await _orderService.createOrder(
        userId: currentUserId,
        totalAmount: totalAmount,
        shippingAddress: shippingAddress,
        paymentMethod: _paymentMethod.name,
        paymentStatus: paymentStatus,
        cartItems: cartItems,
      );
      await _cartService.clearCart();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully!'), backgroundColor: Colors.green));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating order: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm & Pay')),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) return Center(child: Text('Error: ${snapshot.error}'));

          final List<CartItemWithProduct> cartItems = snapshot.data!['cart_items'];
          final Map<String, dynamic> profile = snapshot.data!['profile'];
          final subtotal = _calculateSubtotal(cartItems);
          final grandTotal = _getGrandTotal(subtotal);

          if (cartItems.isEmpty) return const Center(child: Text("Your cart is empty."));

          return Column(children: [
              Expanded(child: ListView(padding: const EdgeInsets.all(12),
                  children: [
                    _buildSectionCard(title: 'Delivery Address', child: Text('${profile['full_name'] ?? ''}\n${profile['shipping_address_line1'] ?? ''}\n${profile['shipping_address_line2'] ?? ''}\n${profile['shipping_pincode'] ?? ''}')),
                    const SizedBox(height: 16),
                    _buildSectionCard(title: 'Payment Method', child: Column(children: [ 
                       RadioListTile<PaymentMethod>(title: const Text('Pay Online'), value: PaymentMethod.online, groupValue: _paymentMethod, onChanged: (v) => setState(()=>_paymentMethod=v!)),
                       RadioListTile<PaymentMethod>(title: const Text('Cash on Delivery'), value: PaymentMethod.cod, groupValue: _paymentMethod, onChanged: (v) => setState(()=>_paymentMethod=v!)),
                    ])),
                    const SizedBox(height: 16),
                    _buildCouponSection(cartItems),
                    const SizedBox(height: 16),
                    _buildSectionCard(title: 'Price Details', child: _buildPriceDetails(subtotal, _discountAmount, grandTotal)),
                  ],
                )),
              _buildCheckoutBottomBar(grandTotal, snapshot.data!),
          ]);
        },
      ));
  }
  
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          child,
        ]),
      ),
    );
  }
  
  Widget _buildCouponSection(List<CartItemWithProduct> cartItems) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apply Coupon', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
                Expanded(child: TextFormField(controller: _couponController, decoration: const InputDecoration(hintText: 'Enter Coupon Code', border: OutlineInputBorder()), textCapitalization: TextCapitalization.characters)),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isCouponLoading ? null : () => _applyCoupon(cartItems),
                  child: _isCouponLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3,)) : const Text('Apply'),
                ),
            ]),
            if (_couponErrorText != null && _couponErrorText!.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(_couponErrorText!, style: const TextStyle(color: Colors.red))),
            if (_appliedCoupon != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text('"${_appliedCoupon!.code}" applied! You saved ₹${_discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
          ],
        ),
      )
    );
  }

  Widget _buildPriceDetails(double subtotal, double discount, double grandTotal) {
    return Column(children: [
        _buildDetailRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
        if (discount > 0) 
          _buildDetailRow('Coupon Discount', '- ₹${discount.toStringAsFixed(2)}', color: Colors.green),
        const Divider(),
        _buildDetailRow('Grand Total', '₹${grandTotal.toStringAsFixed(2)}', isBold: true),
    ]);
  }
  
  Widget _buildDetailRow(String title, String value, {bool isBold = false, Color? color}) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.grey[700])),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color ?? Colors.black, fontSize: isBold ? 18 : 16)),
        ],
      ),
    );
  }

  Widget _buildCheckoutBottomBar(double totalAmount, Map<String, dynamic> data) {
    final cartItems = data['cart_items'] as List<CartItemWithProduct>;
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16),
      decoration: const BoxDecoration(
          color: Colors.white, boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 10, spreadRadius: 1)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Total Payable", style: TextStyle(color: Colors.grey, fontSize: 14)),
              Text("₹${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
            ])
          ),
          ElevatedButton(
            onPressed: (_isLoading || cartItems.isEmpty) ? null : () => _placeOrder(data),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                : Text(_paymentMethod == PaymentMethod.cod ? 'Place Order' : 'Proceed to Pay', style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}