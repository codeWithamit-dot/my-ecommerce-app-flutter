// Path: lib/model/cart_item_with_product.dart

class CartItemWithProduct {
  final String id; // This is the id from the cart_items table
  final int quantity;

  // These details now come directly from the joined 'products' table via the SQL function
  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final int stockQuantity;
  final String sellerId;

  CartItemWithProduct({
    required this.id,
    required this.quantity,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.stockQuantity,
    required this.sellerId,
  });
  
  // A handy getter to check if the item is in stock
  bool get isInStock => stockQuantity > 0;

  // ✅ FIX: This factory now correctly parses the "flat" JSON from our new SQL function
  factory CartItemWithProduct.fromMap(Map<String, dynamic> map) {
    return CartItemWithProduct(
      id: map['id'] ?? '',
      quantity: map['quantity'] as int? ?? 0,
      productId: map['productId'] ?? '',       // Key name changed to match function
      productName: map['productName'] ?? 'N/A',  // Key name changed to match function
      imageUrl: map['imageUrl'] ?? '',          // Key name changed to match function
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: map['stockQuantity'] as int? ?? 0, // Key name changed to match function
      sellerId: map['sellerId'] ?? '',          // Key name changed to match function
    );
  }
}