import 'package:flutter/foundation.dart';
import 'variant_model.dart'; // Assuming this contains VariantModel with at least 'id' and 'quantity'
import 'addon_model.dart';
import 'media_model.dart';
import 'vendor_info_model.dart';
import 'translation_model.dart';
import '../../../core/utils/html_utils.dart';
import '../../../core/utils/stock_debug_logger.dart';

class ProductModel {
  final int id;
  final String name;
  final String? description;
  final String? bodyHtml;
  final String? image;
  final String? thumbImage;
  final double price;
  final double? compareAtPrice;
  final String? sku;
  final String? urlSlug;
  final String? barcode;
  final int vendorId;
  final int categoryId;
  final String? categoryName;
  final bool isActive;
  final bool isFeatured;
  final bool isNew;
  final bool hasVariants;
  final int? stockQuantity; // Represents overall/default variant stock
  final double? rating;
  final int? reviewCount;
  final String? preparationTime;
  final double? weight;
  final String? weightUnit;
  final List<String>? tags;
  final List<VariantModel>? variants;
  final List<AddonModel>? addons;
  final List<MediaModel>? media;
  final VendorInfoModel? vendor;
  final List<TranslationModel>? translations;
  final String? unit;
  final double? minimumOrderCount;
  final double? batchCount;
  final String? createdAt;
  final String? updatedAt;

  // New stock-related fields
  final bool sellWhenOutOfStock; // From JSON: "sell_when_out_of_stock": 0 or 1
  final bool hasInventory; // From JSON: "has_inventory": 0 or 1
  final int? typeId; // Product type ID from API

  // Cart specific
  int quantity = 1;
  String? selectedVariantId;
  List<String> selectedAddonIds = [];

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.bodyHtml,
    this.image,
    this.thumbImage,
    required this.price,
    this.compareAtPrice,
    this.sku,
    this.urlSlug,
    this.barcode,
    required this.vendorId,
    required this.categoryId,
    this.categoryName,
    required this.isActive,
    this.isFeatured = false,
    this.isNew = false,
    this.hasVariants = false,
    this.stockQuantity,
    this.rating,
    this.reviewCount,
    this.preparationTime,
    this.weight,
    this.weightUnit,
    this.tags,
    this.variants,
    this.addons,
    this.media,
    this.vendor,
    this.translations,
    this.unit,
    this.minimumOrderCount,
    this.batchCount,
    this.createdAt,
    this.updatedAt,
    required this.sellWhenOutOfStock,
    required this.hasInventory,
    this.typeId,
  });

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        debugPrint('Error parsing double from: $value, error: $e');
        return null;
      }
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        debugPrint('Error parsing int from: $value, error: $e');
        return null;
      }
    }
    return null;
  }
  
  static String? _extractImageUrl(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isNotEmpty ? value : null;
    if (value is Map) {
      // Try different possible paths for image URL
      return value['image_path'] ?? 
             value['path'] ?? 
             value['url'] ?? 
             value['original_image'] ??
             value['image_s3_url'];
    }
    return null;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    debugPrint('=== ProductModel.fromJson Debug ===');
    debugPrint('JSON keys: ${json.keys.toList()}');
    debugPrint('JSON vals: ${json.values.toList()}');

    // Get the translation for the current language (default to language_id = 1)
    final translations = json['translation'] != null
        ? (json['translation'] as List)
            .map((t) => TranslationModel.fromJson(t))
            .toList()
        : null;

    // Get the first translation (usually language_id = 1)
    final primaryTranslation =
        translations?.isNotEmpty == true ? translations!.first : null;
    debugPrint('Primary translation title: ${primaryTranslation?.title}');

    // Extract primary image from media array or direct path field
    String? primaryImage;
    String? thumbImage;
    
    // Handle direct path field (flattened structure from some API endpoints)
    if (json['path'] != null && json['path'] is String) {
      // Direct path field - construct full image URL
      final imagePath = json['path'] as String;
      if (imagePath.isNotEmpty) {
        primaryImage = 'https://yabalash-assets.s3.me-central-1.amazonaws.com/$imagePath';
        debugPrint('🖼️ Using direct path image: $primaryImage');
      }
    }
    
    // Handle nested media structure (if no direct path or as fallback)
    if (primaryImage == null && json['media'] != null && (json['media'] as List).isNotEmpty) {
      final mediaList = (json['media'] as List);
      // Find default image or use first
      final defaultMedia = mediaList.firstWhere(
        (m) => m['is_default'] == 1,
        orElse: () => mediaList.first,
      );
      primaryImage = defaultMedia['image']?['path']?['original_image'] ??
          defaultMedia['image']?['path']?['image_s3_url'];
      if (primaryImage != null) {
        debugPrint('🖼️ Using original/s3 image: $primaryImage');
      }

      // Build full image URL if needed
      if (primaryImage == null && defaultMedia['image']?['path'] != null) {
        final path = defaultMedia['image']['path'];
        if (path['proxy_url'] != null && path['image_path'] != null) {
          String proxyUrl = path['proxy_url'].toString();
          String imagePath = path['image_path'].toString();
          
          // Remove trailing slash from proxy_url and leading slash from image_path to avoid double slashes
          if (proxyUrl.endsWith('/')) {
            proxyUrl = proxyUrl.substring(0, proxyUrl.length - 1);
          }
          if (imagePath.startsWith('/')) {
            imagePath = imagePath.substring(1);
          }
          
          primaryImage = '$proxyUrl/$imagePath';
          debugPrint('🖼️ Using constructed proxy image: $primaryImage');
        }
      }
    }

    // Parse variants - handle both 'variant' and 'variants' keys
    List<VariantModel>? variantsList;
    if (json['variant'] != null && (json['variant'] as List).isNotEmpty) {
      debugPrint(
          'Found variants in variant key: ${(json['variant'] as List).length}');
      variantsList = (json['variant'] as List)
          .map((v) => VariantModel.fromJson(v))
          .toList();
    } else if (json['variants'] != null &&
        (json['variants'] as List).isNotEmpty) {
      debugPrint(
          'Found variants in variants key: ${(json['variants'] as List).length}');
      variantsList = (json['variants'] as List)
          .map((v) => VariantModel.fromJson(v))
          .toList();
    }

    // Get price from first variant if no direct price
    double productPrice = 0.0;
    double? comparePrice;
    if (variantsList != null && variantsList.isNotEmpty) {
      productPrice = variantsList.first.price;
      comparePrice = variantsList.first.compareAtPrice ??
          _parseDouble(json['compare_at_price']) ??
          _parseDouble(json['compare_price_numeric']);
      debugPrint('Using variant price: $productPrice, compare: $comparePrice');
    } else {
      // Handle both price/compare_at_price and price_numeric/compare_price_numeric
      productPrice = _parseDouble(json['price_numeric']) ?? 
                    _parseDouble(json['price']) ?? 0.0;
      comparePrice = _parseDouble(json['compare_price_numeric']) ?? 
                    _parseDouble(json['compare_at_price']);
      debugPrint('Using direct price: $productPrice, compare: $comparePrice');
      debugPrint('🔍 Price debug - price_numeric: ${json['price_numeric']}, price: ${json['price']}');
      debugPrint('🔍 Compare debug - compare_price_numeric: ${json['compare_price_numeric']}, compare_at_price: ${json['compare_at_price']}');
    }

    final product = ProductModel(
      id: _parseInt(json['id']) ?? 0,
      name: primaryTranslation?.title ?? json['title'] ?? json['name'] ?? '',
      description: HtmlUtils.safeExtractText(primaryTranslation?.bodyHtml ??
          json['description'] ??
          primaryTranslation?.metaDescription),
      bodyHtml: primaryTranslation?.bodyHtml ?? json['body_html'],
      image: primaryImage ??
          _extractImageUrl(json['image']) ??
          json['image_url'] ??
          _extractImageUrl(json['product_image']),
      thumbImage: thumbImage ?? json['thumb_image_url'],
      price: productPrice,
      compareAtPrice: comparePrice,
      sku: json['sku'],
      urlSlug: json['url_slug'],
      barcode: variantsList?.isNotEmpty == true
          ? variantsList!.first.barcode
          : json['barcode'],
      vendorId: _parseInt(json['vendor_id']) ?? 0,
      categoryId:
          _parseInt(json['category_id'] ?? json['category']?['id']) ?? 0,
      categoryName: json['category']?['name'] ??
          json['category']?['category_detail']?['translation']?[0]?['name'],
      isActive: json['is_active'] == 1 ||
          json['is_live'] == 1 ||
          json['status'] == 'active' ||
          json['status'] == 1,
      isFeatured: json['is_featured'] == 1,
      isNew: json['is_new'] == 1,
      hasVariants:
          json['has_variant'] == 1 || (variantsList?.isNotEmpty ?? false),
      stockQuantity: variantsList?.isNotEmpty == true
          ? _parseInt(variantsList!.first.stockQuantity)
          : _parseInt(json['stock_quantity'] ?? json['quantity']),
      rating: _parseDouble(json['averageRating'] ?? json['rating']),
      reviewCount: _parseInt(json['review_count']),
      preparationTime: json['preparation_time'],
      weight: _parseDouble(json['weight']),
      weightUnit: json['weight_unit'],
      tags: json['tags'] != null
          ? (json['tags'] is List
              ? List<String>.from(json['tags'].map((tag) => tag.toString()))
              : [json['tags'].toString()])
          : null,
      variants: variantsList,
      addons: json['add_on'] != null
          ? (json['add_on'] as List).map((a) => AddonModel.fromJson(a)).toList()
          : null,
      media: json['media'] != null
          ? (json['media'] as List).map((m) => MediaModel.fromJson(m)).toList()
          : null,
      vendor: json['vendor'] != null
          ? VendorInfoModel.fromJson(json['vendor'])
          : null,
      translations: translations,
      unit: json['unit'],
      minimumOrderCount: _parseDouble(json['minimum_order_count']) ?? 1,
      batchCount: _parseDouble(json['batch_count']) ?? 1,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      sellWhenOutOfStock: _parseInt(json['sell_when_out_of_stock']) == 1,
      hasInventory: _parseInt(json['has_inventory']) == 1,
      typeId: _parseInt(json['type_id']),
    );
    
    // Log critical field parsing for debugging
    StockDebugLogger.logApiParsing(
      json: json,
      field: 'has_inventory',
      rawValue: json['has_inventory'],
      parsedValue: _parseInt(json['has_inventory']) == 1,
    );
    StockDebugLogger.logApiParsing(
      json: json,
      field: 'type_id',
      rawValue: json['type_id'],
      parsedValue: _parseInt(json['type_id']),
    );
    
    return product;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'body_html': bodyHtml,
      'image': image,
      'thumb_image': thumbImage,
      'price': price,
      'compare_at_price': compareAtPrice,
      'sku': sku,
      'url_slug': urlSlug,
      'barcode': barcode,
      'vendor_id': vendorId,
      'category_id': categoryId,
      'category_name': categoryName,
      'is_active': isActive,
      'is_featured': isFeatured,
      'is_new': isNew,
      'has_variants': hasVariants,
      'stock_quantity': stockQuantity,
      'rating': rating,
      'review_count': reviewCount,
      'preparation_time': preparationTime,
      'weight': weight,
      'weight_unit': weightUnit,
      'tags': tags,
      'variants': variants?.map((v) => v.toJson()).toList(),
      'addons': addons?.map((a) => a.toJson()).toList(),
      'media': media?.map((m) => m.toJson()).toList(),
      'vendor': vendor?.toJson(),
      'translations': translations?.map((t) => t.toJson()).toList(),
      'unit': unit,
      'minimum_order_count': minimumOrderCount,
      'batch_count': batchCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sell_when_out_of_stock': sellWhenOutOfStock,
      'has_inventory': hasInventory,
      'type_id': typeId,
    };
  }

  // Helper methods
  double get finalPrice {
    if (hasVariants &&
        selectedVariantId != null &&
        variants != null &&
        variants!.isNotEmpty) {
      final variant = variants!.firstWhere(
        (v) => v.id.toString() == selectedVariantId,
        orElse: () =>
            variants!.first, // Fallback, consider if this is always desired
      );
      return variant.price; // Assuming VariantModel has 'price'
    }
    return price;
  }

  double get totalPrice {
    double currentFinalPrice =
        finalPrice; // Use the getter that considers variants
    double total = currentFinalPrice * quantity;

    if (selectedAddonIds.isNotEmpty && addons != null && addons!.isNotEmpty) {
      for (String addonId in selectedAddonIds) {
        final addon = addons!.firstWhere(
          (a) => a.id.toString() == addonId,
          // Consider a safer orElse or ensure addonId is always valid
        );
        total += addon.price * quantity; // Assuming AddonModel has 'price'
      }
    }
    return total;
  }

  String get displayPrice {
    // This displays the base or selected variant's price, not considering addons or quantity.
    final currentPrice = finalPrice;
    if (compareAtPrice != null && compareAtPrice! > currentPrice) {
      // You might want to display compareAtPrice for the selected variant if it exists
      return 'AED ${currentPrice.toStringAsFixed(2)}'; // Showing discounted price
    }
    return 'AED ${currentPrice.toStringAsFixed(2)}';
  }
  
  /// Get total quantity across all variants (for products with variants)
  /// or the main stock quantity (for simple products)
  int get productTotalQuantity {
    if (hasVariants && variants != null && variants!.isNotEmpty) {
      // Sum up all variant quantities
      return variants!.fold(0, (sum, variant) => sum + (variant.stockQuantity ?? 0));
    }
    // For simple products, return the main stock quantity
    return stockQuantity ?? 0;
  }

// Goes inside your ProductModel class

  bool get isInStock {
    // Calculate the result first
    bool result = _calculateIsInStock();
    
    // Log the evaluation
    StockDebugLogger.logProductStock(
      productId: id,
      productName: name,
      isActive: isActive,
      hasInventory: hasInventory,
      stockQuantity: productTotalQuantity,
      sellWhenOutOfStock: sellWhenOutOfStock,
      typeId: typeId,
      finalIsInStock: result,
    );
    
    return result;
  }
  
  bool _calculateIsInStock() {

    // NOTE: React Native does NOT check isActive for stock availability
    // Commenting this out to match React Native behavior
    // if (!isActive) {
    //   return false; // Product is not active, so definitely not "in stock" for purchasing
    // }

    // React Native logic: Show add to cart if ANY of these conditions are true:
    // 1. has_inventory == 0 (inventory not tracked)
    // 2. productTotalQuantity > 0 (has stock)
    // 3. typeId == 8 (special type)
    // 4. sell_when_out_of_stock is true

    // Check for special type (React Native checks for typeId == 8)
    if (typeId == 8) {
      return true;
    }

    // PRIORITY: If the product is marked to be sold even when there is no stock,
    // it's considered "in stock" or "orderable" for purchasing purposes.
    if (sellWhenOutOfStock) {
      return true;
    }

    // If inventory is not tracked for this product (and sellWhenOutOfStock is false),
    // it's considered always available (if active).
    if (!hasInventory) {
      return true;
    }
    
    // Check if product has stock (React Native checks productTotalQuantity > 0)
    if (productTotalQuantity > 0) {
      return true;
    }

    // If we reach here, all conditions have failed:
    // - typeId != 8 (not a special service)
    // - sellWhenOutOfStock is false
    // - hasInventory is true (inventory is tracked)
    // - productTotalQuantity is 0 (no stock)
    return false; // Out of stock
  }
}
