// lib/models/cart_item.dart
class CartItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;

  CartItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'price': price,
        'imageUrl': imageUrl,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'],
        name: json['name'],
        quantity: json['quantity'],
        price: json['price'],
        imageUrl: json['imageUrl'],
      );
}
