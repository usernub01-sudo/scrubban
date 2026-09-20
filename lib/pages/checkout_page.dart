import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_item.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _governorate;
  bool _submitting = false;

  static const List<String> _governorates = [
    'Cairo',
    'Giza',
    'Alexandria',
    'Dakahlia',
    'Sharqia',
    'Monufia',
    'Gharbia',
    'Qalyubia',
    'Beheira',
    'Kafr El Sheikh',
    'Damietta',
    'Port Said',
    'Ismailia',
    'Suez',
    'North Sinai',
    'South Sinai',
    'Fayoum',
    'Beni Suef',
    'Minya',
    'Asyut',
    'Sohag',
    'Qena',
    'Luxor',
    'Aswan',
    'Red Sea',
    'New Valley',
    'Matrouh',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_governorate == null) {
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
        governorate: _governorate!,
        city: _cityCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        total: cart.total,
        items: items,
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
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _submitting,
          child: Column(
            children: [
              _buildTopBar(),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Form(
                        key: _formKey,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 800;
                            return isWide
                                ? _buildWideLayout(cart)
                                : _buildNarrowLayout(cart);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (MediaQuery.of(context).size.width <= 800)
                _buildStickyButton(),
            ],
          ),
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
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ============================================================
  // Wide Layout
  // ============================================================
  Widget _buildWideLayout(CartProvider cart) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildForm()),
        const SizedBox(width: 40),
        SizedBox(width: 360, child: _buildSummary(cart)),
      ],
    );
  }

  // ============================================================
  // Narrow Layout
  // ============================================================
  Widget _buildNarrowLayout(CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildForm(),
        const SizedBox(height: 32),
        _buildSummary(cart),
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

        // Governorate dropdown
        DropdownButtonFormField<String>(
          value: _governorate,
          decoration: _inputDecoration('Governorate'),
          items: _governorates
              .map(
                (g) => DropdownMenuItem(
                  value: g,
                  child: Text(
                    g,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              )
              .toList(),
          onChanged: _submitting
              ? null
              : (v) => setState(() => _governorate = v),
          icon: const Icon(Icons.expand_more, color: Colors.black54),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
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
      ],
    );
  }

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
      filled: false,
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
  Widget _buildSummary(CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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

          // Items
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

          _buildSummaryRow('Subtotal', '${cart.total.toStringAsFixed(2)} EGP'),
          const SizedBox(height: 10),
          _buildSummaryRow('Shipping', 'Free'),

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
                '${cart.total.toStringAsFixed(2)} EGP',
                style: const TextStyle(
                  fontSize: 18,
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

          // Submit button (wide only)
          if (MediaQuery.of(context).size.width > 800) ...[
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  elevation: 0,
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
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Sticky button (narrow)
  // ============================================================
  Widget _buildStickyButton() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              elevation: 0,
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
      ),
    );
  }
}
