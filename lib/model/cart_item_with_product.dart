// lib/model/cart_item_with_product.dart

class CartItemWithProduct {
  final String id;
  final String productId;
  final int quantity;
  
  final String productName;
  final String imageUrl;
  final double price;
  final int stockQuantity;
  final String sellerId; // ✅ FIX: Sabse zaroori `sellerId` yahan add kiya gaya hai.

  CartItemWithProduct({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.stockQuantity,
    required this.sellerId,
  });
  
  bool get isInStock => stockQuantity > 0;

  factory CartItemWithProduct.fromMap(Map<String, dynamic> map) {
    // Ab `products` ke bajaye `live_products` se join ho raha hai
    final productData = map['products'] as Map<String, dynamic>?; 
    final imageUrls = productData?['image_urls'] as List?;

    return CartItemWithProduct(
      id: map['id'],
      productId: map['product_id'],
      quantity: map['quantity'] as int,
      productName: productData?['name'] ?? 'Product not available',
      imageUrl: (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls.first as String : '',
      price: (productData?['price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: productData?['stock_quantity'] as int? ?? 0,
      sellerId: productData?['seller_id'] ?? '', // ✅ `sellerId` ko bhi data se nikala
    );
  }
}