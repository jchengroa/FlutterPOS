import 'package:flutter/material.dart';

import 'core/currency.dart';
import 'data/models/cart_item.dart';
import 'data/models/product.dart';
import 'data/models/sale_record.dart';
import 'data/services/local_pos_backend.dart';
import 'state/pos_controller.dart';

class PosApp extends StatelessWidget {
  const PosApp({super.key, required this.backend});

  final LocalPosBackend backend;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F1EA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E5A4F),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFCF6),
        ),
        textTheme: Typography.blackMountainView.apply(
          bodyColor: const Color(0xFF1E1F1C),
          displayColor: const Color(0xFF1E1F1C),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFCF6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE4DED0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD8D1C0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD8D1C0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF1E5A4F), width: 1.2),
          ),
        ),
      ),
      home: PosDashboard(controller: PosController(backend)),
    );
  }
}

class PosDashboard extends StatefulWidget {
  const PosDashboard({super.key, required this.controller});

  final PosController controller;

  @override
  State<PosDashboard> createState() => _PosDashboardState();
}

class _PosDashboardState extends State<PosDashboard> {
  late final TextEditingController _searchController;

  PosController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: controller.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _checkout() async {
    final success = await controller.checkout();
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          success
              ? 'Sale completed and inventory updated.'
              : 'Add items to the cart before checkout.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8F4EA), Color(0xFFF2EFE7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 1100;
                  final sections = [
                    _buildCatalogSection(isCompact),
                    _buildCartSection(isCompact),
                  ];

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: isCompact
                        ? ListView(
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              ...sections.expand(
                                (section) => [section, const SizedBox(height: 20)],
                              ),
                              _buildInsightsSection(isCompact: true),
                            ],
                          )
                        : Column(
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 6, child: sections[0]),
                                    const SizedBox(width: 20),
                                    Expanded(flex: 4, child: sections[1]),
                                    const SizedBox(width: 20),
                                    SizedBox(
                                      width: 300,
                                      child: _buildInsightsSection(isCompact: false),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minimal POS',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elegant checkout, indexed catalog search, and local backend persistence.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5D625B),
                      ),
                ),
              ],
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(
                  label: 'Products',
                  value: '${controller.products.length}',
                ),
                _MetricChip(
                  label: 'Revenue',
                  value: formatCurrency(controller.totalRevenue),
                ),
                _MetricChip(
                  label: 'Low Stock',
                  value: '${controller.lowStockCount}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogSection(bool isCompact) {
    final grid = controller.filteredProducts.isEmpty
        ? const _EmptyState(
            title: 'No products match the current filters.',
            subtitle: 'Try another category or clear the search query.',
          )
        : GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isCompact ? 1 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: isCompact ? 2.4 : 1.55,
            ),
            itemCount: controller.filteredProducts.length,
            itemBuilder: (context, index) {
              final product = controller.filteredProducts[index];
              return _ProductCard(
                product: product,
                onAdd: product.stock == 0 ? null : () => controller.addToCart(product.id),
              );
            },
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catalog',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isCompact ? double.infinity : 320,
                  child: TextField(
                    controller: _searchController,
                    onChanged: controller.updateSearch,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search by name, token, or prefix',
                    ),
                  ),
                ),
                SizedBox(
                  width: isCompact ? double.infinity : 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: controller.selectedCategory,
                    items: [
                      const DropdownMenuItem(
                        value: 'All',
                        child: Text('All categories'),
                      ),
                      ...controller.categories.map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      ),
                    ],
                    onChanged: (value) => controller.updateCategory(value ?? 'All'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.tune_rounded),
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Low stock only'),
                  selected: controller.lowStockOnly,
                  onSelected: (_) => controller.toggleLowStock(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            isCompact ? SizedBox(height: 540, child: grid) : Expanded(child: grid),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSection(bool isCompact) {
    final cartList = controller.cartItems.isEmpty
        ? const _EmptyState(
            title: 'Cart is empty.',
            subtitle: 'Add products from the catalog to start a sale.',
          )
        : ListView.separated(
            itemCount: controller.cartItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = controller.cartItems[index];
              return _CartItemTile(
                item: item,
                onDecrease: () => controller.changeQuantity(
                  item.product.id,
                  item.quantity - 1,
                ),
                onIncrease: () => controller.changeQuantity(
                  item.product.id,
                  item.quantity + 1,
                ),
                onRemove: () => controller.removeFromCart(item.product.id),
              );
            },
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Sale',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'O(1) cart updates are backed by a product-id keyed map.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF686E65),
                  ),
            ),
            const SizedBox(height: 18),
            isCompact ? SizedBox(height: 280, child: cartList) : Expanded(child: cartList),
            const SizedBox(height: 18),
            _SummaryRow(label: 'Items', value: '${controller.totalUnits}'),
            _SummaryRow(
              label: 'Subtotal',
              value: formatCurrency(controller.subtotal),
            ),
            _SummaryRow(
              label: 'Tax (8%)',
              value: formatCurrency(controller.tax),
            ),
            const Divider(height: 28),
            _SummaryRow(
              label: 'Total',
              value: formatCurrency(controller.total),
              prominent: true,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.cartItems.isEmpty
                        ? null
                        : controller.clearCart,
                    child: const Text('Clear cart'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _checkout,
                    child: const Text('Checkout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection({required bool isCompact}) {
    final recentSales = controller.sales.take(5).toList();
    final salesList = recentSales.isEmpty
        ? const _EmptyState(
            title: 'No completed sales yet.',
            subtitle: 'Checkout activity will appear here.',
          )
        : ListView.separated(
            itemCount: recentSales.length,
            separatorBuilder: (context, index) => const Divider(height: 18),
            itemBuilder: (context, index) {
              final sale = recentSales[index];
              return _SaleTile(sale: sale);
            },
          );
    final recentSalesCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Sales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(child: salesList),
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backend Snapshot',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                _SummaryRow(
                  label: 'Transactions',
                  value: '${controller.sales.length}',
                ),
                _SummaryRow(
                  label: 'Inventory units',
                  value: '${controller.inventoryUnits}',
                ),
                _SummaryRow(
                  label: 'Average basket',
                  value: formatCurrency(controller.averageOrderValue),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (isCompact)
          SizedBox(
            height: 360,
            child: recentSalesCard,
          )
        else
          Expanded(child: recentSalesCard),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onAdd});

  final Product product;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final lowStock = product.stock <= 5;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4DED0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: product.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(product.icon, color: product.color),
                ),
                const Spacer(),
                Chip(
                  label: Text(product.category),
                  backgroundColor: const Color(0xFFF2EFE7),
                  side: BorderSide.none,
                ),
              ],
            ),
            const Spacer(),
            Text(
              product.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF62675E),
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  formatCurrency(product.price),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  '${product.stock} in stock',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: lowStock ? const Color(0xFF9E4C00) : const Color(0xFF62675E),
                        fontWeight: lowStock ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onAdd,
                child: Text(onAdd == null ? 'Out of stock' : 'Add to cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DED0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatCurrency(item.product.price)} each',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF62675E),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _QuantityButton(icon: Icons.remove, onPressed: onDecrease),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '${item.quantity}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _QuantityButton(icon: Icons.add, onPressed: onIncrease),
                const Spacer(),
                Text(
                  formatCurrency(item.lineTotal),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale});

  final SaleRecord sale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                sale.reference,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(formatCurrency(sale.total)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${formatDateTime(sale.completedAt)} • ${sale.items.length} items',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF62675E),
              ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DED0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF62675E),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EFE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.prominent = false,
  });

  final String label;
  final String value;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final style = prominent
        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_rounded, size: 34, color: Color(0xFF7C8379)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF62675E),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
