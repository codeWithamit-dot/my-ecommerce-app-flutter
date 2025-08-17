// lib/models/coupon.dart
class Coupon {
  final String code;
  final double discountPercent; // e.g., 10% discount = 10.0
  final DateTime expiryDate;

  Coupon({
    required this.code,
    required this.discountPercent,
    required this.expiryDate,
  });

  bool get isValid => DateTime.now().isBefore(expiryDate);

  Map<String, dynamic> toJson() => {
        'code': code,
        'discountPercent': discountPercent,
        'expiryDate': expiryDate.toIso8601String(),
      };

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        code: json['code'],
        discountPercent: json['discountPercent'],
        expiryDate: DateTime.parse(json['expiryDate']),
      );
}
