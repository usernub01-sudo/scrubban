import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';
import 'cart_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final ProductService _productService = ProductService();
  late Future<Product?> _productFuture;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _productFuture = _productService.fetchProductById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Product?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShell(
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black87,
                  ),
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return _buildShell(_buildError(snapshot.error));
          }
          final product = snapshot.data;
          if (product == null) {
            return _buildShell(_buildNotFound());
          }
          return _buildProduct(product);
        },
      ),
    );
  }

  // ============================================================
  // Shell (for loading/error states)
  // ============================================================
  Widget _buildShell(Widget body) {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          Expanded(child: body),
        ],
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
                'PRODUCT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, size: 22),
                    color: Colors.black87,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ============================================================
  // Product Page
  // ============================================================
  Widget _buildProduct(Product product) {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return SingleChildScrollView(
                  child: isWide
                      ? _buildWideLayout(product)
                      : _buildNarrowLayout(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---- Wide: image left, info right ----
  Widget _buildWideLayout(Product product) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: const Color(0xFFF7F7F7),
              child: _buildImage(product),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: _buildInfo(product),
          ),
        ),
      ],
    );
  }

  // ---- Narrow: stacked ----
  Widget _buildNarrowLayout(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            color: const Color(0xFFF7F7F7),
            child: _buildImage(product),
          ),
        ),
        Padding(padding: const EdgeInsets.all(20), child: _buildInfo(product)),
      ],
    );
  }

  // ============================================================
  // Image
  // ============================================================
  Widget _buildImage(Product product) {
    if (product.imageUrl == null || product.imageUrl!.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, size: 56, color: Color(0xFFCCCCCC)),
      );
    }
    return Image.network(
      product.imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black26,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 56,
          color: Color(0xFFCCCCCC),
        ),
      ),
    );
  }

  // ============================================================
  // Info
  // ============================================================
  Widget _buildInfo(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name (Georgia, editorial)
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
            height: 1.25,
            letterSpacing: -0.3,
            fontFamily: 'Georgia',
          ),
        ),

        const SizedBox(height: 12),

        // Price
        Text(
          '${product.price.toStringAsFixed(2)} EGP',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 28),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 24),

        // Description
        if (product.description != null && product.description!.isNotEmpty) ...[
          Text(
            product.description!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 28),
        ],

        // Quantity selector
        _buildQuantityRow(),

        const SizedBox(height: 18),

        // Add to cart
        _buildAddToCartButton(product),

        const SizedBox(height: 32),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 24),

        // Notes
        _buildNote(
          Icons.local_shipping_outlined,
          'Delivery available — we will contact you',
        ),
        const SizedBox(height: 14),
        _buildNote(
          Icons.payments_outlined,
          'Cash on delivery — no online payment',
        ),
      ],
    );
  }

  // ---- Quantity ----
  Widget _buildQuantityRow() {
    return Row(
      children: [
        const Text(
          'Quantity',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyBtn(
                icon: Icons.remove,
                enabled: _quantity > 1,
                onTap: () => setState(() => _quantity--),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 40),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              _qtyBtn(
                icon: Icons.add,
                enabled: true,
                onTap: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qtyBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.black87 : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }

  // ---- Add to cart ----
  Widget _buildAddToCartButton(Product product) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _onAddToCart(product),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: const Text(
          'ADD TO CART',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  // ---- Note row ----
  Widget _buildNote(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF666666)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Error & Not Found
  // ============================================================
  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Color(0xFF999999)),
            const SizedBox(height: 16),
            const Text(
              'Failed to load product',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 44, color: Color(0xFF999999)),
          SizedBox(height: 16),
          Text(
            'Product not found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Add to Cart
  // ============================================================
  void _onAddToCart(Product product) {
    context.read<CartProvider>().addToCart(product, quantity: _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added $_quantity × ${product.name} to cart',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
    setState(() => _quantity = 1);
  }
}
