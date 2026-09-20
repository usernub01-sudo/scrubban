import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;

  /// يجيب كل المنتجات الـ active (اللي العميل يشوفها)
  Future<List<Product>> fetchActiveProducts() async {
    final data = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (data as List)
        .map((item) => Product.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// يجيب منتج واحد بالـid (هنستخدمها في صفحة التفاصيل)
  Future<Product?> fetchProductById(String id) async {
    final data = await _client
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Product.fromMap(data);
  }

  /// يجيب **كل** المنتجات (للأدمن — الـactive والـinactive)
  Future<List<Product>> fetchAllProducts() async {
    final data = await _client
        .from('products')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map((item) => Product.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// يحذف منتج
  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  /// يضيف منتج جديد ويرجّع الـid بتاعه
  Future<String> createProduct({
    required String name,
    required String description,
    required double price,
    required bool isActive,
    String? imageUrl,
  }) async {
    final data = await _client
        .from('products')
        .insert({
          'name': name,
          'description': description,
          'price': price,
          'image_url': imageUrl,
          'is_active': isActive,
        })
        .select()
        .single();

    return data['id'] as String;
  }

  /// يعدّل منتج موجود (هنستخدمها في 7.4)
  Future<void> updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    required bool isActive,
    String? imageUrl,
  }) async {
    await _client
        .from('products')
        .update({
          'name': name,
          'description': description,
          'price': price,
          'image_url': imageUrl,
          'is_active': isActive,
        })
        .eq('id', id);
  }
}
