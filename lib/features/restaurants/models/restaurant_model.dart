import 'package:flutter/foundation.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/html_utils.dart';

class RestaurantModel {
  final int? id;
  final String? name;
  final String? description;
  final String? image;
  final List<String>? images;
  final double? rating;
  final int? reviewCount;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? distance;
  final String? deliveryTime;
  final double? deliveryFee;
  final int? timeofLineOfSightDistance; // Time in minutes from API
  final String? timeofLineOfSightDistanceStr; // Time range string from API
  final double? minimumOrderAmount;
  final bool? isOpen;
  final bool? isDeliveryAvailable;
  final bool? isPickupAvailable;
  final String? phoneNumber;
  final String? email;
  final List<String>? cuisines;
  final Map<String, dynamic>? businessHours;
  final bool? isFeatured;
  final bool? isPureVeg;
  final String? priceRange; // $, $$, $$$, $$$$
  final String? logo;
  final String? banner;
  final bool? isFavorite;
  final List<String>? tags;
  final double? minimumOrder;
  final List<dynamic>? products;  // Products that come directly with vendor data
  final List<dynamic>? categories;  // Categories that come with vendor data
  final String? slug;
  final int? showSlot;
  final double? adminRating;
  final int? closedStoreOrderScheduled;
  final bool? isWishlist;
  final String? promoDiscount;
  final String? categoriesList;
  final int? sellingCount;
  final String? slotdateStartEndTime;
  final String? slotStartEndTime;
  final double? productAvgAverageRating;
  final String? vendorRating;
  final String? typeTitle;
  final bool? isVendorClosed;
  final List<dynamic>? dateWithSlots;
  final int? delaySlot;
  final String? deliveryTime8; // delivery_time field from API

  RestaurantModel({
    this.id,
    this.name,
    this.description,
    this.image,
    this.images,
    this.rating,
    this.reviewCount,
    this.address,
    this.latitude,
    this.longitude,
    this.distance,
    this.deliveryTime,
    this.deliveryFee,
    this.timeofLineOfSightDistance,
    this.timeofLineOfSightDistanceStr,
    this.minimumOrderAmount,
    this.isOpen,
    this.isDeliveryAvailable,
    this.isPickupAvailable,
    this.phoneNumber,
    this.email,
    this.cuisines,
    this.businessHours,
    this.isFeatured,
    this.isPureVeg,
    this.priceRange,
    this.logo,
    this.banner,
    this.isFavorite,
    this.tags,
    this.minimumOrder,
    this.products,
    this.categories,
    this.slug,
    this.showSlot,
    this.adminRating,
    this.closedStoreOrderScheduled,
    this.isWishlist,
    this.promoDiscount,
    this.categoriesList,
    this.sellingCount,
    this.slotdateStartEndTime,
    this.slotStartEndTime,
    this.productAvgAverageRating,
    this.vendorRating,
    this.typeTitle,
    this.isVendorClosed,
    this.dateWithSlots,
    this.delaySlot,
    this.deliveryTime8,
  });

  // Get formatted delivery time range (e.g., "30-35 mins")
  String? get formattedDeliveryTime {
    // First check if we have the string version from API
    if (timeofLineOfSightDistanceStr != null && timeofLineOfSightDistanceStr!.isNotEmpty) {
      return timeofLineOfSightDistanceStr;
    }
    
    // Otherwise calculate from integer value
    if (timeofLineOfSightDistance != null) {
      final baseTime = timeofLineOfSightDistance!;
      final maxTime = baseTime + 5;
      
      // Convert to hours if >= 60 minutes
      if (baseTime >= 60) {
        final hours = baseTime ~/ 60;
        final maxHours = maxTime ~/ 60;
        if (hours == maxHours) {
          return '${hours}h';
        } else {
          return '$hours-${maxHours}h';
        }
      } else {
        return '$baseTime-$maxTime mins';
      }
    }
    
    // Fallback to deliveryTime if available
    return deliveryTime;
  }

  // Get formatted distance (e.g., "1.2 km" or "800 m")
  String? get formattedDistance {
    if (distance == null) return null;
    
    final distanceInKm = distance!;
    if (distanceInKm < 1) {
      // Show in meters if less than 1 km
      final meters = (distanceInKm * 1000).round();
      return '$meters m';
    } else {
      // Show in kilometers with 1 decimal place
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
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
        return null;
      }
    }
    return null;
  }

  static double? _parseDistanceFromString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      // Remove " km" suffix and parse
      final distanceStr = value.replaceAll(' km', '').replaceAll('km', '').trim();
      return _parseDouble(distanceStr);
    }
    return _parseDouble(value);
  }
  
  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    // Handle nested image object from V2 API
    String? imageUrl;
    
    // Try logo first (for vendor listings), then image
    if (json['logo'] != null) {
      if (json['logo'] is Map<String, dynamic>) {
        // New format: logo is an object with image_s3_url
        final logoData = json['logo'] as Map<String, dynamic>;
        imageUrl = logoData['image_s3_url'] ?? logoData['proxy_url'];
      } else {
        // Old format: logo is a string
        imageUrl = ImageUtils.buildVendorLogoUrl(json['logo']);
      }
    } else if (json['image'] != null) {
      imageUrl = ImageUtils.buildImageUrl(json['image']);
    }
    
    // Handle nested name from translation
    String? vendorName = json['name'];
    if (vendorName == null && json['translation'] is List) {
      final translations = json['translation'] as List;
      if (translations.isNotEmpty && translations[0] is Map) {
        vendorName = translations[0]['name'];
      }
    }
    
    // Extract delivery time and fee from vendor data
    String? deliveryTimeStr;
    double? deliveryFeeAmount;
    
    if (json['delivery_time'] != null) {
      deliveryTimeStr = json['delivery_time'].toString();
    } else if (json['deliveryTime'] != null) {
      deliveryTimeStr = '${json['deliveryTime']} min';
    } else if (json['timeofLineOfSightDistance'] != null) {
      deliveryTimeStr = json['timeofLineOfSightDistance'].toString();
    } else if (json['avg_delivery_time'] != null) {
      deliveryTimeStr = '${json['avg_delivery_time']} min';
    }
    
    if (json['delivery_fee'] != null) {
      try {
        deliveryFeeAmount = double.parse(json['delivery_fee'].toString());
      } catch (e) {
        deliveryFeeAmount = null;
      }
    } else if (json['delivery_charges'] != null) {
      try {
        deliveryFeeAmount = double.parse(json['delivery_charges'].toString());
      } catch (e) {
        deliveryFeeAmount = null;
      }
    }
    
    return RestaurantModel(
      id: json['id'],
      name: vendorName,
      description: HtmlUtils.safeExtractText(json['description'] ?? json['desc']),
      image: imageUrl,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      rating: _parseDouble(json['rating'] ?? json['vendorRating'] ?? json['avg_rating']),
      reviewCount: _parseInt(json['review_count'] ?? json['reviews_count'] ?? json['selling_count']),
      address: json['address'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      distance: _parseDistanceFromString(json['lineOfSightDistance']) ?? _parseDouble(json['distance']),
      deliveryTime: deliveryTimeStr,
      deliveryFee: deliveryFeeAmount,
      timeofLineOfSightDistance: _parseInt(json['timeofLineOfSightDistance'] ?? json['deliveryTime'] ?? json['order_pre_time']),
      timeofLineOfSightDistanceStr: json['timeofLineOfSightDistance']?.toString(),
      minimumOrderAmount: _parseDouble(json['minimum_order_amount'] ?? json['min_order_value'] ?? json['minimum_price']),
      isOpen: _determineIsOpen(json),
      isDeliveryAvailable: json['is_delivery_available'] == 1 || json['is_delivery_available'] == true,
      isPickupAvailable: json['is_pickup_available'] == 1 || json['is_pickup_available'] == true,
      phoneNumber: json['phone_number'] ?? json['phone'],
      email: json['email'],
      cuisines: _extractCuisinesList(json),
      businessHours: json['business_hours'],
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      isPureVeg: json['is_pure_veg'] == 1 || json['is_pure_veg'] == true,
      priceRange: json['price_range'],
      logo: _extractImageUrl(json['logo']),
      banner: _extractBannerUrl(json['banner']),
      isFavorite: json['is_wishlist'] == 1 || json['is_favorite'] == 1,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      minimumOrder: _parseDouble(json['minimum_order_amount'] ?? json['min_order_value'] ?? json['minimum_price']),
      products: _extractProductsList(json['products']),
      categories: _extractCategoriesList(json['categories']),
      slug: json['slug'],
      showSlot: _parseInt(json['show_slot']),
      adminRating: _parseDouble(json['admin_rating']),
      closedStoreOrderScheduled: _parseInt(json['closed_store_order_scheduled']),
      isWishlist: json['is_wishlist'] == 1 || json['is_wishlist'] == true,
      promoDiscount: json['promo_discount']?.toString(),
      categoriesList: json['categoriesList'] ?? json['type_title'],
      sellingCount: _parseInt(json['selling_count']),
      slotdateStartEndTime: json['slotdate_start_end_time']?.toString(),
      slotStartEndTime: json['slot_start_end_time']?.toString(),
      productAvgAverageRating: _parseDouble(json['product_avg_average_rating']),
      vendorRating: json['vendorRating']?.toString(),
      typeTitle: json['type_title'],
      isVendorClosed: json['is_vendor_closed'] == 1 || json['is_vendor_closed'] == true,
      dateWithSlots: json['date_with_slots'] is List ? json['date_with_slots'] : null,
      delaySlot: _parseInt(json['delaySlot']),
      deliveryTime8: json['delivery_time']?.toString(),
    );
  }

  static String? _extractImageUrl(dynamic imageData) {
    if (imageData == null) return null;
    
    try {
      // If it's a Map (new object format), extract the image URL
      if (imageData is Map<String, dynamic>) {
        // Try different URL fields in order of preference
        return imageData['image_s3_url'] ?? 
               imageData['proxy_url'] ?? 
               imageData['image_path'] ?? 
               imageData['image_fit'];
      }
      
      // If it's a string (old format), use ImageUtils to build the URL
      if (imageData is String) {
        return ImageUtils.buildImageUrl(imageData);
      }
    } catch (e) {
      debugPrint('Error extracting image URL from: $imageData, error: $e');
    }
    
    return null;
  }

  static String? _extractBannerUrl(dynamic bannerData) {
    if (bannerData == null) return null;
    
    try {
      // If it's a Map (new object format), extract the banner URL
      if (bannerData is Map<String, dynamic>) {
        // Try different URL fields in order of preference
        return bannerData['image_s3_url'] ?? 
               bannerData['proxy_url'] ?? 
               bannerData['image_path'] ?? 
               bannerData['image_fit'];
      }
      
      // If it's a string (old format), use ImageUtils to build the banner URL
      if (bannerData is String) {
        return ImageUtils.buildVendorBannerUrl(bannerData);
      }
    } catch (e) {
      debugPrint('Error extracting banner URL from: $bannerData, error: $e');
    }
    
    return null;
  }

  static List<dynamic>? _extractProductsList(dynamic productsData) {
    if (productsData == null) return null;
    
    // If it's already a List, return as is
    if (productsData is List) return productsData;
    
    // If it's a Map (paginated response), extract the data field
    if (productsData is Map<String, dynamic>) {
      if (productsData.containsKey('data')) {
        final data = productsData['data'];
        if (data is List) return data;
      }
      // If no 'data' field, return the map as a single-item list
      return [productsData];
    }
    
    return null;
  }
  
  static List<dynamic>? _extractCategoriesList(dynamic categoriesData) {
    if (categoriesData == null) return null;
    
    // If it's already a List, return as is
    if (categoriesData is List) return categoriesData;
    
    // If it's a Map (paginated response), extract the data field
    if (categoriesData is Map<String, dynamic>) {
      if (categoriesData.containsKey('data')) {
        final data = categoriesData['data'];
        if (data is List) return data;
      }
      // If no 'data' field, return the map as a single-item list
      return [categoriesData];
    }
    
    return null;
  }

  static List<String>? _extractCuisinesList(Map<String, dynamic> json) {
    // First check for cuisines array
    if (json['cuisines'] != null && json['cuisines'] is List) {
      return List<String>.from(json['cuisines']);
    }
    
    // Fall back to categoriesList or type_title
    if (json['categoriesList'] != null) {
      return [json['categoriesList'].toString()];
    }
    
    if (json['type_title'] != null) {
      return [json['type_title'].toString()];
    }
    
    return null;
  }

  static bool _determineIsOpen(Map<String, dynamic> json) {
    // Debug print for troubleshooting availability issues
    debugPrint('RestaurantModel._determineIsOpen - Vendor: ${json['name']}');
    debugPrint('  - is_vendor_closed: ${json['is_vendor_closed']}');
    debugPrint('  - is_open: ${json['is_open']}');
    debugPrint('  - show_slot: ${json['show_slot']}');
    debugPrint('  - status: ${json['status']}');
    debugPrint('  - active: ${json['active']}');
    
    // Check if vendor is explicitly closed - this is the most important field
    if (json['is_vendor_closed'] == 1 || json['is_vendor_closed'] == true) {
      debugPrint('  - Result: CLOSED (is_vendor_closed)');
      return false;
    }
    
    // Check positive open indicators first
    if (json['is_open'] == 1 || json['is_open'] == true) {
      debugPrint('  - Result: OPEN (is_open = true)');
      return true;
    }
    
    if (json['status'] == 1 || json['status'] == 'active') {
      debugPrint('  - Result: OPEN (status = active)');
      return true;
    }
    
    if (json['active'] == 1 || json['active'] == true) {
      debugPrint('  - Result: OPEN (active = true)');
      return true;
    }
    
    // Check for explicit closed indicators
    if (json['is_open'] == 0 || json['is_open'] == false) {
      debugPrint('  - Result: CLOSED (is_open = false)');
      return false;
    }
    
    if (json['status'] == 0 || json['status'] == 'inactive') {
      debugPrint('  - Result: CLOSED (status = inactive)');
      return false;
    }
    
    if (json['active'] == 0 || json['active'] == false) {
      debugPrint('  - Result: CLOSED (active = false)');
      return false;
    }
    
    // IMPORTANT: show_slot: 0 does NOT mean closed! 
    // show_slot indicates whether to show time slots, not restaurant availability
    // Many restaurants have show_slot: 0 but are still open for ordering
    if (json['show_slot'] == 0 && json['is_vendor_closed'] != 1) {
      debugPrint('  - Result: OPEN (show_slot = 0 but not vendor_closed)');
      return true;
    }
    
    // Default to open if no clear closed indicators (most permissive approach)
    // This matches the behavior seen in your API response where restaurants 
    // with show_slot: 0 should still appear as available
    debugPrint('  - Result: OPEN (default - no clear closed indicators)');
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'images': images,
      'rating': rating,
      'review_count': reviewCount,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'delivery_time': deliveryTime,
      'delivery_fee': deliveryFee,
      'minimum_order_amount': minimumOrderAmount,
      'is_open': isOpen == true ? 1 : 0,
      'is_delivery_available': isDeliveryAvailable == true ? 1 : 0,
      'is_pickup_available': isPickupAvailable == true ? 1 : 0,
      'phone_number': phoneNumber,
      'email': email,
      'cuisines': cuisines,
      'business_hours': businessHours,
      'is_featured': isFeatured == true ? 1 : 0,
      'is_pure_veg': isPureVeg == true ? 1 : 0,
      'price_range': priceRange,
    };
  }
}