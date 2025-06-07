import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/api_response.dart';

class ProductVariantDetails {
  final int productId;
  final String sku;
  final String title;
  final String? description;
  final int vendorId;
  final int categoryId;
  final bool hasVariant;
  final bool hasInventory;
  final bool sellWhenOutOfStock;
  final int minimumOrderCount;
  final int batchCount;
  final List<ProductVariant> variants;
  final List<AddonSet> addonSets;

  ProductVariantDetails({
    required this.productId,
    required this.sku,
    required this.title,
    this.description,
    required this.vendorId,
    required this.categoryId,
    required this.hasVariant,
    required this.hasInventory,
    required this.sellWhenOutOfStock,
    required this.minimumOrderCount,
    required this.batchCount,
    required this.variants,
    required this.addonSets,
  });

  factory ProductVariantDetails.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;
    
    return ProductVariantDetails(
      productId: product['id'],
      sku: product['sku'],
      title: product['title'],
      description: product['description'],
      vendorId: product['vendor_id'],
      categoryId: product['category_id'],
      hasVariant: product['has_variant'] == 1,
      hasInventory: product['has_inventory'] == 1,
      sellWhenOutOfStock: product['sell_when_out_of_stock'] == 1,
      minimumOrderCount: product['minimum_order_count'] ?? 1,
      batchCount: product['batch_count'] ?? 1,
      variants: (json['variants'] as List?)
          ?.map((v) => ProductVariant.fromJson(v))
          .toList() ?? [],
      addonSets: (json['addon_sets'] as List?)
          ?.map((a) => AddonSet.fromJson(a))
          .toList() ?? [],
    );
  }
}

class ProductVariant {
  final int id;
  final String sku;
  final String? title;
  final double price;
  final double? compareAtPrice;
  final int? quantityAvailable;
  final String? barcode;
  final double? containerCharges;
  final double markupPrice;

  ProductVariant({
    required this.id,
    required this.sku,
    this.title,
    required this.price,
    this.compareAtPrice,
    this.quantityAvailable,
    this.barcode,
    this.containerCharges,
    required this.markupPrice,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      sku: json['sku'],
      title: json['title'],
      price: double.parse(json['price'].toString()),
      compareAtPrice: json['compare_at_price'] != null 
          ? double.parse(json['compare_at_price'].toString())
          : null,
      quantityAvailable: json['quantity_available'],
      barcode: json['barcode'],
      containerCharges: json['container_charges'] != null
          ? double.parse(json['container_charges'].toString())
          : null,
      markupPrice: double.parse((json['markup_price'] ?? 0).toString()),
    );
  }
}

class AddonSet {
  final int addonId;
  final String title;
  final int minSelect;
  final int maxSelect;
  final List<AddonOption> addonOptions;

  AddonSet({
    required this.addonId,
    required this.title,
    required this.minSelect,
    required this.maxSelect,
    required this.addonOptions,
  });

  factory AddonSet.fromJson(Map<String, dynamic> json) {
    return AddonSet(
      addonId: json['addon_id'],
      title: json['title'],
      minSelect: json['min_select'] ?? 0,
      maxSelect: json['max_select'] ?? 1,
      addonOptions: (json['addon_options'] as List?)
          ?.map((o) => AddonOption.fromJson(o))
          .toList() ?? [],
    );
  }
}

class AddonOption {
  final int id;
  final String title;
  final double price;

  AddonOption({
    required this.id,
    required this.title,
    required this.price,
  });

  factory AddonOption.fromJson(Map<String, dynamic> json) {
    return AddonOption(
      id: json['id'],
      title: json['title'],
      price: double.parse(json['price'].toString()),
    );
  }
}

class ProductVariantService {
  final ApiService _apiService;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  ProductVariantService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Helper method to get timezone string in format like "+03" or "-05"
  String _getTimezoneString() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final hours = offset.inHours.abs();
    final minutes = (offset.inMinutes.abs() % 60);
    final sign = offset.isNegative ? '-' : '+';
    return minutes > 0 
        ? '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}'
        : '$sign${hours.toString().padLeft(2, '0')}';
  }

  // Helper method to get common headers
  Future<Map<String, String>> _getHeaders() async {
    String deviceId = '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await _deviceInfo.androidInfo;
      deviceId = androidInfo.id ?? '';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
    }

    final prefs = await SharedPreferences.getInstance();
    final countryCode = prefs.getString('countryCode') ?? '2b5f69';
    final currencyId = prefs.getString('currencyId') ?? '5';
    final language = prefs.getString('language') ?? '1';

    return {
      'systemuser': deviceId,
      'timezone': _getTimezoneString(),
      'code': countryCode,
      'currency': currencyId,
      'language': language,
    };
  }

  Future<ApiResponse<ProductVariantDetails>> getProductVariantDetails(String sku) async {
    try {
      debugPrint('=== FETCHING PRODUCT VARIANT DETAILS ===');
      debugPrint('SKU: $sku');

      final headers = await _getHeaders();

      final response = await _apiService.get(
        '/product-variant-details/$sku',
        headers: headers,
      );

      if (response.success && response.data != null) {
        final details = ProductVariantDetails.fromJson(response.data);
        
        debugPrint('Product ID: ${details.productId}');
        debugPrint('Variants count: ${details.variants.length}');
        if (details.variants.isNotEmpty) {
          debugPrint('First variant ID: ${details.variants.first.id}');
        }
        debugPrint('Addon sets count: ${details.addonSets.length}');
        
        return ApiResponse.success(
          data: details,
          message: response.message ?? 'Product variant details loaded successfully',
        );
      } else {
        return ApiResponse.error(
          message: response.message ?? 'Failed to load product variant details',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to load product variant details';
      
      if (e.response?.data != null) {
        try {
          if (e.response!.data is Map) {
            final responseData = e.response!.data as Map<String, dynamic>;
            errorMessage = responseData['message'] ?? errorMessage;
          }
        } catch (_) {}
      }
      
      return ApiResponse.error(message: errorMessage);
    } catch (e) {
      debugPrint('Error getting product variant details: $e');
      return ApiResponse.error(
        message: 'Failed to load product variant details',
      );
    }
  }
}