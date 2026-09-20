import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import 'checkout_page.dart';
import 'home_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cart, _) {
            return Column(
              children: [
                _buildTopBar(context, cart),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                Expanded(
                  child: cart.isEmpty
                      ? _buildEmpty(context)
                      : _buildCartContent(context, cart),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // Top Bar
  // ============================================================
  Widget _buildTopBar(BuildContext context, CartProvider cart) {
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
          Expanded(
            child: Center(
              child: Text(
                cart.isEmpty ? 'CART' : 'CART (${cart.itemCount})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // Clear all (only when non-empty)
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 22),
              color: Colors.black87,
              tooltip: 'Clear cart',
              onPressed: () => _confirmClear(context, cart),
            )
          else
            const SizedBox(width: 48),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ============================================================
  // Empty
  // ============================================================
  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Color(0xFFCCCCCC),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add some products to get started',
              style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black87, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'CONTINUE SHOPPING',
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

  // ============================================================
  // Content
  // ============================================================
  Widget _buildCartContent(BuildContext context, CartProvider cart) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        if (isWide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildItemsColumn(context, cart)),
                    const SizedBox(width: 40),
                    SizedBox(
                      width: 340,
                      child: _buildSummaryColumn(context, cart),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildItemsColumn(context, cart),
                    const SizedBox(height: 24),
                    _buildSummaryColumn(context, cart),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildStickyBar(context, cart),
          ],
        );
      },
    );
  }

  // ============================================================
  // Items Column
  // ============================================================
  Widget _buildItemsColumn(BuildContext context, CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'ITEMS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.5,
              color: Color(0xFF999999),
            ),
          ),
        ),
        ...cart.items.map((item) => _buildItemRow(context, item)),
      ],
    );
  }

  Widget _buildItemRow(BuildContext context, CartItem item) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            width: 90,
            height: 90,
            child: Container(
              color: const Color(0xFFF7F7F7),
              child: _buildImage(item),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.product.price.toStringAsFixed(2)} EGP',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Quantity
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFDDDDDD),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _qtyBtn(
                            icon: Icons.remove,
                            enabled: item.quantity > 1,
                            onTap: () => context
                                .read<CartProvider>()
                                .decreaseQuantity(item.product.id),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 36),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _qtyBtn(
                            icon: Icons.add,
                            enabled: true,
                            onTap: () => context
                                .read<CartProvider>()
                                .increaseQuantity(item.product.id),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${item.subtotal.toStringAsFixed(2)} EGP',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Remove
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: const Color(0xFF999999),
            tooltip: 'Remove',
            onPressed: () =>
                context.read<CartProvider>().removeItem(item.product.id),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? Colors.black87 : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }

  Widget _buildImage(CartItem item) {
    if (item.product.imageUrl == null || item.product.imageUrl!.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, size: 28, color: Color(0xFFCCCCCC)),
      );
    }
    return Image.network(
      item.product.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 28,
          color: Color(0xFFCCCCCC),
        ),
      ),
    );
  }

  // ============================================================
  // Summary Column
  // ============================================================
  Widget _buildSummaryColumn(BuildContext context, CartProvider cart) {
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

          _buildSummaryRow('Subtotal', '${cart.total.toStringAsFixed(2)} EGP'),
          const SizedBox(height: 12),
          _buildSummaryRow('Shipping', 'Free'),
          const SizedBox(height: 12),
          _buildSummaryRow('Tax', 'Included'),

          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 0.5,
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

          const SizedBox(height: 24),

          // Checkout button (wide layout only)
          if (MediaQuery.of(context).size.width > 900)
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'CHECKOUT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          const Text(
            'Free shipping on all orders.\nNo online payment required.',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF999999),
              height: 1.6,
            ),
          ),
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
  // Sticky Bar (narrow)
  // ============================================================
  Widget _buildStickyBar(BuildContext context, CartProvider cart) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'CHECKOUT',
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

  // ============================================================
  // Clear Cart
  // ============================================================
  Future<void> _confirmClear(BuildContext context, CartProvider cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          'Clear cart?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        content: const Text(
          'This will remove all items. This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
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
              'CLEAR',
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

    if (confirmed == true) {
      cart.clearCart();
    }
  }
}
