// Path: lib/model/order_model.dart

import 'product_model.dart'; // We only need this import

class Order {
  final String id;
  final DateTime createdAt;
  final String userId;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final Map<String, dynamic> shippingAddress; 
  final String? trackingId;
  final String? courierCompany;
  final List<OrderItem> items; 

  Order({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.shippingAddress,
    this.trackingId,
    this.courierCompany,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = <OrderItem>[];
    
    if (json['order_items'] != null && json['order_items'] is List) {
      itemsList = (json['order_items'] as List)
          .where((item) => item != null && item['product'] != null) 
          .map((itemJson) => OrderItem.fromJson(itemJson as Map<String, dynamic>))
          .toList();
    }
    
    return Order(
      id: json['id']?.toString() ?? 'ErrorID',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      userId: json['user_id'] ?? 'N/A',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0.0') ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'N/A',
      paymentStatus: json['payment_status'] ?? 'N/A',
      status: json['status'] ?? 'unknown',
      shippingAddress: (json['shipping_address'] is Map<String, dynamic>) 
          ? json['shipping_address'] 
          : {},
      trackingId: json['tracking_id'],
      courierCompany: json['courier_company'],
      items: itemsList,
    );
  }
}

class OrderItem {
  final String id;
  final int quantity;
  final double pricePerItem;
  final Product product;

  OrderItem({
    required this.id,
    required this.quantity,
    required this.pricePerItem,
    required this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? 'ErrorItemID',
      quantity: json['quantity'] as int? ?? 0,
      pricePerItem: double.tryParse(json['price_per_item']?.toString() ?? '0.0') ?? 0.0,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
    );
  }
}