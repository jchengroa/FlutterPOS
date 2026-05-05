import 'package:flutter/material.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.stock,
    required this.iconCodePoint,
    required this.colorValue,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final int stock;
  final int iconCodePoint;
  final int colorValue;

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    double? price,
    int? stock,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'price': price,
        'stock': stock,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
    );
  }
}
