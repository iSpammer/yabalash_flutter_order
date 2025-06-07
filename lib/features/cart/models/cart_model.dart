import '../../restaurants/models/product_model.dart';

class TimeSlot {
  final String name;
  final String value;

  TimeSlot({
    required this.name,
    required this.value,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }
}

class CartModel {
  final int? id;
  final List<CartVendorItem> products;
  final double? grossPayableAmount;
  final double? netPayableAmount;
  final double? totalPayableAmount;
  final double? totalDiscount;
  final double? totalDeliveryFee;
  final double? totalTax;
  final double? walletAmountUsed;
  final double? loyaltyAmountUsed;
  final double? totalSubscriptionDiscount;
  final bool? deliverStatus;
  final String? address;
  final String? scheduledDateTime;
  final String? scheduleType;
  final List<TipOption>? tipOptions;
  final VendorDetails? vendorDetails;
  final double? minimumOrderAmount;
  final String? minimumOrderAmountText;
  final List<TimeSlot>? slots;
  final List<TimeSlot>? dropoffSlots;
  final int? itemCount;
  final int? currencyId;
  final String? uniqueIdentifier;
  final int? userId;
  final int? createdBy;
  final String? status;
  final String? isGift;
  final String? createdAt;
  final String? updatedAt;
  final String? specificInstructions;
  final String? commentForPickupDriver;
  final String? commentForDropoffDriver;
  final String? commentForVendor;
  final String? schedulePickup;
  final String? scheduleDropoff;
  final String? scheduledSlot;
  final String? shippingDeliveryType;
  final int? addressId;
  final String? dropoffScheduledSlot;
  final String? totalOtherTaxes;
  final int? orderId;
  final int? giftCardId;
  final String? payableAmount;
  final String? userGiftCode;
  final String? vendorBiddingDiscount;
  final int? closedStoreOrderScheduled;
  final int? categoryKycCount;
  final int? withoutCategoryKyc;
  final String? categoryIds;
  final double? otherTaxes;
  final List<Map<String, dynamic>>? specificTaxes;
  final String? totalServiceFee;
  final String? totalContainerCharges;
  final String? totalMarkupCharges;
  final List<Map<String, dynamic>>? taxDetails;
  final String? totalTaxableAmount;
  final double? totalFixedFeeAmount;
  final double? totalAddonPrice;

  CartModel({
    this.id,
    required this.products,
    this.grossPayableAmount,
    this.netPayableAmount,
    this.totalPayableAmount,
    this.totalDiscount,
    this.totalDeliveryFee,
    this.totalTax,
    this.walletAmountUsed,
    this.loyaltyAmountUsed,
    this.totalSubscriptionDiscount,
    this.deliverStatus,
    this.address,
    this.scheduledDateTime,
    this.scheduleType,
    this.tipOptions,
    this.vendorDetails,
    this.minimumOrderAmount,
    this.minimumOrderAmountText,
    this.slots,
    this.dropoffSlots,
    this.itemCount,
    this.currencyId,
    this.uniqueIdentifier,
    this.userId,
    this.createdBy,
    this.status,
    this.isGift,
    this.createdAt,
    this.updatedAt,
    this.specificInstructions,
    this.commentForPickupDriver,
    this.commentForDropoffDriver,
    this.commentForVendor,
    this.schedulePickup,
    this.scheduleDropoff,
    this.scheduledSlot,
    this.shippingDeliveryType,
    this.addressId,
    this.dropoffScheduledSlot,
    this.totalOtherTaxes,
    this.orderId,
    this.giftCardId,
    this.payableAmount,
    this.userGiftCode,
    this.vendorBiddingDiscount,
    this.closedStoreOrderScheduled,
    this.categoryKycCount,
    this.withoutCategoryKyc,
    this.categoryIds,
    this.otherTaxes,
    this.specificTaxes,
    this.totalServiceFee,
    this.totalContainerCharges,
    this.totalMarkupCharges,
    this.taxDetails,
    this.totalTaxableAmount,
    this.totalFixedFeeAmount,
    this.totalAddonPrice,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'],
      products: (json['products'] as List?)
              ?.map((e) => CartVendorItem.fromJson(e))
              .toList() ??
          [],
      grossPayableAmount: _parseDouble(json['gross_paybale_amount']),
      netPayableAmount: _parseDouble(json['net_paybale_amount']),
      totalPayableAmount: _parseDouble(json['total_payable_amount']),
      totalDiscount: _parseDouble(json['total_discount_amount']),
      totalDeliveryFee: _parseDouble(json['total_delivery_fee']),
      totalTax: _parseDouble(json['total_tax']),
      walletAmountUsed: _parseDouble(json['wallet_amount_used']),
      loyaltyAmountUsed: _parseDouble(json['loyalty_amount_used']),
      totalSubscriptionDiscount:
          _parseDouble(json['total_subscription_discount']),
      deliverStatus: json['deliver_status'] == true || json['deliver_status'] == 1,
      address: json['address'],
      scheduledDateTime: json['scheduled_date_time'],
      scheduleType: json['schedule_type'],
      tipOptions: (json['tip'] as List?)
          ?.map((e) => TipOption.fromJson(e))
          .toList(),
      vendorDetails: json['vendor_details'] != null && json['vendor_details'] is Map<String, dynamic>
          ? VendorDetails.fromJson(json['vendor_details'])
          : null,
      minimumOrderAmount: _parseDouble(json['minimum_order_amount']),
      minimumOrderAmountText: json['minimum_order_amount_text'],
      slots: (json['slots'] as List?)
          ?.map((e) => TimeSlot.fromJson(e))
          .toList(),
      dropoffSlots: (json['dropoff_slots'] as List?)
          ?.map((e) => TimeSlot.fromJson(e))
          .toList(),
      itemCount: json['item_count'],
      currencyId: json['currency_id'],
      uniqueIdentifier: json['unique_identifier'],
      userId: json['user_id'],
      createdBy: json['created_by'],
      status: json['status']?.toString(),
      isGift: json['is_gift']?.toString(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      specificInstructions: json['specific_instructions'],
      commentForPickupDriver: json['comment_for_pickup_driver'],
      commentForDropoffDriver: json['comment_for_dropoff_driver'],
      commentForVendor: json['comment_for_vendor'],
      schedulePickup: json['schedule_pickup'],
      scheduleDropoff: json['schedule_dropoff'],
      scheduledSlot: json['scheduled_slot'],
      shippingDeliveryType: json['shipping_delivery_type'],
      addressId: json['address_id'],
      dropoffScheduledSlot: json['dropoff_scheduled_slot'],
      totalOtherTaxes: json['total_other_taxes']?.toString(),
      orderId: json['order_id'],
      giftCardId: json['gift_card_id'],
      payableAmount: json['payable_amount']?.toString(),
      userGiftCode: json['user_gift_code'],
      vendorBiddingDiscount: json['vendor_bidding_discount']?.toString(),
      closedStoreOrderScheduled: json['closed_store_order_scheduled'],
      categoryKycCount: json['category_kyc_count'],
      withoutCategoryKyc: json['without_category_kyc'],
      categoryIds: json['category_ids'],
      otherTaxes: _parseDouble(json['other_taxes']),
      specificTaxes: (json['specific_taxes'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
      totalServiceFee: json['total_service_fee']?.toString(),
      totalContainerCharges: json['total_container_charges']?.toString(),
      totalMarkupCharges: json['total_markup_charges']?.toString(),
      taxDetails: (json['tax_details'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
      totalTaxableAmount: json['total_taxable_amount']?.toString(),
      totalFixedFeeAmount: _parseDouble(json['total_fixed_fee_amount']),
      totalAddonPrice: _parseDouble(json['total_addon_price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products': products.map((e) => e.toJson()).toList(),
      'gross_paybale_amount': grossPayableAmount,
      'net_paybale_amount': netPayableAmount,
      'total_payable_amount': totalPayableAmount,
      'total_discount_amount': totalDiscount,
      'total_delivery_fee': totalDeliveryFee,
      'total_tax': totalTax,
      'wallet_amount_used': walletAmountUsed,
      'loyalty_amount_used': loyaltyAmountUsed,
      'total_subscription_discount': totalSubscriptionDiscount,
      'deliver_status': deliverStatus,
      'address': address,
      'scheduled_date_time': scheduledDateTime,
      'schedule_type': scheduleType,
      'tip': tipOptions?.map((e) => e.toJson()).toList(),
      'vendor_details': vendorDetails?.toJson(),
      'minimum_order_amount': minimumOrderAmount,
      'minimum_order_amount_text': minimumOrderAmountText,
      'slots': slots?.map((e) => e.toJson()).toList(),
      'dropoff_slots': dropoffSlots?.map((e) => e.toJson()).toList(),
      'item_count': itemCount,
      'currency_id': currencyId,
      'unique_identifier': uniqueIdentifier,
      'user_id': userId,
      'created_by': createdBy,
      'status': status,
      'is_gift': isGift,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'specific_instructions': specificInstructions,
      'comment_for_pickup_driver': commentForPickupDriver,
      'comment_for_dropoff_driver': commentForDropoffDriver,
      'comment_for_vendor': commentForVendor,
      'schedule_pickup': schedulePickup,
      'schedule_dropoff': scheduleDropoff,
      'scheduled_slot': scheduledSlot,
      'shipping_delivery_type': shippingDeliveryType,
      'address_id': addressId,
      'dropoff_scheduled_slot': dropoffScheduledSlot,
      'total_other_taxes': totalOtherTaxes,
      'order_id': orderId,
      'gift_card_id': giftCardId,
      'payable_amount': payableAmount,
      'user_gift_code': userGiftCode,
      'vendor_bidding_discount': vendorBiddingDiscount,
      'closed_store_order_scheduled': closedStoreOrderScheduled,
      'category_kyc_count': categoryKycCount,
      'without_category_kyc': withoutCategoryKyc,
      'category_ids': categoryIds,
      'other_taxes': otherTaxes,
      'specific_taxes': specificTaxes,
      'total_service_fee': totalServiceFee,
      'total_container_charges': totalContainerCharges,
      'total_markup_charges': totalMarkupCharges,
      'tax_details': taxDetails,
      'total_taxable_amount': totalTaxableAmount,
      'total_fixed_fee_amount': totalFixedFeeAmount,
      'total_addon_price': totalAddonPrice,
    };
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
}

class CartVendorItem {
  final int? vendorId;
  final VendorInfo? vendor;
  final List<CartProductItem> vendorProducts;
  final bool? isDeliverable;
  final double? deliverCharge;
  final double? discountAmount;
  final double? payableAmount;
  final CouponData? couponData;
  final int? vendorDineinTableId;
  final int? dispatchAgentId;
  final bool? isCartChecked;
  final String? scheduledDateTime;
  final String? slotsDate;
  final List<TimeSlot>? slots;
  final int? slotsCnt;
  final String? delaySlot;
  final List<String>? deliveryTypes;
  final String? selTypes;
  final double? proSum;
  final double? addonSum;
  final bool? promoFreeDelivery;
  final bool? couponApplyOnVendor;
  final bool? isCouponApplied;
  final double? serviceFeePercentageAmount;
  final double? vendorGrossTotal;
  final double? discountPercent;
  final double? taxableAmount;
  final bool? isPromoCodeAvailable;
  final Map<String, dynamic>? coupon;

  CartVendorItem({
    this.vendorId,
    this.vendor,
    required this.vendorProducts,
    this.isDeliverable,
    this.deliverCharge,
    this.discountAmount,
    this.payableAmount,
    this.couponData,
    this.vendorDineinTableId,
    this.dispatchAgentId,
    this.isCartChecked,
    this.scheduledDateTime,
    this.slotsDate,
    this.slots,
    this.slotsCnt,
    this.delaySlot,
    this.deliveryTypes,
    this.selTypes,
    this.proSum,
    this.addonSum,
    this.promoFreeDelivery,
    this.couponApplyOnVendor,
    this.isCouponApplied,
    this.serviceFeePercentageAmount,
    this.vendorGrossTotal,
    this.discountPercent,
    this.taxableAmount,
    this.isPromoCodeAvailable,
    this.coupon,
  });

  factory CartVendorItem.fromJson(Map<String, dynamic> json) {
    return CartVendorItem(
      vendorId: json['vendor_id'],
      vendor: json['vendor'] != null ? VendorInfo.fromJson(json['vendor']) : null,
      vendorProducts: (json['vendor_products'] as List?)
              ?.map((e) => CartProductItem.fromJson(e))
              .toList() ??
          [],
      isDeliverable: json['isDeliverable'] == true || json['isDeliverable'] == 1,
      deliverCharge: CartModel._parseDouble(json['deliver_charge']),
      discountAmount: CartModel._parseDouble(json['discount_amount']),
      payableAmount: CartModel._parseDouble(json['payable_amount']),
      couponData: json['couponData'] != null
          ? CouponData.fromJson(json['couponData'])
          : null,
      vendorDineinTableId: json['vendor_dinein_table_id'],
      dispatchAgentId: json['dispatch_agent_id'],
      isCartChecked: json['is_cart_checked'] == true || json['is_cart_checked'] == 1,
      scheduledDateTime: json['scheduled_date_time'],
      slotsDate: json['slotsdate'],
      slots: (json['slots'] as List?)
          ?.map((e) => TimeSlot.fromJson(e))
          .toList(),
      slotsCnt: json['slotsCnt'],
      delaySlot: json['delaySlot'],
      deliveryTypes: (json['delivery_types'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      selTypes: json['sel_types'],
      proSum: CartModel._parseDouble(json['proSum']),
      addonSum: CartModel._parseDouble(json['addonSum']),
      promoFreeDelivery: json['promo_free_delivery'] == true || json['promo_free_delivery'] == 1,
      couponApplyOnVendor: json['coupon_apply_on_vendor'] == true || json['coupon_apply_on_vendor'] == 1,
      isCouponApplied: json['is_coupon_applied'] == true || json['is_coupon_applied'] == 1,
      serviceFeePercentageAmount: CartModel._parseDouble(json['service_fee_percentage_amount']),
      vendorGrossTotal: CartModel._parseDouble(json['vendor_gross_total']),
      discountPercent: CartModel._parseDouble(json['discount_percent']),
      taxableAmount: CartModel._parseDouble(json['taxable_amount']),
      isPromoCodeAvailable: json['is_promo_code_available'] == true || json['is_promo_code_available'] == 1,
      coupon: json['coupon'] != null ? Map<String, dynamic>.from(json['coupon']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_id': vendorId,
      'vendor': vendor?.toJson(),
      'vendor_products': vendorProducts.map((e) => e.toJson()).toList(),
      'isDeliverable': isDeliverable,
      'deliver_charge': deliverCharge,
      'discount_amount': discountAmount,
      'payable_amount': payableAmount,
      'couponData': couponData?.toJson(),
      'vendor_dinein_table_id': vendorDineinTableId,
      'dispatch_agent_id': dispatchAgentId,
      'is_cart_checked': isCartChecked,
      'scheduled_date_time': scheduledDateTime,
      'slotsdate': slotsDate,
      'slots': slots?.map((e) => e.toJson()).toList(),
      'slotsCnt': slotsCnt,
      'delaySlot': delaySlot,
      'delivery_types': deliveryTypes,
      'sel_types': selTypes,
      'proSum': proSum,
      'addonSum': addonSum,
      'promo_free_delivery': promoFreeDelivery,
      'coupon_apply_on_vendor': couponApplyOnVendor,
      'is_coupon_applied': isCouponApplied,
      'service_fee_percentage_amount': serviceFeePercentageAmount,
      'vendor_gross_total': vendorGrossTotal,
      'discount_percent': discountPercent,
      'taxable_amount': taxableAmount,
      'is_promo_code_available': isPromoCodeAvailable,
      'coupon': coupon,
    };
  }
}

class CartProductItem {
  final int? id;
  final int? cartId;
  final int? quantity;
  final ProductModel? product;
  final CartItemVariant? variants;
  final List<VariantOption>? variantOptions;
  final List<ProductAddon>? productAddons;
  final CartImage? cartImg;

  CartProductItem({
    this.id,
    this.cartId,
    this.quantity,
    this.product,
    this.variants,
    this.variantOptions,
    this.productAddons,
    this.cartImg,
  });

  factory CartProductItem.fromJson(Map<String, dynamic> json) {
    return CartProductItem(
      id: json['id'],
      cartId: json['cart_id'],
      quantity: json['quantity'],
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'])
          : null,
      variants: json['variants'] != null
          ? CartItemVariant.fromJson(json['variants'])
          : null,
      variantOptions: (json['variant_options'] as List?)
          ?.map((e) => VariantOption.fromJson(e))
          .toList(),
      productAddons: (json['product_addons'] as List?)
          ?.map((e) => ProductAddon.fromJson(e))
          .toList(),
      cartImg: json['cartImg'] != null && json['cartImg'] is Map
          ? CartImage.fromJson(json['cartImg'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart_id': cartId,
      'quantity': quantity,
      'product': product?.toJson(),
      'variants': variants?.toJson(),
      'variant_options': variantOptions?.map((e) => e.toJson()).toList(),
      'product_addons': productAddons?.map((e) => e.toJson()).toList(),
      'cartImg': cartImg?.toJson(),
    };
  }
}

class CartItemVariant {
  final int? id;
  final double? price;
  final double? quantityPrice;
  final String? title;

  CartItemVariant({
    this.id,
    this.price,
    this.quantityPrice,
    this.title,
  });

  factory CartItemVariant.fromJson(Map<String, dynamic> json) {
    return CartItemVariant(
      id: json['id'],
      price: CartModel._parseDouble(json['price']),
      quantityPrice: CartModel._parseDouble(json['quantity_price']),
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'quantity_price': quantityPrice,
      'title': title,
    };
  }
}

class VariantOption {
  final int? id;
  final String? title;
  final String? option;

  VariantOption({
    this.id,
    this.title,
    this.option,
  });

  factory VariantOption.fromJson(Map<String, dynamic> json) {
    return VariantOption(
      id: json['id'],
      title: json['title'],
      option: json['option'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'option': option,
    };
  }
}

class ProductAddon {
  final int? id;
  final String? addonTitle;
  final String? optionTitle;
  final double? price;
  final int? multiplier;

  ProductAddon({
    this.id,
    this.addonTitle,
    this.optionTitle,
    this.price,
    this.multiplier,
  });

  factory ProductAddon.fromJson(Map<String, dynamic> json) {
    return ProductAddon(
      id: json['id'],
      addonTitle: json['addon_title'],
      optionTitle: json['option_title'],
      price: CartModel._parseDouble(json['price']),
      multiplier: json['multiplier'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'addon_title': addonTitle,
      'option_title': optionTitle,
      'price': price,
      'multiplier': multiplier,
    };
  }
}

class CartImage {
  final int? id;
  final int? mediaType;
  final String? imagePath;
  final String? proxyUrl;
  final String? originalImage;
  final String? imageFit;

  CartImage({
    this.id,
    this.mediaType,
    this.imagePath,
    this.proxyUrl,
    this.originalImage,
    this.imageFit,
  });

  factory CartImage.fromJson(Map<String, dynamic> json) {
    // Handle both direct fields and nested path object
    Map<String, dynamic>? pathData = json['path'] is Map ? json['path'] : null;
    
    return CartImage(
      id: json['id'],
      mediaType: json['media_type'],
      imagePath: json['image_path'] ?? pathData?['image_path'],
      proxyUrl: json['proxy_url'] ?? pathData?['proxy_url'],
      originalImage: json['original_image'] ?? pathData?['original_image'],
      imageFit: json['image_fit'] ?? pathData?['image_fit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'media_type': mediaType,
      'image_path': imagePath,
      'proxy_url': proxyUrl,
      'original_image': originalImage,
      'image_fit': imageFit,
    };
  }
  
  String? get fullImageUrl {
    // Try to get the original image first
    if (originalImage != null && originalImage!.isNotEmpty) {
      return originalImage;
    }
    
    // If we have proxy URL and image path, combine them
    if (proxyUrl != null && imagePath != null) {
      String proxy = proxyUrl!;
      String path = imagePath!;
      
      // Remove trailing slash from proxy_url and leading slash from image_path to avoid double slashes
      if (proxy.endsWith('/')) {
        proxy = proxy.substring(0, proxy.length - 1);
      }
      if (path.startsWith('/')) {
        path = path.substring(1);
      }
      
      return '$proxy/$path';
    }
    
    // Return any available URL
    return imagePath ?? proxyUrl;
  }
}

class TipOption {
  final double value;
  final String label;

  TipOption({
    required this.value,
    required this.label,
  });

  factory TipOption.fromJson(Map<String, dynamic> json) {
    return TipOption(
      value: CartModel._parseDouble(json['value']) ?? 0.0,
      label: json['label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }
}

class VendorInfo {
  final int? id;
  final String? name;
  final String? desc;
  final String? logo;
  final String? banner;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? phone;
  final String? phoneNo;
  final String? email;
  final int? status;
  final int? cityId;
  final int? countryId;
  final int? preparationTime;
  final int? orderPreTime;
  final String? autoRejectTime;
  final double? orderMinAmount;
  final double? deliveryCharge;
  final double? minimumOrderAmount;
  final double? rating;
  final int? totalReviews;
  final bool? isOpen;
  final bool? isFeatured;
  final bool? isDeliveryAvailable;
  final bool? isPickupAvailable;
  final String? openingTime;
  final String? closingTime;
  final String? createdAt;
  final String? updatedAt;
  final int? showSlot;
  final int? dineIn;
  final int? delivery;
  final int? takeaway;
  final double? serviceFeePercent;
  final String? orderAmountForDeliveryFee;
  final double? deliveryFeeMinimum;
  final double? deliveryFeeMaximum;
  final int? closedStoreOrderScheduled;
  final String? slug;
  final String? city;
  final String? state;
  final String? country;
  final String? countryCode;
  final int? isVendorClosed;
  final int? isWishlist;

  VendorInfo({
    this.id,
    this.name,
    this.desc,
    this.logo,
    this.banner,
    this.latitude,
    this.longitude,
    this.address,
    this.phone,
    this.phoneNo,
    this.email,
    this.status,
    this.cityId,
    this.countryId,
    this.preparationTime,
    this.orderPreTime,
    this.autoRejectTime,
    this.orderMinAmount,
    this.deliveryCharge,
    this.minimumOrderAmount,
    this.rating,
    this.totalReviews,
    this.isOpen,
    this.isFeatured,
    this.isDeliveryAvailable,
    this.isPickupAvailable,
    this.openingTime,
    this.closingTime,
    this.createdAt,
    this.updatedAt,
    this.showSlot,
    this.dineIn,
    this.delivery,
    this.takeaway,
    this.serviceFeePercent,
    this.orderAmountForDeliveryFee,
    this.deliveryFeeMinimum,
    this.deliveryFeeMaximum,
    this.closedStoreOrderScheduled,
    this.slug,
    this.city,
    this.state,
    this.country,
    this.countryCode,
    this.isVendorClosed,
    this.isWishlist,
  });

  factory VendorInfo.fromJson(Map<String, dynamic> json) {
    return VendorInfo(
      id: json['id'],
      name: json['name'],
      desc: json['desc'],
      // Extract logo URL from nested object structure
      logo: _extractImageUrl(json['logo']),
      // Extract banner URL from nested object structure
      banner: _extractImageUrl(json['banner']),
      latitude: CartModel._parseDouble(json['latitude']),
      longitude: CartModel._parseDouble(json['longitude']),
      address: json['address'],
      phone: json['phone'],
      phoneNo: json['phone_no'],
      email: json['email'],
      status: json['status'],
      cityId: json['city_id'],
      countryId: json['country_id'],
      preparationTime: json['preparation_time'],
      orderPreTime: json['order_pre_time'],
      autoRejectTime: json['auto_reject_time'],
      orderMinAmount: CartModel._parseDouble(json['order_min_amount']),
      deliveryCharge: CartModel._parseDouble(json['delivery_charge']),
      minimumOrderAmount: CartModel._parseDouble(json['minimum_order_amount']),
      rating: CartModel._parseDouble(json['rating']),
      totalReviews: json['total_reviews'],
      isOpen: json['is_open'] == true || json['is_open'] == 1,
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      isDeliveryAvailable: json['is_delivery_available'] == true || json['is_delivery_available'] == 1,
      isPickupAvailable: json['is_pickup_available'] == true || json['is_pickup_available'] == 1,
      openingTime: json['opening_time'],
      closingTime: json['closing_time'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      showSlot: json['show_slot'],
      dineIn: json['dine_in'],
      delivery: json['delivery'],
      takeaway: json['takeaway'],
      serviceFeePercent: CartModel._parseDouble(json['service_fee_percent']),
      orderAmountForDeliveryFee: json['order_amount_for_delivery_fee'],
      deliveryFeeMinimum: CartModel._parseDouble(json['delivery_fee_minimum']),
      deliveryFeeMaximum: CartModel._parseDouble(json['delivery_fee_maximum']),
      closedStoreOrderScheduled: json['closed_store_order_scheduled'],
      slug: json['slug'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      countryCode: json['country_code'],
      isVendorClosed: json['is_vendor_closed'],
      isWishlist: json['is_wishlist'],
    );
  }

  static String? _extractImageUrl(dynamic imageData) {
    if (imageData == null) return null;
    
    // If it's already a string, return it
    if (imageData is String) return imageData;
    
    // If it's a map, try to extract the URL
    if (imageData is Map<String, dynamic>) {
      // The API returns image data with this structure:
      // "logo": {
      //   "proxy_url": "https://images.yabalash.com/insecure/fill/",
      //   "image_path": "/ce/0/plain/https://yabalash-assets.s3.me-central-1.amazonaws.com/vendor/...",
      //   "image_fit": "https://images.yabalash.com/insecure/fit/",
      //   "image_s3_url": "https://yabalash-assets.s3.me-central-1.amazonaws.com/vendor/..."
      // }
      
      // Try to get the S3 URL first as it's the direct image URL
      if (imageData['image_s3_url'] != null) {
        return imageData['image_s3_url'];
      }
      
      // If no S3 URL, try to construct from proxy_url and image_path
      if (imageData['proxy_url'] != null && imageData['image_path'] != null) {
        String proxyUrl = imageData['proxy_url'].toString();
        String imagePath = imageData['image_path'].toString();
        
        // Remove trailing slash from proxy_url and leading slash from image_path to avoid double slashes
        if (proxyUrl.endsWith('/')) {
          proxyUrl = proxyUrl.substring(0, proxyUrl.length - 1);
        }
        if (imagePath.startsWith('/')) {
          imagePath = imagePath.substring(1);
        }
        
        return '$proxyUrl/$imagePath';
      }
      
      // Fallback to other possible fields
      return imageData['url'] ?? 
             imageData['image_url'] ?? 
             imageData['proxy_url'] ?? 
             imageData['original_image'] ??
             imageData['path']?['proxy_url'] ??
             imageData['path']?['image_path'];
    }
    
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'desc': desc,
      'logo': logo,
      'banner': banner,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'phone': phone,
      'phone_no': phoneNo,
      'email': email,
      'status': status,
      'city_id': cityId,
      'country_id': countryId,
      'preparation_time': preparationTime,
      'order_pre_time': orderPreTime,
      'auto_reject_time': autoRejectTime,
      'order_min_amount': orderMinAmount,
      'delivery_charge': deliveryCharge,
      'minimum_order_amount': minimumOrderAmount,
      'rating': rating,
      'total_reviews': totalReviews,
      'is_open': isOpen,
      'is_featured': isFeatured,
      'is_delivery_available': isDeliveryAvailable,
      'is_pickup_available': isPickupAvailable,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'show_slot': showSlot,
      'dine_in': dineIn,
      'delivery': delivery,
      'takeaway': takeaway,
      'service_fee_percent': serviceFeePercent,
      'order_amount_for_delivery_fee': orderAmountForDeliveryFee,
      'delivery_fee_minimum': deliveryFeeMinimum,
      'delivery_fee_maximum': deliveryFeeMaximum,
      'closed_store_order_scheduled': closedStoreOrderScheduled,
      'slug': slug,
      'city': city,
      'state': state,
      'country': country,
      'country_code': countryCode,
      'is_vendor_closed': isVendorClosed,
      'is_wishlist': isWishlist,
    };
  }
}

class VendorDetails {
  final VendorAddress? vendorAddress;
  final List<VendorTable>? vendorTables;

  VendorDetails({
    this.vendorAddress,
    this.vendorTables,
  });

  factory VendorDetails.fromJson(Map<String, dynamic> json) {
    return VendorDetails(
      vendorAddress: json['vendor_address'] != null
          ? VendorAddress.fromJson(json['vendor_address'])
          : null,
      vendorTables: (json['vendor_tables'] as List?)
          ?.map((e) => VendorTable.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_address': vendorAddress?.toJson(),
      'vendor_tables': vendorTables?.map((e) => e.toJson()).toList(),
    };
  }
}

class VendorAddress {
  final int? id;
  final String? address;
  final double? latitude;
  final double? longitude;

  VendorAddress({
    this.id,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory VendorAddress.fromJson(Map<String, dynamic> json) {
    return VendorAddress(
      id: json['id'],
      address: json['address'],
      latitude: CartModel._parseDouble(json['latitude']),
      longitude: CartModel._parseDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class VendorTable {
  final int? id;
  final int? tableNumber;
  final int? seatingNumber;
  final TableCategory? category;

  VendorTable({
    this.id,
    this.tableNumber,
    this.seatingNumber,
    this.category,
  });

  factory VendorTable.fromJson(Map<String, dynamic> json) {
    return VendorTable(
      id: json['id'],
      tableNumber: json['table_number'],
      seatingNumber: json['seating_number'],
      category: json['category'] != null
          ? TableCategory.fromJson(json['category'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_number': tableNumber,
      'seating_number': seatingNumber,
      'category': category?.toJson(),
    };
  }
}

class TableCategory {
  final int? id;
  final String? title;

  TableCategory({
    this.id,
    this.title,
  });

  factory TableCategory.fromJson(Map<String, dynamic> json) {
    return TableCategory(
      id: json['id'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}

class CouponData {
  final int? couponId;
  final String? name;
  final double? amount;

  CouponData({
    this.couponId,
    this.name,
    this.amount,
  });

  factory CouponData.fromJson(Map<String, dynamic> json) {
    return CouponData(
      couponId: json['coupon_id'],
      name: json['name'],
      amount: CartModel._parseDouble(json['amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coupon_id': couponId,
      'name': name,
      'amount': amount,
    };
  }
}