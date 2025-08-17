// lib/services/coupon_service.dart
import 'package:my_ecommerce_app/model/coupon.dart';

class CouponService {
  // Example: Hardcoded coupons. Later can fetch from Supabase
  static final List<Coupon> _coupons = [
    Coupon(code: 'WELCOME10', discountPercent: 10, expiryDate: DateTime(2099)),
    Coupon(code: 'FLUTTER20', discountPercent: 20, expiryDate: DateTime(2099)),
  ];

  static Coupon? validateCoupon(String code) {
    try {
      final coupon = _coupons.firstWhere((c) => c.code == code);
      if (coupon.isValid) return coupon;
    } catch (_) {}
    return null;
  }
}
