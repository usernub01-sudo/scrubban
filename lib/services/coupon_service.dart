import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coupon.dart';

class CouponService {
  final SupabaseClient _client = Supabase.instance.client;

  /// يجيب كل الكوبونات (للأدمن)
  Future<List<Coupon>> fetchAllCoupons() async {
    final data = await _client
        .from('coupons')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map((item) => Coupon.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// يولّد كود عشوائي (8 حروف وأرقام)
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();

    // 8 أحرف
    var seed = rand;
    for (var i = 0; i < 8; i++) {
      buffer.write(chars[seed % chars.length]);
      seed = seed ~/ 3 + (seed >> 2) + 7;
    }

    return buffer.toString();
  }

  /// يولّد كوبون جديد بنسبة خصم
  Future<Coupon> createCoupon({required double discountPercent}) async {
    if (discountPercent <= 0 || discountPercent > 100) {
      throw Exception('Discount must be between 1 and 100');
    }

    // حاول لحد 5 مرات لو الكود اتكرر
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generateCode();
      try {
        final data = await _client
            .from('coupons')
            .insert({'code': code, 'discount_percent': discountPercent})
            .select()
            .single();

        return Coupon.fromMap(data);
      } on PostgrestException catch (e) {
        // لو الكود اتكرر، جرّب تاني
        if (!e.message.toLowerCase().contains('duplicate')) {
          rethrow;
        }
      }
    }
    throw Exception('Could not generate unique code. Try again.');
  }

  /// يحذف كوبون
  Future<void> deleteCoupon(String id) async {
    await _client.from('coupons').delete().eq('id', id);
  }

  /// يتحقق من كوبون (يُستخدم من صفحة Checkout)
  /// يرجّع نسبة الخصم لو صالح، أو null لو غلط
  Future<double?> validateCoupon(String code) async {
    if (code.trim().isEmpty) return null;

    final result = await _client.rpc(
      'validate_coupon',
      params: {'p_code': code.trim()},
    );

    // النتيجة List of maps: [{discount_percent: X, is_valid: true/false}]
    if (result is List && result.isNotEmpty) {
      final row = result.first as Map<String, dynamic>;
      final isValid = row['is_valid'] as bool? ?? false;
      if (isValid) {
        return (row['discount_percent'] as num).toDouble();
      }
    }
    return null;
  }
}
