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

  // Time-based availability fields
  final bool isLimitedTime; // From JSON: "is_limited_time"
  final DateTime? availableFrom; // From JSON: "available_from"
  final DateTime? availableUntil; // From JSON: "available_until"

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
    required this.isLimitedTime,
    this.availableFrom,
    this.availableUntil,
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

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('Error parsing DateTime from: $value, error: $e');
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

  static String? _extractCategoryName(Map<String, dynamic> json) {
    // Direct category_name field
    if (json['category_name'] != null && json['category_name'] is String) {
      return json['category_name'];
    }
    
    // Try translation_category_name (from vendor API)
    if (json['translation_category_name'] != null && json['translation_category_name'] is String) {
      return json['translation_category_name'];
    }
    
    // Category object with name
    if (json['category'] != null) {
      final category = json['category'];
      if (category is Map) {
        // Direct name field
        if (category['name'] != null && category['name'] is String) {
          return category['name'];
        }
        
        // Category detail with translation
        if (category['category_detail'] != null) {
          final detail = category['category_detail'];
          if (detail is Map && detail['translation'] != null) {
            final translation = detail['translation'];
            if (translation is List && translation.isNotEmpty) {
              final firstTranslation = translation[0];
              if (firstTranslation is Map && firstTranslation['name'] != null) {
                return firstTranslation['name'].toString();
              }
            }
          }
        }
      }
    }
    
    return null;
  }

  static VendorInfoModel? _parseVendor(dynamic vendorData) {
    if (vendorData == null) return null;
    
    try {
      if (vendorData is Map<String, dynamic>) {
        return VendorInfoModel.fromJson(vendorData);
      }
    } catch (e) {
      debugPrint('Error parsing vendor: $e');
    }
    
    return null;
  }
  
  static VendorInfoModel? _parseVendorFromProduct(Map<String, dynamic> json) {
    // Try to parse vendor from vendor field
    final vendor = _parseVendor(json['vendor']);
    if (vendor != null) return vendor;
    
    // Fallback: Create vendor from vendor_name field if available
    if (json['vendor_name'] != null && json['vendor_name'] is String && 
        json['vendor_name'].toString().isNotEmpty) {
      return VendorInfoModel(
        id: _parseInt(json['vendor_id']) ?? 0,
        name: json['vendor_name'],
        slug: json['vendor_slug'],
      );
    }
    
    return null;
  }

  static List<AddonModel>? _parseAddons(dynamic addonsData) {
    if (addonsData == null) return null;
    
    try {
      if (addonsData is List) {
        return addonsData.map((a) => AddonModel.fromJson(a)).toList();
      }
    } catch (e) {
      debugPrint('Error parsing addons: $e');
    }
    
    return null;
  }

  static List<MediaModel>? _parseMedia(dynamic mediaData) {
    if (mediaData == null) return null;
    
    try {
      if (mediaData is List) {
        return mediaData.map((m) => MediaModel.fromJson(m)).toList();
      }
    } catch (e) {
      debugPrint('Error parsing media: $e');
    }
    
    return null;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    debugPrint('=== ProductModel.fromJson Debug ===');
    debugPrint('JSON keys: ${json.keys.toList()}');
    debugPrint('JSON vals: ${json.values.toList()}');

    // Get the translation for the current language (default to language_id = 1)
    List<TranslationModel>? translations;
    try {
      if (json['translation'] != null) {
        if (json['translation'] is List) {
          translations = (json['translation'] as List)
              .map((t) => TranslationModel.fromJson(t))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error parsing translations: $e');
      translations = null;
    }

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
        primaryImage =
            'https://yabalash-assets.s3.me-central-1.amazonaws.com/$imagePath';
        debugPrint('🖼️ Using direct path image: $primaryImage');
      }
    }

    debugPrint('full json is ${json}');

    // Handle nested media structure (if no direct path or as fallback)
    if (primaryImage == null &&
        json['media'] != null &&
        (json['media'] as List).isNotEmpty) {
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
    try {
      if (json['variant'] != null && json['variant'] is List && (json['variant'] as List).isNotEmpty) {
        debugPrint(
            'Found variants in variant key: ${(json['variant'] as List).length}');
        variantsList = (json['variant'] as List)
            .whereType<Map<String, dynamic>>()
            .map((v) => VariantModel.fromJson(v))
            .toList();
      } else if (json['variants'] != null && json['variants'] is List && (json['variants'] as List).isNotEmpty) {
        debugPrint(
            'Found variants in variants key: ${(json['variants'] as List).length}');
        variantsList = (json['variants'] as List)
            .whereType<Map<String, dynamic>>()
            .map((v) => VariantModel.fromJson(v))
            .toList();
      }
    } catch (e) {
      debugPrint('Error parsing variants: $e');
      variantsList = null;
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
      // Also check for variant_price from vendor API
      productPrice = _parseDouble(json['variant_price']) ??
          _parseDouble(json['price_numeric']) ??
          _parseDouble(json['price']) ??
          0.0;
      comparePrice = _parseDouble(json['compare_price_numeric']) ??
          _parseDouble(json['compare_at_price']);
      debugPrint('Using direct price: $productPrice, compare: $comparePrice');
      debugPrint(
          '🔍 Price debug - variant_price: ${json['variant_price']}, price_numeric: ${json['price_numeric']}, price: ${json['price']}');
      debugPrint(
          '🔍 Compare debug - compare_price_numeric: ${json['compare_price_numeric']}, compare_at_price: ${json['compare_at_price']}');
    }

    final product = ProductModel(
      id: _parseInt(json['id']) ?? 0,
      name: primaryTranslation?.title ?? json['translation_title'] ?? json['title'] ?? json['name'] ?? '',
      description: HtmlUtils.safeExtractText(primaryTranslation?.bodyHtml ??
          json['translation_description'] ??
          json['description'] ??
          primaryTranslation?.metaDescription),
      bodyHtml: primaryTranslation?.bodyHtml ?? json['body_html'],
      image: primaryImage ??
          _extractImageUrl(json['image']) ??
          json['product_image'] ??
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
      categoryName: _extractCategoryName(json),
      isActive: json['is_currently_available'] == true ||
          json['is_active'] == 1 ||
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
      addons: _parseAddons(json['add_on']),
      media: _parseMedia(json['media']),
      vendor: _parseVendorFromProduct(json),
      translations: translations,
      unit: json['unit'],
      minimumOrderCount: _parseDouble(json['minimum_order_count']) ?? 1,
      batchCount: _parseDouble(json['batch_count']) ?? 1,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      sellWhenOutOfStock: _parseInt(json['sell_when_out_of_stock']) == 1,
      hasInventory: _parseInt(json['has_inventory']) == 1,
      typeId: _parseInt(json['type_id']),
      isLimitedTime: json['is_limited_time'] == true || json['is_limited_time'] == 1,
      availableFrom: _parseDateTime(json['available_from']),
      availableUntil: _parseDateTime(json['available_until']),
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
      'is_limited_time': isLimitedTime,
      'available_from': availableFrom?.toIso8601String(),
      'available_until': availableUntil?.toIso8601String(),
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
      return variants!
          .fold(0, (sum, variant) => sum + (variant.stockQuantity ?? 0));
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

    // Check time-based availability first
    if (isLimitedTime) {
      final now = DateTime.now();
      
      // If product has availability window, check if current time is within range
      if (availableFrom != null && now.isBefore(availableFrom!)) {
        return false; // Product not yet available
      }
      
      if (availableUntil != null && now.isAfter(availableUntil!)) {
        return false; // Product availability has expired
      }
    }

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

  /// Check if product is currently available based on time restrictions
  bool get isCurrentlyAvailable {
    if (!isLimitedTime) {
      return true; // No time restrictions
    }
    
    final now = DateTime.now();
    
    // Check if current time is within availability window
    if (availableFrom != null && now.isBefore(availableFrom!)) {
      return false; // Not yet available
    }
    
    if (availableUntil != null && now.isAfter(availableUntil!)) {
      return false; // No longer available
    }
    
    return true; // Currently available
  }

  /// Get time until product becomes available (if not yet available)
  Duration? get timeUntilAvailable {
    if (!isLimitedTime || availableFrom == null) {
      return null;
    }
    
    final now = DateTime.now();
    if (now.isBefore(availableFrom!)) {
      return availableFrom!.difference(now);
    }
    
    return null; // Already available or past availability
  }

  /// Get time until product expires (if currently available)
  Duration? get timeUntilExpires {
    if (!isLimitedTime || availableUntil == null) {
      return null;
    }
    
    final now = DateTime.now();
    if (now.isBefore(availableUntil!)) {
      return availableUntil!.difference(now);
    }
    
    return null; // Already expired or no expiry
  }
}
