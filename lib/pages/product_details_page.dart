import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrubban/providers/cart_provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';

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
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Product?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حصل خطأ: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final product = snapshot.data;
          if (product == null) {
            return const Center(child: Text('المنتج غير موجود'));
          }

          return _buildProductView(product);
        },
      ),
    );
  }

  Widget _buildProductView(Product product) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // لو الشاشة عريضة، نصير Row، لو ضيقة نصير Column
        final isWide = constraints.maxWidth > 700;

        final imageSection = _buildImage(product);
        final infoSection = _buildInfo(product);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: imageSection),
                    const SizedBox(width: 24),
                    Expanded(child: infoSection),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    imageSection,
                    const SizedBox(height: 20),
                    infoSection,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildImage(Product product) {
    if (product.imageUrl == null || product.imageUrl!.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.grey[200],
          child: const Icon(
            Icons.image_not_supported,
            size: 80,
            color: Colors.grey,
          ),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 1,
      child: Image.network(
        product.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget _buildInfo(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          '${product.price.toStringAsFixed(2)} EGP',
          style: TextStyle(
            fontSize: 22,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        if (product.description != null && product.description!.isNotEmpty) ...[
          const Text(
            'الوصف:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            product.description!,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 24),
        ],
        // اختيار الكمية
        Row(
          children: [
            const Text('الكمية:', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            _buildQuantityControl(),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _onAddToCart(product),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('أضف إلى السلة', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControl() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
          ),
          Text(
            '$_quantity',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  void _onAddToCart(Product product) {
    context.read<CartProvider>().addToCart(product, quantity: _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة $_quantity × ${product.name} إلى السلة'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // رجّع الكمية لـ1 بعد الإضافة
    setState(() => _quantity = 1);
  }
}
