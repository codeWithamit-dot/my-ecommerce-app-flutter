// lib/services/payment_service.dart

// ------------------- FINAL, CORRECTED, 100% FULL PAGE CODE -------------------

import 'package:flutter/foundation.dart'; // <<<--- Sirf is ek import ki zaroorat hai
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  // Instance ko nullable banaya gaya hai
  Razorpay? _razorpay;
  
  // Callback functions
  VoidCallback? _onSuccess;
  ValueChanged<String>? _onError;

  // Constructor
  PaymentService() {
    // Sirf mobile par hi Razorpay ko initialize karo aur listeners lagao
    if (!kIsWeb) {
      _razorpay = Razorpay();
      
      // --- YAHAN HAI ASLI, FINAL FIX ---
      // Listeners ab is 'if' block ke andar hain. Isse woh kabhi bhi null
      // _razorpay par call nahi honge.
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }
  
  void dispose() {
    _razorpay?.clear(); // Null check (?) zaroori hai
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("✅ PAYMENT SUCCESSFUL: ID - ${response.paymentId}");
    _onSuccess?.call();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final errorMessage = response.message ?? "An unknown payment error occurred.";
    debugPrint("❌ PAYMENT FAILED: Code - ${response.code}, Message - $errorMessage");
    _onError?.call(errorMessage);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("💰 EXTERNAL WALLET used: ${response.walletName}");
  }
  
  void openCheckout({
    required double amount,
    required String orderDescription,
    required Map<String, dynamic> prefill,
    required VoidCallback onPaymentSuccess,
    required ValueChanged<String> onPaymentError,
  }) {
    _onSuccess = onPaymentSuccess;
    _onError = onPaymentError;
    
    if (kIsWeb || _razorpay == null) {
      onPaymentError("Payments are not supported on this platform.");
      return;
    }

    final amountInPaisa = (amount * 100).toInt();

    final Map<String, dynamic> options = {
      'key': 'YOUR_KEY_ID_HERE', // <<<<<<< YAHAN APNA RAZORPAY KEY ID DAALO
      'amount': amountInPaisa,
      'name': 'My E-Commerce App',
      'description': orderDescription,
      'timeout': 120, 
      'prefill': prefill,
    };
    
    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay checkout: ${e.toString()}");
      onPaymentError("Could not launch payment window. Please try again.");
    }
  }
}