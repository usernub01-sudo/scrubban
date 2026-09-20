import 'package:flutter/material.dart';

import '../../models/shipping_rate.dart';
import '../../services/shipping_service.dart';

class AdminShippingPage extends StatefulWidget {
  const AdminShippingPage({super.key});

  @override
  State<AdminShippingPage> createState() => _AdminShippingPageState();
}

class _AdminShippingPageState extends State<AdminShippingPage> {
  final _shippingService = ShippingService();
  late Future<List<ShippingRate>> _ratesFuture;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  void _loadRates() {
    setState(() {
      _ratesFuture = _shippingService.fetchAllRates();
    });
  }

  // ============================================================
  // Edit rate dialog
  // ============================================================
  Future<void> _showEditDialog(ShippingRate rate) async {
    final controller = TextEditingController(
      text: rate.shippingCost.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    bool saving = false;
    bool isActive = rate.isActive;
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
              title: Text(
                rate.governorate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              content: SizedBox(
                width: 320,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shipping cost
                      TextFormField(
                        controller: controller,
                        enabled: !saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Shipping Cost (EGP)',
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                          hintText: 'e.g. 50',
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
                            return 'Cost is required';
                          }
                          final n = double.tryParse(v.trim());
                          if (n == null) return 'Must be a number';
                          if (n < 0) return 'Cannot be negative';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Active toggle
                      InkWell(
                        onTap: saving
                            ? null
                            : () => setDialogState(() => isActive = !isActive),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFDDDDDD),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Available for delivery',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isActive
                                          ? 'Customers can select this governorate'
                                          : 'Hidden from checkout',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 40,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.black87
                                      : const Color(0xFFDDDDDD),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  alignment: isActive
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                  onPressed: saving ? null : () => Navigator.pop(ctx),
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
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            saving = true;
                            dialogError = null;
                          });

                          try {
                            final cost = double.parse(controller.text.trim());
                            await _shippingService.updateRate(
                              id: rate.id,
                              shippingCost: cost,
                              isActive: isActive,
                            );

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${rate.governorate} updated',
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
                            _loadRates();
                          } catch (e) {
                            setDialogState(() {
                              saving = false;
                              dialogError = '$e';
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black87,
                          ),
                        )
                      : const Text(
                          'SAVE',
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
  // Build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<ShippingRate>>(
        future: _ratesFuture,
        builder: (context, snapshot) {
          final rates = snapshot.data ?? [];
          final activeCount = rates.where((r) => r.isActive).length;

          return Column(
            children: [
              _buildToolbar(
                total: snapshot.hasData ? rates.length : null,
                activeCount: activeCount,
              ),
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
  Widget _buildToolbar({required int? total, required int activeCount}) {
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
                'Shipping',
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
                child: OutlinedButton.icon(
                  onPressed: _loadRates,
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
          const SizedBox(height: 10),

          if (total != null)
            Row(
              children: [
                _buildStat(
                  icon: Icons.local_shipping_outlined,
                  label: '$activeCount active',
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 16),
                _buildStat(
                  icon: Icons.public,
                  label: '$total governorates',
                  color: const Color(0xFF999999),
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
  Widget _buildBody(AsyncSnapshot<List<ShippingRate>> snapshot) {
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
                'Failed to load shipping rates',
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

    final rates = snapshot.data ?? [];
    if (rates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 56,
              color: Color(0xFFCCCCCC),
            ),
            SizedBox(height: 16),
            Text(
              'No shipping rates',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadRates(),
      color: Colors.black87,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: rates.length,
        itemBuilder: (context, index) {
          return _buildRateRow(rates[index]);
        },
      ),
    );
  }

  // ============================================================
  // Rate Row
  // ============================================================
  Widget _buildRateRow(ShippingRate rate) {
    final isActive = rate.isActive;
    final statusColor = isActive
        ? Colors.green.shade700
        : const Color(0xFF999999);
    final statusLabel = isActive ? 'ACTIVE' : 'DISABLED';

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade50 : const Color(0xFFF7F7F7),
              border: Border.all(
                color: isActive
                    ? Colors.green.shade200
                    : const Color(0xFFEEEEEE),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.location_on_outlined,
              size: 18,
              color: isActive ? Colors.green.shade700 : const Color(0xFF999999),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rate.governorate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? Colors.black87
                              : const Color(0xFF999999),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                Row(
                  children: [
                    Text(
                      '${rate.shippingCost.toStringAsFixed(2)} EGP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? Colors.black87
                            : const Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'shipping',
                      style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: const Color(0xFF666666),
            onPressed: () => _showEditDialog(rate),
          ),
        ],
      ),
    );
  }
}
