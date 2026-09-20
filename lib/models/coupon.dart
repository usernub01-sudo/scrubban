class Coupon {
  final String id;
  final String code;
  final double discountPercent;
  final bool isUsed;
  final DateTime createdAt;
  final DateTime? usedAt;

  Coupon({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.isUsed,
    required this.createdAt,
    this.usedAt,
  });

  factory Coupon.fromMap(Map<String, dynamic> map) {
    return Coupon(
      id: map['id'] as String,
      code: map['code'] as String,
      discountPercent: (map['discount_percent'] as num).toDouble(),
      isUsed: map['is_used'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      usedAt: map['used_at'] != null
          ? DateTime.parse(map['used_at'] as String)
          : null,
    );
  }
}
