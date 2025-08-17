// lib/model/cart_item_with_product.dart

// This class combines the cart item data with its corresponding product data.
class CartItemWithProduct {
  final int id; // The id of the cart entry itself
  final String userId;
  final String productId;
  final int quantity; // The quantity in the cart
  final String productName;
  final String? imageUrl;
  final double price;
  final int stockQuantity; // The available stock for the product

  CartItemWithProduct({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.productName,
    this.imageUrl,
    required this.price,
    required this.stockQuantity,
  });

  // A helper to check if the item is currently in stock
  bool get isInStock => stockQuantity > 0 && quantity <= stockQuantity;

  factory CartItemWithProduct.fromMap(Map<String, dynamic> map) {
    final productData = map['products'] as Map<String, dynamic>? ?? {};
    return CartItemWithProduct(
      id: map['id'],
      userId: map['user_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      productName: productData['product_name'] ?? 'Product Not Found',
      imageUrl: productData['image_url'],
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: productData['stock_quantity'] as int? ?? 0,
    );
  }
}