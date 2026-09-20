import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  /// ينشئ طلب جديد مع بنوده (عبر RPC).
  /// يرجّع الـorder_id الجديد.
  Future<String> createOrder({
    required String customerName,
    required String phone,
    required String governorate,
    required String city,
    required String address,
    required List<OrderItem> items,
    String? couponCode,
  }) async {
    final result = await _client.rpc(
      'create_order_with_items',
      params: {
        'p_customer_name': customerName,
        'p_phone': phone,
        'p_governorate': governorate,
        'p_city': city,
        'p_address': address,
        'p_items': items.map((e) => e.toRpcJson()).toList(),
        'p_coupon_code': couponCode,
      },
    );

    return result as String;
  }

  /// يجيب كل الطلبات (للأدمن فقط — محمي بـRLS)
  Future<List<Order>> fetchAllOrders() async {
    final data = await _client
        .from('orders')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map((item) => Order.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// يجيب بنود طلب معين
  Future<List<OrderItem>> fetchOrderItems(String orderId) async {
    final data = await _client
        .from('order_items')
        .select()
        .eq('order_id', orderId);

    return (data as List)
        .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// يغيّر حالة الطلب
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _client.from('orders').update({'status': status}).eq('id', orderId);
  }
}
