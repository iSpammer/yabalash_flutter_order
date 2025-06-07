import 'package:flutter/foundation.dart';
import '../../../core/utils/sku_utils.dart';

class VariantModel {
  final int id;
  final String name;
  final String? sku;
  final double price;
  final double? compareAtPrice;
  final int? stockQuantity;
  final String? image;
  final String? barcode;
  final int? position;
  final bool isDefault;

  VariantModel({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    this.compareAtPrice,
    this.stockQuantity,
    this.image,
    this.barcode,
    this.position,
    this.isDefault = false,
  });

  /// Returns a properly formatted display name
  /// If name is empty or looks like a SKU, parses the SKU to get a readable name
  String get displayName {
    debugPrint('=== Variant Display Name Debug ===');
    debugPrint('Original name: "$name"');
    debugPrint('SKU: "$sku"');
    
    // If we have a proper name that's not empty and doesn't look like a SKU, use it
    if (name.isNotEmpty && !name.startsWith('com.') && !_looksLikeSku(name)) {
      debugPrint('Using original name: "$name"');
      return name;
    }
    
    // If we have a SKU, parse it to get a readable name
    if (sku != null && sku!.isNotEmpty) {
      final parsedName = SkuUtils.parseSkuToDisplayName(sku);
      if (parsedName.isNotEmpty && parsedName != sku) {
        debugPrint('Parsed SKU "$sku" -> "$parsedName"');
        return parsedName;
      }
    }
    
    // If name looks like a SKU, parse it
    if (name.isNotEmpty && _looksLikeSku(name)) {
      final parsedName = SkuUtils.parseSkuToDisplayName(name);
      if (parsedName.isNotEmpty && parsedName != name) {
        debugPrint('Parsed name as SKU "$name" -> "$parsedName"');
        return parsedName;
      }
    }
    
    // Fallback to original name or 'Variant'
    final fallback = name.isNotEmpty ? name : 'Variant';
    debugPrint('Using fallback: "$fallback"');
    debugPrint('=====================================');
    return fallback;
  }

  /// Checks if a string looks like a SKU (contains dots or is all concatenated)
  bool _looksLikeSku(String text) {
    return text.contains('.') || 
           text.contains('com.') ||
           (text.length > 10 && !text.contains(' '));
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: _parseInt(json['id']),
      name: json['name'] ?? json['title'] ?? '',
      sku: json['sku'],
      price: _parseDouble(json['price'] ?? json['new_price'] ?? json['actual_price']),
      compareAtPrice: json['compare_at_price'] != null ? _parseDouble(json['compare_at_price']) : null,
      stockQuantity: _parseInt(json['quantity_available'] ?? json['quantity'] ?? json['stock_quantity']),
      image: json['image'],
      barcode: json['barcode'],
      position: _parseInt(json['position']),
      isDefault: json['is_default'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'price': price,
      'compare_at_price': compareAtPrice,
      'stock_quantity': stockQuantity,
      'image': image,
      'barcode': barcode,
      'position': position,
      'is_default': isDefault,
    };
  }
}