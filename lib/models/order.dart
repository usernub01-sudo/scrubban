class Order {
  final String id;
  final String customerName;
  final String phone;
  final String governorate;
  final String city;
  final String address;
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
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

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
