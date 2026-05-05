import 'dart:collection';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/sale_record.dart';
import '../seeds.dart';

class LocalPosBackend {
  LocalPosBackend._();

  static const taxRate = 0.08;

  final LinkedHashMap<String, Product> _productsById = LinkedHashMap();
  final LinkedHashMap<String, CartItem> _cartByProductId = LinkedHashMap();
  final List<SaleRecord> _sales = [];

  final Map<String, Set<String>> _categoryIndex = {};
  final Map<String, Set<String>> _searchIndex = {};

  static Future<LocalPosBackend> bootstrap() async {
    final backend = LocalPosBackend._();
    backend._load();
    return backend;
  }

  List<Product> get products => List.unmodifiable(_productsById.values);
  List<CartItem> get cartItems => List.unmodifiable(_cartByProductId.values);
  List<SaleRecord> get sales => List.unmodifiable(_sales.reversed);
  List<String> get categories => _categoryIndex.keys.toList()..sort();

  double get subtotal =>
      _cartByProductId.values.fold(0, (sum, item) => sum + item.lineTotal);

  double get tax => subtotal * taxRate;
  double get total => subtotal + tax;
  int get totalUnits =>
      _cartByProductId.values.fold(0, (sum, item) => sum + item.quantity);
  int get lowStockCount => _productsById.values.where((product) => product.stock <= 5).length;
  int get inventoryUnits => _productsById.values.fold(0, (sum, product) => sum + product.stock);
  double get totalRevenue => _sales.fold(0, (sum, sale) => sum + sale.total);
  double get averageOrderValue => _sales.isEmpty ? 0 : totalRevenue / _sales.length;

  List<Product> queryProducts({
    String query = '',
    String category = 'All',
    bool lowStockOnly = false,
  }) {
    Set<String>? candidateIds;

    if (category != 'All') {
      candidateIds = {...?_categoryIndex[category]};
    }

    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      final parts = normalizedQuery.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
      for (final part in parts) {
        final matches = _searchIndex[part] ?? <String>{};
        candidateIds = candidateIds == null ? {...matches} : candidateIds.intersection(matches);
      }
    }

    final baseProducts = candidateIds == null
        ? _productsById.values
        : candidateIds.map((id) => _productsById[id]).whereType<Product>();

    final filtered = baseProducts.where((product) {
      if (lowStockOnly && product.stock > 5) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final stockCompare = a.stock.compareTo(b.stock);
        if (lowStockOnly && stockCompare != 0) {
          return stockCompare;
        }
        return a.name.compareTo(b.name);
      });

    return filtered;
  }

  void addToCart(String productId) {
    final product = _productsById[productId];
    if (product == null || product.stock == 0) {
      return;
    }

    final existing = _cartByProductId[productId];
    final nextQuantity = (existing?.quantity ?? 0) + 1;
    if (nextQuantity > product.stock) {
      return;
    }

    _cartByProductId[productId] = CartItem(product: product, quantity: nextQuantity);
  }

  void updateCartQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      _cartByProductId.remove(productId);
      return;
    }

    final product = _productsById[productId];
    if (product == null) {
      return;
    }

    final safeQuantity = quantity.clamp(0, product.stock);
    if (safeQuantity == 0) {
      _cartByProductId.remove(productId);
      return;
    }

    _cartByProductId[productId] = CartItem(product: product, quantity: safeQuantity);
  }

  void clearCart() {
    _cartByProductId.clear();
  }

  Future<bool> checkout() async {
    if (_cartByProductId.isEmpty) {
      return false;
    }

    final items = <SaleLineItem>[];
    for (final entry in _cartByProductId.entries) {
      final product = _productsById[entry.key];
      final quantity = entry.value.quantity;
      if (product == null || product.stock < quantity) {
        return false;
      }
      items.add(
        SaleLineItem(
          productId: product.id,
          name: product.name,
          quantity: quantity,
          unitPrice: product.price,
        ),
      );
    }

    for (final entry in _cartByProductId.entries) {
      final product = _productsById[entry.key]!;
      _productsById[entry.key] = product.copyWith(stock: product.stock - entry.value.quantity);
    }

    final sale = SaleRecord(
      reference: 'TX-${DateTime.now().millisecondsSinceEpoch}',
      completedAt: DateTime.now(),
      subtotal: subtotal,
      tax: tax,
      total: total,
      items: items,
    );

    _sales.add(sale);
    _cartByProductId.clear();
    _rebuildIndexes();
    return true;
  }

  void _load() {
    final products = seedProducts;
    final sales = <SaleRecord>[];
    _productsById
      ..clear()
      ..addEntries(products.map((product) => MapEntry(product.id, product)));
    _sales
      ..clear()
      ..addAll(sales);
    _rebuildIndexes();
  }

  void _rebuildIndexes() {
    _categoryIndex.clear();
    _searchIndex.clear();

    for (final product in _productsById.values) {
      _categoryIndex.putIfAbsent(product.category, () => <String>{}).add(product.id);

      final searchable = '${product.name} ${product.category} ${product.description}'.toLowerCase();
      final tokens = searchable
          .split(RegExp(r'[^a-z0-9]+'))
          .where((token) => token.isNotEmpty)
          .toSet();

      for (final token in tokens) {
        for (var i = 1; i <= token.length; i++) {
          final prefix = token.substring(0, i);
          _searchIndex.putIfAbsent(prefix, () => <String>{}).add(product.id);
        }
      }
    }
  }
}
