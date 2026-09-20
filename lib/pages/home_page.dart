import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';
import 'cart_page.dart';
import 'product_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _productService.fetchActiveProducts();
  }

  Future<void> _refresh() async {
    setState(() {
      _productsFuture = _productService.fetchActiveProducts();
    });
    await _productsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildError(snapshot.error);
                  }

                  final products = snapshot.data ?? [];
                  if (products.isEmpty) {
                    return _buildEmpty();
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: Colors.black,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        _buildProductsHeader(products.length),
                        _buildProductsGrid(products),
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Header
  // ============================================================
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Logo (centered)
          const Expanded(
            child: Center(
              child: Text(
                'SCRUBBAN',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // Search icon

          // Cart icon with badge
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, size: 24),
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
  // Products Header ("Products" + count)
  // ============================================================
  Widget _buildProductsHeader(int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Products',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                letterSpacing: -0.5,
                fontFamily: 'Georgia',
              ),
            ),
            const Spacer(),
            Text(
              '$count ${count == 1 ? 'product' : 'products'}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Products Grid
  // ============================================================
  Widget _buildProductsGrid(List<Product> products) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 24,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return _ProductTile(
            product: products[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProductDetailsPage(productId: products[index].id),
                ),
              );
            },
          );
        }, childCount: products.length),
      ),
    );
  }

  // ============================================================
  // Error
  // ============================================================
  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Failed to load products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _refresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black87),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Empty
  // ============================================================
  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No products yet',
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Product Tile (Shopify-style)
// ============================================================
class _ProductTile extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Image ----
            Expanded(
              child: AnimatedScale(
                scale: _hovering ? 1.02 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF7F7F7),
                  child: _buildImage(product),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ---- Name ----
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                letterSpacing: 0.1,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 3),

            // ---- Price ----
            Text(
              '${product.price.toStringAsFixed(2)} EGP',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                letterSpacing: 0.1,
              ),
            ),

            const SizedBox(height: 10),

            // ---- Button ----
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                onPressed: widget.onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  backgroundColor: _hovering ? Colors.black87 : Colors.white,
                  side: const BorderSide(color: Colors.black87, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'View product',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                    color: _hovering ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Product product) {
    if (product.imageUrl == null || product.imageUrl!.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Color(0xFFCCCCCC)),
      );
    }
    return Image.network(
      product.imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
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
          size: 40,
          color: Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}
