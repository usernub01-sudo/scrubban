import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/coupon.dart';
import '../../services/coupon_service.dart';

class AdminCouponsPage extends StatefulWidget {
  const AdminCouponsPage({super.key});

  @override
  State<AdminCouponsPage> createState() => _AdminCouponsPageState();
}

class _AdminCouponsPageState extends State<AdminCouponsPage> {
  final _couponService = CouponService();
  late Future<List<Coupon>> _couponsFuture;

  // الحد الأقصى للكوبونات النشطة
  static const int maxActiveCoupons = 10;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  void _loadCoupons() {
    setState(() {
      _couponsFuture = _couponService.fetchAllCoupons();
    });
  }

  // ============================================================
  // Generate coupon dialog
  // ============================================================
  Future<void> _showGenerateDialog(int activeCount) async {
    // تحقق سريع قبل ما نفتح الـdialog
    if (activeCount >= maxActiveCoupons) {
      _showError(
        'وصلت للحد الأقصى ($maxActiveCoupons كوبونات نشطة). '
        'استنى لحد ما واحد يتفعّل أو احذف واحد.',
      );
      return;
    }

    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;
    String? dialogError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              title: const Text(
                'Generate Coupon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              content: SizedBox(
                width: 320,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Enter a discount percentage (1–100). The system will generate a random code automatically.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: controller,
                        enabled: !submitting,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Discount %',
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                          hintText: 'e.g. 10',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFBBBBBB),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Color(0xFFDDDDDD),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Color(0xFFDDDDDD),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Colors.black87,
                              width: 1.4,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: Colors.red, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: 1.4,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Discount is required';
                          }
                          final n = double.tryParse(v.trim());
                          if (n == null) return 'Must be a number';
                          if (n <= 0) return 'Must be greater than 0';
                          if (n > 100) return 'Cannot exceed 100';
                          return null;
                        },
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            dialogError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.black87,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            submitting = true;
                            dialogError = null;
                          });

                          try {
                            final percent = double.parse(
                              controller.text.trim(),
                            );
                            final coupon = await _couponService.createCoupon(
                              discountPercent: percent,
                            );

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Coupon created: ${coupon.code} '
                                  '(${coupon.discountPercent.toStringAsFixed(0)}% off)',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                backgroundColor: Colors.black87,
                                behavior: SnackBarBehavior.floating,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                            );
                            _loadCoupons();
                          } on PostgrestException catch (e) {
                            // الحد الأقصى للكوبونات النشطة
                            var msg = e.message;
                            if (msg.contains('Maximum 10 active coupons')) {
                              msg =
                                  'وصلت للحد الأقصى ($maxActiveCoupons كوبونات نشطة). '
                                  'مش هينفع تولّد أكتر لحد ما واحد يتفعّل.';
                            }
                            setDialogState(() {
                              submitting = false;
                              dialogError = msg;
                            });
                          } catch (e) {
                            setDialogState(() {
                              submitting = false;
                              dialogError = '$e';
                            });
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black87,
                          ),
                        )
                      : const Text(
                          'GENERATE',
                          style: TextStyle(
                            color: Colors.black87,
                            letterSpacing: 1.5,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  // ============================================================
  // Delete coupon
  // ============================================================
  Future<void> _confirmDelete(Coupon coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          'Delete coupon?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${coupon.code}"? '
          'This action cannot be undone.',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.black87,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'DELETE',
              style: TextStyle(
                color: Colors.red,
                letterSpacing: 1.5,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _couponService.deleteCoupon(coupon.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coupon ${coupon.code} deleted',
            style: const TextStyle(fontSize: 13, letterSpacing: 0.3),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
      _loadCoupons();
    } catch (e) {
      _showError('Delete failed: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 13, letterSpacing: 0.3),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Coupon>>(
        future: _couponsFuture,
        builder: (context, snapshot) {
          final coupons = snapshot.data ?? [];
          final activeCount = coupons.where((c) => !c.isUsed).length;
          final usedCount = coupons.where((c) => c.isUsed).length;

          return Column(
            children: [
              _buildToolbar(
                total: snapshot.hasData ? coupons.length : null,
                activeCount: activeCount,
                usedCount: usedCount,
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              Expanded(child: _buildBody(snapshot, activeCount)),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // Toolbar
  // ============================================================
  Widget _buildToolbar({
    required int? total,
    required int activeCount,
    required int usedCount,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Coupons',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                  fontFamily: 'Georgia',
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => _showGenerateDialog(activeCount),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'GENERATE COUPON',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stats row
          if (total != null)
            Row(
              children: [
                _buildStat(
                  icon: Icons.check_circle_outline,
                  label: '$activeCount active',
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 16),
                _buildStat(
                  icon: Icons.history,
                  label: '$usedCount used',
                  color: const Color(0xFF999999),
                ),
                const SizedBox(width: 16),
                _buildStat(
                  icon: Icons.flag_outlined,
                  label: 'limit: $activeCount / $maxActiveCoupons active',
                  color: activeCount >= maxActiveCoupons
                      ? Colors.red.shade700
                      : const Color(0xFF999999),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: color,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Body
  // ============================================================
  Widget _buildBody(AsyncSnapshot<List<Coupon>> snapshot, int activeCount) {
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
                'Failed to load coupons',
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

    final coupons = snapshot.data ?? [];
    if (coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              size: 56,
              color: Color(0xFFCCCCCC),
            ),
            const SizedBox(height: 16),
            const Text(
              'No coupons yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Click "Generate Coupon" to create one.',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: () => _showGenerateDialog(activeCount),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black87, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'GENERATE COUPON',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadCoupons(),
      color: Colors.black87,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          return _buildCouponRow(coupons[index]);
        },
      ),
    );
  }

  // ============================================================
  // Coupon Row
  // ============================================================
  Widget _buildCouponRow(Coupon coupon) {
    final isUsed = coupon.isUsed;
    final statusColor = isUsed
        ? const Color(0xFF999999)
        : Colors.green.shade700;
    final statusLabel = isUsed ? 'USED' : 'ACTIVE';

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUsed ? const Color(0xFFF7F7F7) : Colors.green.shade50,
              border: Border.all(
                color: isUsed ? const Color(0xFFEEEEEE) : Colors.green.shade200,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              isUsed
                  ? Icons.check_circle_outline
                  : Icons.confirmation_number_outlined,
              size: 20,
              color: isUsed ? const Color(0xFF999999) : Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Code
                    SelectableText(
                      coupon.code,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isUsed
                            ? const Color(0xFF999999)
                            : Colors.black87,
                        letterSpacing: 1.5,
                        decoration: isUsed ? TextDecoration.lineThrough : null,
                        decorationColor: const Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${coupon.discountPercent.toStringAsFixed(0)}% off '
                  '• created ${_formatDate(coupon.createdAt)}'
                  '${isUsed && coupon.usedAt != null ? ' • used ${_formatDate(coupon.usedAt!)}' : ''}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),

          // Delete
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red.shade400,
            onPressed: () => _confirmDelete(coupon),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Helpers
  // ============================================================
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
