class OrderItem {
  final String? id;
  final String? orderId;
  final String? productId;
  final String productName;
  final double price;
  final int quantity;

  OrderItem({
    this.id,
    this.orderId,
    this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  /// للقراءة من Supabase (لما الأدمن يعرض الطلبات)
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String?,
      orderId: map['order_id'] as String?,
      productId: map['product_id'] as String?,
      productName: map['product_name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
    );
  }

  /// للإرسال لـSupabase (جوه الـRPC)
  Map<String, dynamic> toRpcJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
    };
  }
}
