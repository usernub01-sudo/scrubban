import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_item.dart';
import '../models/shipping_rate.dart';
import '../providers/cart_provider.dart';
import '../services/coupon_service.dart';
import '../services/order_service.dart';
import '../services/shipping_service.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();
  final _shippingService = ShippingService();
  final _couponService = CouponService();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();

  // Shipping
  late Future<List<ShippingRate>> _shippingFuture;
  ShippingRate? _selectedRate;

  // Coupon
  double? _appliedDiscountPercent;
  String? _appliedCouponCode;
  bool _checkingCoupon = false;
  String? _couponError;

  // Submit
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _shippingFuture = _shippingService.fetchActiveRates();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // Totals
  // ============================================================
  double _subtotal(CartProvider cart) => cart.total;

  double _discountAmount(CartProvider cart) {
    if (_appliedDiscountPercent == null) return 0;
    return double.parse(
      ((cart.total * _appliedDiscountPercent!) / 100).toStringAsFixed(2),
    );
  }

  double _shippingCost() => _selectedRate?.shippingCost ?? 0;

  double _finalTotal(CartProvider cart) {
    return _subtotal(cart) - _discountAmount(cart) + _shippingCost();
  }

  // ============================================================
  // Coupon
  // ============================================================
  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _couponError = 'Enter a coupon code');
      return;
    }

    setState(() {
      _checkingCoupon = true;
      _couponError = null;
    });

    try {
      final percent = await _couponService.validateCoupon(code);

      if (!mounted) return;

      if (percent == null) {
        setState(() {
          _checkingCoupon = false;
          _appliedDiscountPercent = null;
          _appliedCouponCode = null;
          _couponError = 'Invalid or already-used coupon';
        });
        return;
      }

      setState(() {
        _checkingCoupon = false;
        _appliedDiscountPercent = percent;
        _appliedCouponCode = code.toUpperCase();
        _couponError = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coupon applied: ${percent.toStringAsFixed(0)}% off',
            style: const TextStyle(fontSize: 13, letterSpacing: 0.3),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingCoupon = false;
        _couponError = 'Could not validate coupon';
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedDiscountPercent = null;
      _appliedCouponCode = null;
      _couponCtrl.clear();
      _couponError = null;
    });
  }

  // ============================================================
  // Submit
  // ============================================================
  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRate == null) {
      _showError('Please select a governorate');
      return;
    }

    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      _showError('Your cart is empty');
      return;
    }

    setState(() => _submitting = true);

    try {
      final items = cart.items
          .map(
            (ci) => OrderItem(
              productId: ci.product.id,
              productName: ci.product.name,
              price: ci.product.price,
              quantity: ci.quantity,
            ),
          )
          .toList();

      final orderId = await _orderService.createOrder(
        customerName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        governorate: _selectedRate!.governorate,
        city: _cityCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        items: items,
        couponCode: _appliedCouponCode,
      );

      cart.clearCart();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderSuccessPage(orderId: orderId)),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to submit order: $e');
      setState(() => _submitting = false);
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
    final cart = context.watch<CartProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: isWide
                      ? _buildWideLayout(cart, isWide: true)
                      : _buildNarrowLayout(cart),
                ),
              ),
            ),
            if (!isWide) _buildStickyButton(cart),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Top Bar
  // ============================================================
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            color: Colors.black87,
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'CHECKOUT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ============================================================
  // Layouts
  // ============================================================
  Widget _buildWideLayout(CartProvider cart, {required bool isWide}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildForm()),
        const SizedBox(width: 40),
        SizedBox(width: 380, child: _buildSummary(cart, isWide: isWide)),
      ],
    );
  }

  Widget _buildNarrowLayout(CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildForm(),
        const SizedBox(height: 32),
        _buildSummary(cart, isWide: false),
        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // Form
  // ============================================================
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'DELIVERY INFORMATION',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.5,
            color: Color(0xFF999999),
          ),
        ),
        const SizedBox(height: 20),

        _buildField(
          controller: _nameCtrl,
          label: 'Full Name',
          validator: (v) =>
              (v == null || v.trim().length < 3) ? 'Name is too short' : null,
        ),
        const SizedBox(height: 16),

        _buildField(
          controller: _phoneCtrl,
          label: 'Phone Number',
          keyboardType: TextInputType.phone,
          hint: '01012345678',
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Phone number is required';
            }
            final cleaned = v.trim().replaceAll(' ', '');
            if (!RegExp(r'^0?1[0-9]{9}$').hasMatch(cleaned)) {
              return 'Invalid number (e.g. 01012345678)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Governorate (dynamic from Supabase)
        FutureBuilder<List<ShippingRate>>(
          future: _shippingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black26,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade200),
                  color: Colors.red.shade50,
                ),
                child: Text(
                  'Failed to load governorates: ${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              );
            }

            final rates = snapshot.data ?? [];
            if (rates.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: const Text(
                  'No governorates available',
                  style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                ),
              );
            }

            return DropdownButtonFormField<String>(
              dropdownColor: Colors.white,
              value: _selectedRate?.governorate,
              decoration: _inputDecoration('Governorate'),
              icon: const Icon(Icons.expand_more, color: Colors.black54),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              isExpanded: true,
              items: rates.map((rate) {
                return DropdownMenuItem<String>(
                  value: rate.governorate,
                  child: Row(
                    children: [
                      Expanded(child: Text(rate.governorate)),
                      Text(
                        '${rate.shippingCost.toStringAsFixed(0)} EGP',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _submitting
                  ? null
                  : (value) {
                      setState(() {
                        _selectedRate = rates.firstWhere(
                          (r) => r.governorate == value,
                        );
                      });
                    },
              validator: (v) =>
                  v == null ? 'Please select a governorate' : null,
            );
          },
        ),
        const SizedBox(height: 16),

        _buildField(
          controller: _cityCtrl,
          label: 'City / Area',
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'City is required' : null,
        ),
        const SizedBox(height: 16),

        _buildField(
          controller: _addressCtrl,
          label: 'Detailed Address',
          hint: 'Street, building number, floor...',
          maxLines: 3,
          validator: (v) => (v == null || v.trim().length < 5)
              ? 'Please enter a more detailed address'
              : null,
        ),

        const SizedBox(height: 32),
        _buildCouponSection(),
      ],
    );
  }

  // ============================================================
  // Coupon Section
  // ============================================================
  Widget _buildCouponSection() {
    // Applied state
    if (_appliedCouponCode != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 20,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _appliedCouponCode!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_appliedDiscountPercent!.toStringAsFixed(0)}% off applied',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: Colors.green.shade700,
              onPressed: _removeCoupon,
              tooltip: 'Remove coupon',
            ),
          ],
        ),
      );
    }

    // Input state
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'COUPON CODE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.5,
            color: Color(0xFF999999),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _couponCtrl,
                enabled: !_submitting && !_checkingCoupon,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 14,
                  letterSpacing: 1.5,
                  color: Colors.black87,
                ),
                decoration: _inputDecoration(
                  'Enter code',
                ).copyWith(errorText: _couponError),
                onFieldSubmitted: (_) => _applyCoupon(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: _checkingCoupon || _submitting ? null : _applyCoupon,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black87, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: _checkingCoupon
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black87,
                        ),
                      )
                    : const Text(
                        'APPLY',
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
      ],
    );
  }

  // ============================================================
  // Field Helper
  // ============================================================
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_submitting,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: _inputDecoration(label, hint: hint),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
      labelStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF666666),
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black87, width: 1.4),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.red, width: 1.4),
      ),
    );
  }

  // ============================================================
  // Summary
  // ============================================================
  Widget _buildSummary(CartProvider cart, {required bool isWide}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ORDER SUMMARY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.5,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 20),

          ...cart.items.map(
            (ci) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ci.quantity}×',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ci.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555555),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ci.subtotal.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),

          _buildSummaryRow(
            'Subtotal',
            '${_subtotal(cart).toStringAsFixed(2)} EGP',
          ),

          if (_appliedDiscountPercent != null) ...[
            const SizedBox(height: 10),
            _buildSummaryRow(
              'Discount (${_appliedDiscountPercent!.toStringAsFixed(0)}%)',
              '- ${_discountAmount(cart).toStringAsFixed(2)} EGP',
              valueColor: Colors.green.shade700,
            ),
          ],

          const SizedBox(height: 10),
          _buildSummaryRow(
            'Shipping',
            _selectedRate == null
                ? '—'
                : '${_shippingCost().toStringAsFixed(2)} EGP',
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${_finalTotal(cart).toStringAsFixed(2)} EGP',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),

          const Text(
            'This is an order request. We will contact you to confirm. No online payment.',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF999999),
              height: 1.6,
            ),
          ),

          if (isWide) ...[const SizedBox(height: 24), _buildPlaceOrderButton()],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Place Order Buttons
  // ============================================================
  Widget _buildPlaceOrderButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submitOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'PLACE ORDER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }

  Widget _buildStickyButton(CartProvider cart) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_finalTotal(cart).toStringAsFixed(2)} EGP',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'PLACE ORDER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
