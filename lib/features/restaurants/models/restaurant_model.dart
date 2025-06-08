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
    // Handle nested data structure from API
    Map<String, dynamic> vendorData = json;
    if (json['vendor'] != null && json['vendor'] is Map) {
      vendorData = json['vendor'] as Map<String, dynamic>;
    }
    
    // Handle nested image object from V2 API
    String? imageUrl;
    
    // Try logo first (for vendor listings), then image
    if (vendorData['logo'] != null) {
      if (vendorData['logo'] is Map<String, dynamic>) {
        // New format: logo is an object with image_s3_url
        final logoData = vendorData['logo'] as Map<String, dynamic>;
        imageUrl = logoData['image_s3_url'] ?? logoData['proxy_url'];
      } else {
        // Old format: logo is a string
        imageUrl = ImageUtils.buildVendorLogoUrl(vendorData['logo']);
      }
    } else if (vendorData['image'] != null) {
      imageUrl = ImageUtils.buildImageUrl(vendorData['image']);
    } else if (json['logo'] != null) {
      // Fallback to original json
      if (json['logo'] is Map<String, dynamic>) {
        final logoData = json['logo'] as Map<String, dynamic>;
        imageUrl = logoData['image_s3_url'] ?? logoData['proxy_url'];
      } else {
        imageUrl = ImageUtils.buildVendorLogoUrl(json['logo']);
      }
    }
    
    // Handle nested name from translation
    String? vendorName = vendorData['name'];
    if (vendorName == null && vendorData['translation'] is List) {
      final translations = vendorData['translation'] as List;
      if (translations.isNotEmpty && translations[0] is Map) {
        vendorName = translations[0]['name'];
      }
    }
    
    // Extract delivery time and fee from vendor data
    String? deliveryTimeStr;
    double? deliveryFeeAmount;
    
    if (vendorData['delivery_time'] != null) {
      deliveryTimeStr = vendorData['delivery_time'].toString();
    } else if (vendorData['deliveryTime'] != null) {
      deliveryTimeStr = '${vendorData['deliveryTime']} min';
    } else if (vendorData['timeofLineOfSightDistance'] != null) {
      deliveryTimeStr = vendorData['timeofLineOfSightDistance'].toString();
    } else if (vendorData['avg_delivery_time'] != null) {
      deliveryTimeStr = '${vendorData['avg_delivery_time']} min';
    }
    
    if (vendorData['delivery_fee'] != null) {
      try {
        deliveryFeeAmount = double.parse(vendorData['delivery_fee'].toString());
      } catch (e) {
        deliveryFeeAmount = null;
      }
    } else if (vendorData['delivery_charges'] != null) {
      try {
        deliveryFeeAmount = double.parse(vendorData['delivery_charges'].toString());
      } catch (e) {
        deliveryFeeAmount = null;
      }
    }
    
    return RestaurantModel(
      id: vendorData['id'] ?? json['id'],
      name: vendorName ?? json['vendor_name'] ?? 'Restaurant',
      description: HtmlUtils.safeExtractText(vendorData['description'] ?? vendorData['desc'] ?? vendorData['short_desc'] ?? json['description'] ?? json['desc']),
      image: imageUrl,
      images: vendorData['images'] != null ? List<String>.from(vendorData['images']) : null,
      rating: _parseDouble(vendorData['rating'] ?? vendorData['vendorRating'] ?? vendorData['avg_rating']),
      reviewCount: _parseInt(vendorData['review_count'] ?? vendorData['reviews_count'] ?? vendorData['selling_count']),
      address: vendorData['address'],
      latitude: _parseDouble(vendorData['latitude']),
      longitude: _parseDouble(vendorData['longitude']),
      distance: _parseDistanceFromString(vendorData['lineOfSightDistance']) ?? _parseDouble(vendorData['distance']),
      deliveryTime: deliveryTimeStr,
      deliveryFee: deliveryFeeAmount,
      timeofLineOfSightDistance: _parseInt(vendorData['timeofLineOfSightDistance'] ?? vendorData['deliveryTime'] ?? vendorData['order_pre_time']),
      timeofLineOfSightDistanceStr: vendorData['timeofLineOfSightDistance']?.toString(),
      minimumOrderAmount: _parseDouble(vendorData['minimum_order_amount'] ?? vendorData['min_order_value'] ?? vendorData['minimum_price'] ?? vendorData['order_min_amount']),
      isOpen: _determineIsOpen(vendorData),
      isDeliveryAvailable: vendorData['delivery'] == 1 || vendorData['delivery'] == true || vendorData['is_delivery_available'] == 1 || vendorData['is_delivery_available'] == true,
      isPickupAvailable: vendorData['takeaway'] == 1 || vendorData['takeaway'] == true || vendorData['is_pickup_available'] == 1 || vendorData['is_pickup_available'] == true,
      phoneNumber: vendorData['phone_no'] ?? vendorData['phone_number'] ?? vendorData['phone'],
      email: vendorData['email'],
      cuisines: _extractCuisinesList(vendorData),
      businessHours: vendorData['business_hours'],
      isFeatured: vendorData['is_featured'] == 1 || vendorData['is_featured'] == true,
      isPureVeg: vendorData['is_pure_veg'] == 1 || vendorData['is_pure_veg'] == true,
      priceRange: vendorData['price_range'],
      logo: _extractImageUrl(vendorData['logo']),
      banner: _extractBannerUrl(vendorData['banner']),
      isFavorite: vendorData['is_wishlist'] == 1 || vendorData['is_favorite'] == 1,
      tags: vendorData['tags'] != null ? List<String>.from(vendorData['tags']) : null,
      minimumOrder: _parseDouble(vendorData['minimum_order_amount'] ?? vendorData['min_order_value'] ?? vendorData['minimum_price'] ?? vendorData['order_min_amount']),
      products: _extractProductsList(json['products'] ?? vendorData['products']),
      categories: _extractCategoriesList(json['categories'] ?? vendorData['categories']),
      slug: vendorData['slug'],
      showSlot: _parseInt(vendorData['show_slot']),
      adminRating: _parseDouble(vendorData['admin_rating']),
      closedStoreOrderScheduled: _parseInt(vendorData['closed_store_order_scheduled']),
      isWishlist: vendorData['is_wishlist'] == 1 || vendorData['is_wishlist'] == true,
      promoDiscount: vendorData['promo_discount']?.toString(),
      categoriesList: vendorData['categoriesList'] ?? vendorData['type_title'],
      sellingCount: _parseInt(vendorData['selling_count']),
      slotdateStartEndTime: vendorData['slotdate_start_end_time']?.toString(),
      slotStartEndTime: vendorData['slot_start_end_time']?.toString(),
      productAvgAverageRating: _parseDouble(vendorData['product_avg_average_rating']),
      vendorRating: vendorData['vendorRating']?.toString(),
      typeTitle: vendorData['type_title'],
      isVendorClosed: vendorData['is_vendor_closed'] == 1 || vendorData['is_vendor_closed'] == true,
      dateWithSlots: vendorData['date_with_slots'] is List ? vendorData['date_with_slots'] : null,
      delaySlot: _parseInt(vendorData['delaySlot']),
      deliveryTime8: vendorData['delivery_time']?.toString(),
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