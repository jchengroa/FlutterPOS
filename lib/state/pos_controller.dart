import 'package:flutter/foundation.dart';

import '../data/models/cart_item.dart';
import '../data/models/product.dart';
import '../data/models/sale_record.dart';
import '../data/services/local_pos_backend.dart';

class PosController extends ChangeNotifier {
  PosController(this._backend) {
    _refresh();
  }

  final LocalPosBackend _backend;

  String searchQuery = '';
  String selectedCategory = 'All';
  bool lowStockOnly = false;

  List<Product> products = const [];
  List<Product> filteredProducts = const [];
  List<CartItem> cartItems = const [];
  List<SaleRecord> sales = const [];
  List<String> categories = const [];

  double subtotal = 0;
  double tax = 0;
  double total = 0;
  int totalUnits = 0;
  int lowStockCount = 0;
  int inventoryUnits = 0;
  double totalRevenue = 0;
  double averageOrderValue = 0;

  void updateSearch(String value) {
    searchQuery = value;
    _refresh(notify: true);
  }

  void updateCategory(String value) {
    selectedCategory = value;
    _refresh(notify: true);
  }

  void toggleLowStock() {
    lowStockOnly = !lowStockOnly;
    _refresh(notify: true);
  }

  void addToCart(String productId) {
    _backend.addToCart(productId);
    _refresh(notify: true);
  }

  void changeQuantity(String productId, int quantity) {
    _backend.updateCartQuantity(productId, quantity);
    _refresh(notify: true);
  }

  void removeFromCart(String productId) {
    _backend.updateCartQuantity(productId, 0);
    _refresh(notify: true);
  }

  void clearCart() {
    _backend.clearCart();
    _refresh(notify: true);
  }

  Future<bool> checkout() async {
    final success = await _backend.checkout();
    _refresh(notify: true);
    return success;
  }

  void _refresh({bool notify = false}) {
    products = _backend.products;
    filteredProducts = _backend.queryProducts(
      query: searchQuery,
      category: selectedCategory,
      lowStockOnly: lowStockOnly,
    );
    cartItems = _backend.cartItems;
    sales = _backend.sales;
    categories = _backend.categories;
    subtotal = _backend.subtotal;
    tax = _backend.tax;
    total = _backend.total;
    totalUnits = _backend.totalUnits;
    lowStockCount = _backend.lowStockCount;
    inventoryUnits = _backend.inventoryUnits;
    totalRevenue = _backend.totalRevenue;
    averageOrderValue = _backend.averageOrderValue;
    if (notify) {
      notifyListeners();
    }
  }
}
