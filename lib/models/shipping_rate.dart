class ShippingRate {
  final String id;
  final String governorate;
  final double shippingCost;
  final bool isActive;

  ShippingRate({
    required this.id,
    required this.governorate,
    required this.shippingCost,
    required this.isActive,
  });

  factory ShippingRate.fromMap(Map<String, dynamic> map) {
    return ShippingRate(
      id: map['id'] as String,
      governorate: map['governorate'] as String,
      shippingCost: (map['shipping_cost'] as num).toDouble(),
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
