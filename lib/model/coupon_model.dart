// Path: lib/model/coupon_model.dart

class Coupon {
  final String id;
  final String code;
  final String discountType; // 'percentage' or 'fixed_amount'
  final double discountValue;
  final double minPurchaseAmount;
  final String? sellerId; // Nullable for admin coupons
  final bool isActive;
  final DateTime? validUntil;
  final DateTime createdAt;

  Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minPurchaseAmount,
    this.sellerId,
    required this.isActive,
    this.validUntil,
    required this.createdAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'],
      code: json['code'],
      discountType: json['discount_type'],
      discountValue: (json['discount_value'] as num).toDouble(),
      minPurchaseAmount: (json['min_purchase_amount'] as num).toDouble(),
      sellerId: json['seller_id'],
      isActive: json['is_active'],
      validUntil: json['valid_until'] != null ? DateTime.parse(json['valid_until']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}