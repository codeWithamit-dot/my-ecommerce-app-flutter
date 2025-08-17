// lib/model/order_model.dart
class OrderModel {
    // You can add more fields here later
    final String id;
    final double totalAmount;
    final String status;
    final DateTime createdAt;
    OrderModel({required this.id, required this.totalAmount, required this.status, required this.createdAt});
}