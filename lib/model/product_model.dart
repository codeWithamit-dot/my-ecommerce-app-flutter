// Path: lib/model/product_model.dart

class Product {
  final String id;
  final String name;
  final double price;
  final String sellerId;
  final String description;
  final String category;
  final int? stockQuantity;
  final double? averageRating;
  final List<String> imageUrls;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.sellerId,
    required this.description,
    required this.category,
    this.stockQuantity,
    this.averageRating,
    this.imageUrls = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final imageUrlsData = json['image_urls'] as List?;
    final imageUrlsList = imageUrlsData?.map((e) => e.toString()).toList() ?? [];

    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'N/A',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      sellerId: json['seller_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      stockQuantity: json['stock_quantity'] as int?,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      imageUrls: imageUrlsList,
    );
  }
}