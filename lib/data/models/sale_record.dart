class SaleLineItem {
  const SaleLineItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory SaleLineItem.fromJson(Map<String, dynamic> json) {
    return SaleLineItem(
      productId: json['productId'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }
}

class SaleRecord {
  const SaleRecord({
    required this.reference,
    required this.completedAt,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.items,
  });

  final String reference;
  final DateTime completedAt;
  final double subtotal;
  final double tax;
  final double total;
  final List<SaleLineItem> items;

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'completedAt': completedAt.toIso8601String(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      reference: json['reference'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      items: (json['items'] as List<dynamic>)
          .map((item) => SaleLineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
