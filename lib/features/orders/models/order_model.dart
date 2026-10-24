class OrderItemModel {
  final String id;
  final String name;
  final String imageUrl;
  final String details;
  final double price;
  final int quantity;

  const OrderItemModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.details,
    required this.price,
    required this.quantity,
  });
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final String placedDate;
  final String? deliveryDate;
  final double totalAmount;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.placedDate,
    this.deliveryDate,
    required this.totalAmount,
    required this.items,
  });
}
