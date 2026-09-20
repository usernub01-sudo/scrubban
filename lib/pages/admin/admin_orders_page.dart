import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          return Column(
            children: [
              _buildToolbar(snapshot.data?.length),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              Expanded(child: _buildBody(snapshot)),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // Toolbar
  // ============================================================
  Widget _buildToolbar(int? count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Orders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count == null
                    ? 'Loading...'
                    : '$count ${count == 1 ? 'order' : 'orders'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'REFRESH',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black87, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Body
  // ============================================================
  Widget _buildBody(AsyncSnapshot<List<Order>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.black87,
          ),
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 44,
                color: Color(0xFF999999),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load orders',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            ],
          ),
        ),
      );
    }

    final orders = snapshot.data ?? [];
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Color(0xFFCCCCCC),
            ),
            SizedBox(height: 16),
            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Orders will appear here when customers place them.',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadOrders(),
      color: Colors.black87,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _OrderRow(
            order: orders[index],
            orderService: _orderService,
            onStatusChanged: _loadOrders,
          );
        },
      ),
    );
  }
}

// ============================================================
// Order Row (expandable)
// ============================================================
class _OrderRow extends StatefulWidget {
  final Order order;
  final OrderService orderService;
  final VoidCallback onStatusChanged;

  const _OrderRow({
    required this.order,
    required this.orderService,
    required this.onStatusChanged,
  });

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  late Future<List<OrderItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.orderService.fetchOrderItems(widget.order.id);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue.shade700;
      case 'confirmed':
        return Colors.orange.shade700;
      case 'delivered':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return const Color(0xFF999999);
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
        SnackBar(
          content: Text(
            'Order status updated to ${_statusLabel(newStatus)}',
            style: const TextStyle(fontSize: 13, letterSpacing: 0.3),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
      widget.onStatusChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Update failed: $e',
            style: const TextStyle(fontSize: 13, letterSpacing: 0.3),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'new':
        return 'New';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }

  // ============================================================
  // Open WhatsApp
  // ============================================================
  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('0')) {
      digits = '20${digits.substring(1)}';
    } else if (digits.length == 10 && digits.startsWith('1')) {
      digits = '20$digits';
    }

    final uri = Uri.parse('https://wa.me/$digits');

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open WhatsApp',
              style: TextStyle(fontSize: 13),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: const TextStyle(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final shortId = o.id.split('-').first.toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '#$shortId',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _statusBadge(o.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${o.phone} • ${o.governorate}, ${o.city}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${o.total.toStringAsFixed(2)} EGP • ${_formatDate(o.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          children: [
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 20),

            // WhatsApp button
            _buildWhatsAppButton(o),

            const SizedBox(height: 24),

            // Delivery address
            _buildSectionLabel('DELIVERY ADDRESS'),
            const SizedBox(height: 8),
            Text(
              o.address,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Items
            _buildSectionLabel('ITEMS'),
            const SizedBox(height: 8),
            FutureBuilder<List<OrderItem>>(
              future: _itemsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black26,
                      ),
                    ),
                  );
                }
                if (snap.hasError) {
                  return Text(
                    'Failed to load items: ${snap.error}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Text(
                    'No items',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  );
                }
                return Column(
                  children: items.map((item) => _buildItemRow(item)).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // ⭐ Payment summary (subtotal, discount, shipping, total)
            _buildSectionLabel('PAYMENT SUMMARY'),
            const SizedBox(height: 10),
            _buildPaymentSummary(o),

            const SizedBox(height: 24),

            // Status selector
            _buildSectionLabel('UPDATE STATUS'),
            const SizedBox(height: 12),
            _buildStatusSelector(o),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Payment Summary
  // ============================================================
  Widget _buildPaymentSummary(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        children: [
          // Subtotal
          _buildSummaryRow(
            'Subtotal',
            '${order.subtotal.toStringAsFixed(2)} EGP',
          ),

          // Discount (if any)
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 10),
            _buildSummaryRow(
              order.couponCode != null && order.couponCode!.isNotEmpty
                  ? 'Discount (${order.couponCode})'
                  : 'Discount',
              '- ${order.discountAmount.toStringAsFixed(2)} EGP',
              valueColor: Colors.green.shade700,
            ),
          ],

          const SizedBox(height: 10),
          // Shipping
          _buildSummaryRow(
            'Shipping${order.governorate.isNotEmpty ? ' (${order.governorate})' : ''}',
            '${order.shippingCost.toStringAsFixed(2)} EGP',
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 14),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${order.total.toStringAsFixed(2)} EGP',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF666666)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WhatsApp Button
  // ============================================================
  Widget _buildWhatsAppButton(Order order) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => _openWhatsApp(context, order.phone),
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: Text(
          'CHAT ON WHATSAPP · ${order.phone}',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.5,
        color: Color(0xFF999999),
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.productName} × ${item.quantity}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Text(
            '${(item.price * item.quantity).toStringAsFixed(2)} EGP',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(Order order) {
    const statuses = ['new', 'confirmed', 'delivered', 'cancelled'];
    const labels = {
      'new': 'New',
      'confirmed': 'Confirmed',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((s) {
        final selected = order.status == s;
        final color = _statusColor(s);

        return InkWell(
          onTap: () {
            if (!selected) _changeStatus(s);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.08) : Colors.white,
              border: Border.all(
                color: selected ? color : const Color(0xFFDDDDDD),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Text(
              labels[s]!.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: selected ? color : const Color(0xFF666666),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    final label = _statusLabel(status).toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
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
