import 'package:flutter/foundation.dart';

class OrderModel {
  final int id;
  final int? orderId; // The actual order ID (parent order)
  final int? vendorId; // The vendor ID for this specific order
  final int userId;
  final int? addressId;
  final int statusId;
  final String status;
  final double totalAmount;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? deliveryType;
  final String? scheduledDate;
  final String? createdAt;
  final String? updatedAt;
  final List<OrderProductModel>? products;
  final OrderVendorModel? vendor;
  final OrderAddressModel? address;
  final String? orderNumber;
  final List<OrderVendorDetailModel>? vendors;
  
  // Additional fields from API
  final double? subtotalAmount;
  final double? taxableAmount;
  final double? totalDeliveryFee;
  final double? totalServiceFee;
  final double? discountAmount;
  final double? tipAmount;
  final double? loyaltyPointsUsed;
  final double? loyaltyPointsEarned;
  final double? loyaltyAmountSaved;
  final String? luxuryOptionName; // Pickup/Delivery/Dine-in
  final String? commentForVendor;
  final String? specificInstructions;
  final List<Map<String, dynamic>>? tipOptions;
  final int? type;
  final String? couponCode;
  final double? couponDiscount;
  final String? userName;
  final Map<String, dynamic>? userImage;
  
  // Additional fields for React Native parity
  final String? scheduledDateTime;
  final String? eta;
  final OrderStatusModel? orderStatus;
  final int? editRequestId;
  final bool? isEdited;
  final String? cancelRequestBy;
  final int? cartId;
  
  // Missing fields from order details
  final double? totalDiscount;
  final double? payableAmount;
  final String? createdDate;
  final PaymentOptionModel? paymentOption;

  OrderModel({
    required this.id,
    this.orderId,
    this.vendorId,
    required this.userId,
    this.addressId,
    required this.statusId,
    required this.status,
    required this.totalAmount,
    this.paymentStatus,
    this.paymentMethod,
    this.deliveryType,
    this.scheduledDate,
    this.createdAt,
    this.updatedAt,
    this.products,
    this.vendor,
    this.address,
    this.orderNumber,
    this.vendors,
    this.subtotalAmount,
    this.taxableAmount,
    this.totalDeliveryFee,
    this.totalServiceFee,
    this.discountAmount,
    this.tipAmount,
    this.loyaltyPointsUsed,
    this.loyaltyPointsEarned,
    this.loyaltyAmountSaved,
    this.luxuryOptionName,
    this.commentForVendor,
    this.specificInstructions,
    this.tipOptions,
    this.type,
    this.couponCode,
    this.couponDiscount,
    this.userName,
    this.userImage,
    this.scheduledDateTime,
    this.eta,
    this.orderStatus,
    this.editRequestId,
    this.isEdited,
    this.cancelRequestBy,
    this.cartId,
    this.totalDiscount,
    this.payableAmount,
    this.createdDate,
    this.paymentOption,
  });

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

  static String _parseString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    debugPrint('=== Parsing OrderModel ===');
    debugPrint('JSON keys: ${json.keys.toList()}');
    
    try {
      debugPrint('Parsing id: ${json['id']} (${json['id'].runtimeType})');
      debugPrint('Parsing payment_status: ${json['payment_status']} (${json['payment_status'].runtimeType})');
      debugPrint('Parsing payment_method: ${json['payment_method']} (${json['payment_method'].runtimeType})');
      debugPrint('Parsing delivery_type: ${json['delivery_type']} (${json['delivery_type'].runtimeType})');
      debugPrint('Parsing scheduled_date: ${json['scheduled_date']} (${json['scheduled_date'].runtimeType})');
      debugPrint('Parsing created_at: ${json['created_at']} (${json['created_at'].runtimeType})');
      debugPrint('Parsing updated_at: ${json['updated_at']} (${json['updated_at'].runtimeType})');
      
    return OrderModel(
      id: _parseInt(json['id']),
      orderId: json['order_id'] != null ? _parseInt(json['order_id']) : null,
      vendorId: json['vendor_id'] != null ? _parseInt(json['vendor_id']) : null,
      userId: _parseInt(json['user_id']),
      addressId: _parseInt(json['address_id']),
      statusId: _parseInt(json['order_status_option_id'] ?? json['status_id'] ?? json['status']),
      status: _parseString(json['status_name'] ?? json['status'], 'Unknown'),
      totalAmount: _parseDouble(json['total_amount'] ?? json['total'] ?? json['payable_amount']),
      paymentStatus: json['payment_status'] != null ? json['payment_status'].toString() : null,
      paymentMethod: json['payment_method'] != null ? json['payment_method'].toString() : null,
      deliveryType: json['delivery_type'],
      scheduledDate: json['scheduled_date'],
      createdAt: json['created_at'] ?? json['created_date'],
      updatedAt: json['updated_at'],
      products: json['products'] != null
          ? (json['products'] as List)
              .map((product) => OrderProductModel.fromJson(product))
              .toList()
          : null,
      vendor: json['vendor'] != null
          ? OrderVendorModel.fromJson(json['vendor'])
          : null,
      address: json['address'] != null
          ? OrderAddressModel.fromJson(json['address'])
          : null,
      orderNumber: json['order_number'],
      vendors: json['vendors'] != null
          ? (json['vendors'] as List)
              .map((vendor) => OrderVendorDetailModel.fromJson(vendor))
              .toList()
          : null,
      // Additional fields
      subtotalAmount: _parseDouble(json['subtotal_amount'] ?? json['total_amount']),
      taxableAmount: _parseDouble(json['taxable_amount']),
      totalDeliveryFee: _parseDouble(json['total_delivery_fee']),
      totalServiceFee: _parseDouble(json['total_service_fee']),
      discountAmount: _parseDouble(json['discount_amount'] ?? json['total_discount']),
      tipAmount: _parseDouble(json['tip_amount']),
      loyaltyPointsUsed: _parseDouble(json['loyalty_points_used']),
      loyaltyPointsEarned: _parseDouble(json['loyalty_points_earned']),
      loyaltyAmountSaved: _parseDouble(json['loyalty_amount_saved']),
      luxuryOptionName: json['luxury_option_name'],
      commentForVendor: json['comment_for_vendor'],
      specificInstructions: json['specific_instructions'],
      tipOptions: json['tip'] != null && json['tip'] is List
          ? List<Map<String, dynamic>>.from(json['tip'])
          : null,
      type: json['type'] != null ? _parseInt(json['type']) : null,
      couponCode: json['coupon_code'],
      couponDiscount: _parseDouble(json['coupon_discount'] ?? json['discount_amount']),
      userName: json['user_name'],
      userImage: json['user_image'],
      // Additional fields for React Native parity
      scheduledDateTime: json['scheduled_date_time'],
      eta: json['eta'],
      orderStatus: json['order_status'] != null 
          ? OrderStatusModel.fromJson(json['order_status'])
          : null,
      editRequestId: json['edit_request_id'] != null ? _parseInt(json['edit_request_id']) : null,
      isEdited: _parseBool(json['is_edited']),
      cancelRequestBy: json['cancel_request_by'],
      cartId: json['cart_id'] != null ? _parseInt(json['cart_id']) : null,
      totalDiscount: _parseDouble(json['total_discount']),
      payableAmount: _parseDouble(json['payable_amount']),
      createdDate: json['created_date'],
      paymentOption: json['payment_option'] != null
          ? PaymentOptionModel.fromJson(json['payment_option'])
          : null,
    );
    } catch (e, stackTrace) {
      debugPrint('ERROR parsing OrderModel: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'vendor_id': vendorId,
      'user_id': userId,
      'address_id': addressId,
      'order_status_option_id': statusId,
      'status': status,
      'total_amount': totalAmount,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'delivery_type': deliveryType,
      'scheduled_date': scheduledDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'products': products?.map((product) => product.toJson()).toList(),
      'vendor': vendor?.toJson(),
      'address': address?.toJson(),
      'order_number': orderNumber,
      'vendors': vendors?.map((vendor) => vendor.toJson()).toList(),
      'subtotal_amount': subtotalAmount,
      'taxable_amount': taxableAmount,
      'total_delivery_fee': totalDeliveryFee,
      'total_service_fee': totalServiceFee,
      'discount_amount': discountAmount,
      'tip_amount': tipAmount,
      'loyalty_points_used': loyaltyPointsUsed,
      'loyalty_points_earned': loyaltyPointsEarned,
      'loyalty_amount_saved': loyaltyAmountSaved,
      'luxury_option_name': luxuryOptionName,
      'comment_for_vendor': commentForVendor,
      'specific_instructions': specificInstructions,
      'tip': tipOptions,
      'type': type,
      'coupon_code': couponCode,
      'user_name': userName,
      'user_image': userImage,
      'scheduled_date_time': scheduledDateTime,
      'eta': eta,
      'order_status': orderStatus?.toJson(),
      'edit_request_id': editRequestId,
      'is_edited': isEdited,
      'cancel_request_by': cancelRequestBy,
      'cart_id': cartId,
      'total_discount': totalDiscount,
      'payable_amount': payableAmount,
      'created_date': createdDate,
      'payment_option': paymentOption?.toJson(),
    };
  }

  bool get isDelivered => statusId == 6;
  bool get isCancelled => statusId == 3;
  
  // Order categorization for tabs
  bool get isPending => statusId == 1;  // Pending (awaiting confirmation)
  bool get isActive => statusId == 2 || statusId == 4 || statusId == 5;  // Confirmed, Preparing, Ready
  bool get isPast => statusId == 6 || statusId == 3;  // Delivered or Cancelled
  
  // Get the first vendor's tracking info (for convenience)
  OrderVendorDetailModel? get primaryVendor => vendors?.isNotEmpty == true ? vendors!.first : null;
  int? get currentDispatcherStatus => primaryVendor?.dispatcherStatusOptionId;
  String? get trackingUrl => primaryVendor?.dispatchTrakingUrl;
  bool get hasTrackingUrl => trackingUrl != null && trackingUrl!.isNotEmpty;
}

// Order Status Model
class OrderStatusModel {
  final OrderStatusOption? currentStatus;
  final OrderStatusOption? previousStatus;
  
  OrderStatusModel({
    this.currentStatus,
    this.previousStatus,
  });
  
  factory OrderStatusModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusModel(
      currentStatus: json['current_status'] != null
          ? OrderStatusOption.fromJson(json['current_status'])
          : null,
      previousStatus: json['previous_status'] != null
          ? OrderStatusOption.fromJson(json['previous_status'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'current_status': currentStatus?.toJson(),
    'previous_status': previousStatus?.toJson(),
  };
}

class OrderStatusOption {
  final int id;
  final String title;
  final String? color;
  
  OrderStatusOption({
    required this.id,
    required this.title,
    this.color,
  });
  
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
  
  factory OrderStatusOption.fromJson(Map<String, dynamic> json) {
    return OrderStatusOption(
      id: _parseInt(json['id']),
      title: json['title'] ?? '',
      color: json['color'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'color': color,
  };
}

class OrderProductModel {
  final int id;
  final int orderId;
  final int productId;
  final int vendorId;
  final int userId;
  final int quantity;
  final double price;
  final String? productName;
  final String? productImage;
  final String? createdAt;
  final String? updatedAt;
  final List<ProductAddonModel>? productAddons;

  OrderProductModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.vendorId,
    required this.userId,
    required this.quantity,
    required this.price,
    this.productName,
    this.productImage,
    this.createdAt,
    this.updatedAt,
    this.productAddons,
  });

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

  factory OrderProductModel.fromJson(Map<String, dynamic> json) {
    // Handle image - it might be a string URL or an object with image paths
    String? imageUrl;
    if (json['image'] is String) {
      imageUrl = json['image'];
    } else if (json['image'] is Map) {
      // Extract the image URL from the image object
      imageUrl = json['image']['original_image'] ?? 
                json['image']['image_path'] ?? 
                json['image']['proxy_url'];
    }
    // Also check product_image field
    if (imageUrl == null && json['product_image'] != null) {
      if (json['product_image'] is String) {
        imageUrl = json['product_image'];
      } else if (json['product_image'] is Map) {
        imageUrl = json['product_image']['original_image'] ?? 
                  json['product_image']['image_path'] ?? 
                  json['product_image']['proxy_url'];
      }
    }
    
    // Clean up proxy URLs with @webp suffix
    if (imageUrl != null) {
      if (imageUrl.contains('/ce/0/plain/')) {
        final urlMatch = RegExp(r'/ce/0/plain/(https?://[^@]+)').firstMatch(imageUrl);
        if (urlMatch != null && urlMatch.group(1) != null) {
          imageUrl = urlMatch.group(1);
        }
      } else if (imageUrl.contains('@webp')) {
        imageUrl = imageUrl.split('@webp').first;
      }
    }
    
    return OrderProductModel(
      id: _parseInt(json['id']),
      orderId: _parseInt(json['order_id']),
      productId: _parseInt(json['product_id']),
      vendorId: _parseInt(json['vendor_id']),
      userId: _parseInt(json['user_id']),
      quantity: _parseInt(json['quantity']),
      price: _parseDouble(json['price']),
      productName: json['product_name'] ?? json['name'],
      productImage: imageUrl,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      productAddons: json['product_addons'] != null
          ? (json['product_addons'] as List)
              .map((addon) => ProductAddonModel.fromJson(addon))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'vendor_id': vendorId,
      'user_id': userId,
      'quantity': quantity,
      'price': price,
      'product_name': productName,
      'product_image': productImage,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'product_addons': productAddons?.map((addon) => addon.toJson()).toList(),
    };
  }
}

class OrderVendorModel {
  final int id;
  final String name;
  final String? logo;
  final String? address;
  final String? phone;
  final String? latitude;
  final String? longitude;

  OrderVendorModel({
    required this.id,
    required this.name,
    this.logo,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
  });

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

  factory OrderVendorModel.fromJson(Map<String, dynamic> json) {
    // Handle logo - it might be a string URL or an object with image paths
    String? logoUrl;
    if (json['logo'] is String) {
      logoUrl = json['logo'];
    } else if (json['logo'] is Map) {
      // Extract the image URL from the logo object
      logoUrl = json['logo']['image_s3_url'] ?? 
                json['logo']['original_image'] ?? 
                json['logo']['image_path'];
    }
    
    return OrderVendorModel(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      logo: logoUrl,
      address: json['address'],
      phone: json['phone'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class OrderAddressModel {
  final int id;
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
  final String? houseNumber;
  final String? pincode;

  OrderAddressModel({
    required this.id,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.houseNumber,
    this.pincode,
  });

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

  factory OrderAddressModel.fromJson(Map<String, dynamic> json) {
    return OrderAddressModel(
      id: _parseInt(json['id']),
      address: json['address'] ?? '',
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      houseNumber: json['house_number'],
      pincode: json['pincode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'house_number': houseNumber,
      'pincode': pincode,
    };
  }
}

class OrderVendorDetailModel {
  final int id;
  final int vendorId;
  final String? vendorName;
  final String? logo;
  final String? dispatchTrakingUrl;
  final int? dispatcherStatusOptionId;
  final List<DispatcherStatusModel>? vendorDispatcherStatus;
  final int vendorDispatcherStatusCount;
  final List<String>? dispatcherStatusIcons;
  final OrderStatusDetailModel? orderStatus;
  final List<OrderProductModel>? products;
  final List<OrderStatusHistoryModel>? allStatus;
  final int? driverId;
  final OrderVendorModel? vendor;
  final Map<String, dynamic>? agentLocation;
  final List<Map<String, dynamic>>? tasks;
  final String? eta;
  final double? discountAmount;
  final double? deliveryFee;
  final double? payableAmount;

  OrderVendorDetailModel({
    required this.id,
    required this.vendorId,
    this.vendorName,
    this.logo,
    this.dispatchTrakingUrl,
    this.dispatcherStatusOptionId,
    this.vendorDispatcherStatus,
    this.vendorDispatcherStatusCount = 6,
    this.dispatcherStatusIcons,
    this.orderStatus,
    this.products,
    this.allStatus,
    this.driverId,
    this.vendor,
    this.agentLocation,
    this.tasks,
    this.eta,
    this.discountAmount,
    this.deliveryFee,
    this.payableAmount,
  });

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

  factory OrderVendorDetailModel.fromJson(Map<String, dynamic> json) {
    debugPrint('=== Parsing OrderVendorDetailModel ===');
    debugPrint('JSON keys: ${json.keys.toList()}');
    
    try {
      debugPrint('Parsing vendor id: ${json['id']} (${json['id'].runtimeType})');
      debugPrint('Parsing vendor_id: ${json['vendor_id']} (${json['vendor_id'].runtimeType})');
      debugPrint('Parsing vendor_dispatcher_status_count: ${json['vendor_dispatcher_status_count']} (${json['vendor_dispatcher_status_count'].runtimeType})');
      
    // Handle logo - it might be a string URL or an object with image paths
    String? logoUrl;
    if (json['logo'] is String) {
      logoUrl = json['logo'];
    } else if (json['logo'] is Map) {
      logoUrl = json['logo']['image_s3_url'] ?? 
                json['logo']['original_image'] ?? 
                json['logo']['image_path'];
    }
    
    return OrderVendorDetailModel(
      id: _parseInt(json['id']),
      vendorId: _parseInt(json['vendor_id']),
      vendorName: json['vendor_name'] ?? json['name'],
      logo: logoUrl,
      dispatchTrakingUrl: json['dispatch_traking_url'],
      dispatcherStatusOptionId: json['dispatcher_status_option_id'] != null 
          ? _parseInt(json['dispatcher_status_option_id']) 
          : null,
      vendorDispatcherStatus: json['vendor_dispatcher_status'] != null
          ? (json['vendor_dispatcher_status'] as List)
              .map((status) => DispatcherStatusModel.fromJson(status))
              .toList()
          : null,
      vendorDispatcherStatusCount: json['vendor_dispatcher_status_count'] != null 
          ? _parseInt(json['vendor_dispatcher_status_count']) 
          : 6,
      dispatcherStatusIcons: json['dispatcher_status_icons'] != null
          ? (json['dispatcher_status_icons'] as List).map((e) => e.toString()).toList()
          : null,
      orderStatus: json['order_status'] != null
          ? OrderStatusDetailModel.fromJson(json['order_status'])
          : null,
      products: json['products'] != null
          ? (json['products'] as List)
              .map((product) => OrderProductModel.fromJson(product))
              .toList()
          : null,
      allStatus: json['all_status'] != null
          ? (json['all_status'] as List)
              .map((status) => OrderStatusHistoryModel.fromJson(status))
              .toList()
          : null,
      driverId: json['driver_id'] != null ? _parseInt(json['driver_id']) : null,
      vendor: json['vendor'] != null
          ? OrderVendorModel.fromJson(json['vendor'])
          : null,
      agentLocation: json['agent_location'] != null 
          ? Map<String, dynamic>.from(json['agent_location']) 
          : null,
      tasks: json['tasks'] != null 
          ? (json['tasks'] as List).map((e) => Map<String, dynamic>.from(e)).toList()
          : null,
      eta: json['eta'],
      discountAmount: _parseDouble(json['discount_amount']),
      deliveryFee: _parseDouble(json['delivery_fee']),
      payableAmount: _parseDouble(json['payable_amount']),
    );
    } catch (e, stackTrace) {
      debugPrint('ERROR parsing OrderVendorDetailModel: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'logo': logo,
      'dispatch_traking_url': dispatchTrakingUrl,
      'dispatcher_status_option_id': dispatcherStatusOptionId,
      'vendor_dispatcher_status': vendorDispatcherStatus?.map((s) => s.toJson()).toList(),
      'vendor_dispatcher_status_count': vendorDispatcherStatusCount,
      'dispatcher_status_icons': dispatcherStatusIcons,
      'order_status': orderStatus?.toJson(),
      'products': products?.map((p) => p.toJson()).toList(),
      'all_status': allStatus?.map((s) => s.toJson()).toList(),
      'driver_id': driverId,
      'vendor': vendor?.toJson(),
      'agent_location': agentLocation,
      'tasks': tasks,
      'eta': eta,
      'discount_amount': discountAmount,
      'delivery_fee': deliveryFee,
      'payable_amount': payableAmount,
    };
  }
}

class DispatcherStatusModel {
  final int dispatcherStatusOptionId;
  final String type;
  final StatusDataModel? statusData;

  DispatcherStatusModel({
    required this.dispatcherStatusOptionId,
    required this.type,
    this.statusData,
  });

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

  factory DispatcherStatusModel.fromJson(Map<String, dynamic> json) {
    return DispatcherStatusModel(
      dispatcherStatusOptionId: _parseInt(json['dispatcher_status_option_id']),
      type: json['type'] != null ? json['type'].toString() : '1',
      statusData: json['status_data'] != null
          ? StatusDataModel.fromJson(json['status_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dispatcher_status_option_id': dispatcherStatusOptionId,
      'type': type,
      'status_data': statusData?.toJson(),
    };
  }
}

class StatusDataModel {
  final String? icon;
  final String? driverStatus;

  StatusDataModel({
    this.icon,
    this.driverStatus,
  });

  factory StatusDataModel.fromJson(Map<String, dynamic> json) {
    return StatusDataModel(
      icon: json['icon'],
      driverStatus: json['driver_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'driver_status': driverStatus,
    };
  }
}

class OrderStatusDetailModel {
  final OrderStatusCurrentModel? currentStatus;

  OrderStatusDetailModel({
    this.currentStatus,
  });

  factory OrderStatusDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusDetailModel(
      currentStatus: json['current_status'] != null
          ? OrderStatusCurrentModel.fromJson(json['current_status'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_status': currentStatus?.toJson(),
    };
  }
}

class OrderStatusCurrentModel {
  final int id;
  final String title;

  OrderStatusCurrentModel({
    required this.id,
    required this.title,
  });

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

  factory OrderStatusCurrentModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusCurrentModel(
      id: _parseInt(json['id']),
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}

class OrderStatusHistoryModel {
  final int id;
  final int orderId;
  final int orderVendorId;
  final int orderStatusOptionId;
  final String? createdAt;
  final String? updatedAt;
  final int? vendorId;
  final OrderStatusModel? status;

  OrderStatusHistoryModel({
    required this.id,
    required this.orderId,
    required this.orderVendorId,
    required this.orderStatusOptionId,
    this.createdAt,
    this.updatedAt,
    this.vendorId,
    this.status,
  });

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

  factory OrderStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryModel(
      id: _parseInt(json['id']),
      orderId: _parseInt(json['order_id']),
      orderVendorId: _parseInt(json['order_vendor_id']),
      orderStatusOptionId: _parseInt(json['order_status_option_id']),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      vendorId: json['vendor_id'] != null ? _parseInt(json['vendor_id']) : null,
      status: json['status'] != null
          ? OrderStatusModel.fromJson(json['status'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'order_vendor_id': orderVendorId,
      'order_status_option_id': orderStatusOptionId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'vendor_id': vendorId,
      'status': status?.toJson(),
    };
  }
}

// Payment Option Model
class PaymentOptionModel {
  final int id;
  final String title;
  final String? titleLng;
  
  PaymentOptionModel({
    required this.id,
    required this.title,
    this.titleLng,
  });
  
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
  
  factory PaymentOptionModel.fromJson(Map<String, dynamic> json) {
    return PaymentOptionModel(
      id: _parseInt(json['id']),
      title: json['title'] ?? '',
      titleLng: json['title_lng'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'title_lng': titleLng,
  };
}

// Product Addon Model
class ProductAddonModel {
  final int id;
  final String addonTitle;
  final String optionTitle;
  final double price;
  
  ProductAddonModel({
    required this.id,
    required this.addonTitle,
    required this.optionTitle,
    required this.price,
  });
  
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
  
  factory ProductAddonModel.fromJson(Map<String, dynamic> json) {
    return ProductAddonModel(
      id: _parseInt(json['id']),
      addonTitle: json['addon_title'] ?? '',
      optionTitle: json['option_title'] ?? '',
      price: _parseDouble(json['price']),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'addon_title': addonTitle,
    'option_title': optionTitle,
    'price': price,
  };
}

