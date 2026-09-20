import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../services/order_service.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _orderService = OrderService();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = _orderService.fetchAllOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'حصل خطأ:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'الطلبات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'تحديث',
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadOrders,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: orders.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد طلبات بعد',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadOrders(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            return _OrderCard(
                              order: orders[index],
                              orderService: _orderService,
                              onStatusChanged: _loadOrders,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  final OrderService orderService;
  final VoidCallback onStatusChanged;

  const _OrderCard({
    required this.order,
    required this.orderService,
    required this.onStatusChanged,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  late Future<List<OrderItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.orderService.fetchOrderItems(widget.order.id);
  }

  /// ⚠️ لازم ترجّع MaterialColor عشان نقدر نستخدم .shade700
  MaterialColor _statusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'confirmed':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    try {
      await widget.orderService.updateOrderStatus(
        orderId: widget.order.id,
        status: newStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث حالة الطلب'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onStatusChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحديث: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final shortId = o.id.split('-').first.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '#$shortId — ${o.customerName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              _statusBadge(o.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${o.phone} • ${o.governorate} - ${o.city}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${o.total.toStringAsFixed(2)} EGP • ${_formatDate(o.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'عنوان التوصيل:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(o.address, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 14),
                  const Text(
                    'المنتجات:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<List<OrderItem>>(
                    future: _itemsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return Text(
                          'خطأ في تحميل البنود: ${snap.error}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        );
                      }
                      final items = snap.data ?? [];
                      if (items.isEmpty) {
                        return const Text('لا توجد بنود');
                      }
                      return Column(
                        children: items
                            .map((item) => _buildItemRow(item))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تغيير الحالة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _buildStatusSelector(o),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.productName} × ${item.quantity}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '${(item.price * item.quantity).toStringAsFixed(2)} EGP',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(Order order) {
    const statuses = ['new', 'confirmed', 'cancelled', 'delivered'];
    const labels = {
      'new': 'جديد',
      'confirmed': 'مؤكد',
      'cancelled': 'ملغي',
      'delivered': 'تم التسليم',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((s) {
        final selected = order.status == s;
        final color = _statusColor(s);
        return ChoiceChip(
          label: Text(labels[s]!),
          selected: selected,
          onSelected: (_) {
            if (!selected) _changeStatus(s);
          },
          selectedColor: color.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: selected ? color.shade700 : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          side: BorderSide(color: selected ? color : Colors.grey.shade300),
        );
      }).toList(),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    final labels = {
      'new': 'جديد',
      'confirmed': 'مؤكد',
      'cancelled': 'ملغي',
      'delivered': 'تم التسليم',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labels[status] ?? status,
        style: TextStyle(
          fontSize: 11,
          color: color.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
