import 'package:flutter/foundation.dart';
import '../models/product.dart';

/// عنصر واحد في السلة
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  /// إجمالي العنصر = السعر × الكمية
  double get subtotal => product.price * quantity;
}

/// الـProvider اللي بيدير السلة كلها
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {}; // key = product.id

  /// كل عناصر السلة كـList
  List<CartItem> get items => _items.values.toList();

  /// عدد العناصر الكلي (مجموع الكميات)
  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// إجمالي السلة
  double get total =>
      _items.values.fold(0.0, (sum, item) => sum + item.subtotal);

  /// هل السلة فاضية؟
  bool get isEmpty => _items.isEmpty;

  /// إضافة منتج للسلة (لو موجود، نزيد الكمية)
  void addToCart(Product product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += quantity;
    } else {
      _items[product.id] = CartItem(product: product, quantity: quantity);
    }
    notifyListeners();
  }

  /// زيادة كمية عنصر
  void increaseQuantity(String productId) {
    final item = _items[productId];
    if (item != null) {
      item.quantity++;
      notifyListeners();
    }
  }

  /// تقليل كمية عنصر (مش أقل من 1)
  void decreaseQuantity(String productId) {
    final item = _items[productId];
    if (item != null && item.quantity > 1) {
      item.quantity--;
      notifyListeners();
    }
  }

  /// حذف عنصر من السلة
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  /// تفريغ السلة بالكامل (هنستخدمها بعد إتمام الطلب)
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
