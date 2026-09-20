class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isActive,
  });

  /// تحويل الـJSON اللي جاي من Supabase لـProduct object
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
