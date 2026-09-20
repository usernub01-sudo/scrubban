import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shipping_rate.dart';

class ShippingService {
  final SupabaseClient _client = Supabase.instance.client;

  /// كل المحافظات النشطة (للـCheckout)
  Future<List<ShippingRate>> fetchActiveRates() async {
    final data = await _client
        .from('shipping_rates')
        .select()
        .eq('is_active', true)
        .order('governorate');

    return (data as List)
        .map((item) => ShippingRate.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// كل المحافظات (للأدمن — حتى الغير نشطة)
  Future<List<ShippingRate>> fetchAllRates() async {
    final data = await _client
        .from('shipping_rates')
        .select()
        .order('governorate');

    return (data as List)
        .map((item) => ShippingRate.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// تعديل سعر شحن محافظة
  Future<void> updateRate({
    required String id,
    required double shippingCost,
    required bool isActive,
  }) async {
    await _client
        .from('shipping_rates')
        .update({'shipping_cost': shippingCost, 'is_active': isActive})
        .eq('id', id);
  }
}
