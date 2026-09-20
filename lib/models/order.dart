class Order {
  final String id;
  final String customerName;
  final String phone;
  final String governorate;
  final String city;
  final String address;
  final double subtotal;
  final double discountAmount;
  final double shippingCost;
  final String? couponCode;
  final double total;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.governorate,
    required this.city,
    required this.address,
    required this.subtotal,
    required this.discountAmount,
    required this.shippingCost,
    this.couponCode,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      customerName: map['customer_name'] as String,
      phone: map['phone'] as String,
      governorate: map['governorate'] as String,
      city: map['city'] as String,
      address: map['address'] as String,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      shippingCost: (map['shipping_cost'] as num?)?.toDouble() ?? 0,
      couponCode: map['coupon_code'] as String?,
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// نص عربي للحالة
  String get statusLabel {
    switch (status) {
      case 'new':
        return 'جديد';
      case 'confirmed':
        return 'مؤكد';
      case 'cancelled':
        return 'ملغي';
      case 'delivered':
        return 'تم التسليم';
      default:
        return status;
    }
  }
}
