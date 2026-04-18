class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String shop;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.shop,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        menuItemId: json['menuItemId'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int,
        shop: json['shop'] as String,
      );

  factory OrderItem.fromSupabase(Map<String, dynamic> json) => OrderItem(
        menuItemId: json['menu_item_id'] as String? ?? '',
        name: json['item_name'] as String,
        price: (json['unit_price'] as num).toDouble(),
        quantity: json['quantity'] as int,
        shop: '',
      );

  Map<String, dynamic> toJson() => {
        'menuItemId': menuItemId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'shop': shop,
      };
}

class Order {
  final String id;
  final String studentId;
  final String studentName;
  final String shopId;
  final List<OrderItem> items;
  final double total;
  final String status;
  final String? cancelReason;
  final DateTime createdAt;
  final int estimatedMinutes;

  const Order({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.shopId,
    required this.items,
    required this.total,
    required this.status,
    this.cancelReason,
    required this.createdAt,
    required this.estimatedMinutes,
  });

  factory Order.fromSupabase(Map<String, dynamic> json) {
    final shopCode = (json['shops'] as Map?)?['shop_code'] as String? ??
        json['shop_id'] as String? ?? '';
    final items = (json['order_items'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromSupabase(e as Map<String, dynamic>))
        .toList();
    return Order(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: '',
      shopId: shopCode,
      items: items,
      total: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      cancelReason: json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['ordered_at'] as String),
      estimatedMinutes: 15,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String? ?? '',
        shopId: json['shopId'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toDouble(),
        status: json['status'] as String,
        cancelReason: json['cancelReason'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        estimatedMinutes: json['estimatedMinutes'] as int? ?? 15,
      );

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
