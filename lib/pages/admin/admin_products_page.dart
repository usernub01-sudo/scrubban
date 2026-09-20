import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import 'admin_product_form_page.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final _productService = ProductService();
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = _productService.fetchAllProducts();
    });
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          'Delete product?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"?\nThis action cannot be undone.',
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
      await _productService.deleteProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product deleted',
            style: TextStyle(fontSize: 13, letterSpacing: 0.3),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
      _loadProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: $e',
            style: const TextStyle(fontSize: 13, letterSpacing: 0.3),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
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
                'Products',
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
                    : '$count ${count == 1 ? 'product' : 'products'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminProductFormPage(),
                  ),
                );
                if (added == true) _loadProducts();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'ADD PRODUCT',
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
    );
  }

  // ============================================================
  // Body
  // ============================================================
  Widget _buildBody(AsyncSnapshot<List<Product>> snapshot) {
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
                'Failed to load products',
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

    final products = snapshot.data ?? [];
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: Color(0xFFCCCCCC),
            ),
            SizedBox(height: 16),
            Text(
              'No products yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Click "Add Product" to create your first one.',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadProducts(),
      color: Colors.black87,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _buildProductRow(products[index]);
        },
      ),
    );
  }

  // ============================================================
  // Product Row
  // ============================================================
  Widget _buildProductRow(Product product) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Thumbnail
          SizedBox(
            width: 64,
            height: 64,
            child: Container(
              color: const Color(0xFFF7F7F7),
              child: _buildImage(product),
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
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(product.isActive),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${product.price.toStringAsFixed(2)} EGP',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Actions
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: const Color(0xFF666666),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminProductFormPage(product: product),
                ),
              );
              if (updated == true) _loadProducts();
            },
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red.shade400,
            onPressed: () => _confirmDelete(product),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Status Badge
  // ============================================================
  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? Colors.green.shade700 : const Color(0xFF999999);
    final label = isActive ? 'ACTIVE' : 'HIDDEN';

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

  // ============================================================
  // Image
  // ============================================================
  Widget _buildImage(Product product) {
    if (product.imageUrl == null || product.imageUrl!.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, size: 22, color: Color(0xFFCCCCCC)),
      );
    }
    return Image.network(
      product.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 22,
          color: Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}
