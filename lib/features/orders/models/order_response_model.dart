import 'package:flutter/foundation.dart';
import 'order_model.dart';

/// Model that matches the actual API response structure for orders
class OrderResponseModel {
  final int id;
  final int orderId;
  final int vendorId;
  final int? vendorDineinTableId;
  final int userId;
  final String deliveryFee;
  final int status;
  final int? couponId;
  final String? couponCode;
  final String taxableAmount;
  final String subtotalAmount;
  final String payableAmount;
  final String discountAmount;
  final String? webHookCode;
  final String adminCommissionPercentageAmount;
  final String? adminCommissionFixedAmount;
  final int couponPaidBy;
  final int? dispatcherStatusOptionId;
  final int orderStatusOptionId;
  final String createdAt;
  final String updatedAt;
  final String? dispatchTrakingUrl;
  final int orderPreTime;
  final int userToVendorTime;
  final String? rejectReason;
  final String serviceFeePercentageAmount;
  final String? cancelledBy;
  final String? lalamoveTrackingUrl;
  final String shippingDeliveryType;
  final String courierId;
  final String? shipOrderId;
  final String? shipShipmentId;
  final String? shipAwbId;
  final String totalContainerCharges;
  final String? acceptedBy;
  final int? driverId;
  final String? scheduledDateTime;
  final String? scheduleSlot;
  final int isRestricted;
  final String totalMarkupPrice;
  final String? fixedFee;
  final String additionalPrice;
  final String fixedServiceChargeAmount;
  final String tollAmount;
  final int? returnReasonId;
  final int isExchangedOrReturned;
  final int? exchangeOrderVendorId;
  final String? deliveryResponse;
  final String subscriptionDiscountAdmin;
  final String subscriptionDiscountVendor;
  final int bidDiscount;
  final int subscriptionInvoicesVendorId;
  final String? extraTime;
  final String? roadieTrackingUrl;
  final String waitingTime;
  final String waitingPrice;
  final String? labelId;
  final String? labelPdf;
  final String userName;
  final Map<String, dynamic>? userImage;
  final String dateTime;
  final String paymentOptionTitle;
  final String orderNumber;
  final String schedulePickup;
  final String? scheduledSlot;
  final String scheduleDropoff;
  final String? dropoffScheduledSlot;
  final int isPostpay;
  final String type;
  final int isEdited;
  final int isEditable;
  final Map<String, dynamic>? orderStatus;
  final int isLongTerm;
  final String luxuryOptionName;
  final List<Map<String, dynamic>>? productDetails;
  final int itemCount;
  final int returnRequestStatus;
  final int returnable;
  final int replaceable;
  final List<Map<String, dynamic>>? products;
  final Map<String, dynamic>? vendor;
  final Map<String, dynamic>? exchangedOfOrder;
  final Map<String, dynamic>? exchangedToOrder;
  final Map<String, dynamic>? cancelRequest;

  OrderResponseModel({
    required this.id,
    required this.orderId,
    required this.vendorId,
    this.vendorDineinTableId,
    required this.userId,
    required this.deliveryFee,
    required this.status,
    this.couponId,
    this.couponCode,
    required this.taxableAmount,
    required this.subtotalAmount,
    required this.payableAmount,
    required this.discountAmount,
    this.webHookCode,
    required this.adminCommissionPercentageAmount,
    this.adminCommissionFixedAmount,
    required this.couponPaidBy,
    this.dispatcherStatusOptionId,
    required this.orderStatusOptionId,
    required this.createdAt,
    required this.updatedAt,
    this.dispatchTrakingUrl,
    required this.orderPreTime,
    required this.userToVendorTime,
    this.rejectReason,
    required this.serviceFeePercentageAmount,
    this.cancelledBy,
    this.lalamoveTrackingUrl,
    required this.shippingDeliveryType,
    required this.courierId,
    this.shipOrderId,
    this.shipShipmentId,
    this.shipAwbId,
    required this.totalContainerCharges,
    this.acceptedBy,
    this.driverId,
    this.scheduledDateTime,
    this.scheduleSlot,
    required this.isRestricted,
    required this.totalMarkupPrice,
    this.fixedFee,
    required this.additionalPrice,
    required this.fixedServiceChargeAmount,
    required this.tollAmount,
    this.returnReasonId,
    required this.isExchangedOrReturned,
    this.exchangeOrderVendorId,
    this.deliveryResponse,
    required this.subscriptionDiscountAdmin,
    required this.subscriptionDiscountVendor,
    required this.bidDiscount,
    required this.subscriptionInvoicesVendorId,
    this.extraTime,
    this.roadieTrackingUrl,
    required this.waitingTime,
    required this.waitingPrice,
    this.labelId,
    this.labelPdf,
    required this.userName,
    this.userImage,
    required this.dateTime,
    required this.paymentOptionTitle,
    required this.orderNumber,
    required this.schedulePickup,
    this.scheduledSlot,
    required this.scheduleDropoff,
    this.dropoffScheduledSlot,
    required this.isPostpay,
    required this.type,
    required this.isEdited,
    required this.isEditable,
    this.orderStatus,
    required this.isLongTerm,
    required this.luxuryOptionName,
    this.productDetails,
    required this.itemCount,
    required this.returnRequestStatus,
    required this.returnable,
    required this.replaceable,
    this.products,
    this.vendor,
    this.exchangedOfOrder,
    this.exchangedToOrder,
    this.cancelRequest,
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

  factory OrderResponseModel.fromJson(Map<String, dynamic> json) {
    debugPrint('=== Parsing OrderResponseModel ===');
    debugPrint('JSON keys: ${json.keys.toList()}');
    
    try {
      debugPrint('Parsing id: ${json['id']} (${json['id'].runtimeType})');
      final id = _parseInt(json['id']);
      
      debugPrint('Parsing order_id: ${json['order_id']} (${json['order_id'].runtimeType})');
      final orderId = _parseInt(json['order_id']);
      
      debugPrint('Parsing vendor_id: ${json['vendor_id']} (${json['vendor_id'].runtimeType})');
      final vendorId = _parseInt(json['vendor_id']);
      
      // Debug problematic string fields
      debugPrint('Parsing cancelled_by: ${json['cancelled_by']} (${json['cancelled_by'].runtimeType})');
      debugPrint('Parsing accepted_by: ${json['accepted_by']} (${json['accepted_by'].runtimeType})');
      debugPrint('Parsing courier_id: ${json['courier_id']} (${json['courier_id'].runtimeType})');
      debugPrint('Parsing type: ${json['type']} (${json['type'].runtimeType})');
      
      return OrderResponseModel(
      id: id,
      orderId: orderId,
      vendorId: vendorId,
      vendorDineinTableId: json['vendor_dinein_table_id'] != null ? _parseInt(json['vendor_dinein_table_id']) : null,
      userId: _parseInt(json['user_id']),
      deliveryFee: _parseString(json['delivery_fee'], '0.00'),
      status: _parseInt(json['status']),
      couponId: json['coupon_id'] != null ? _parseInt(json['coupon_id']) : null,
      couponCode: json['coupon_code'],
      taxableAmount: _parseString(json['taxable_amount'], '0.00'),
      subtotalAmount: _parseString(json['subtotal_amount'], '0.00'),
      payableAmount: _parseString(json['payable_amount'], '0.00'),
      discountAmount: _parseString(json['discount_amount'], '0.00'),
      webHookCode: json['web_hook_code'],
      adminCommissionPercentageAmount: _parseString(json['admin_commission_percentage_amount'], '0.00'),
      adminCommissionFixedAmount: json['admin_commission_fixed_amount'],
      couponPaidBy: _parseInt(json['coupon_paid_by']),
      dispatcherStatusOptionId: json['dispatcher_status_option_id'] != null ? _parseInt(json['dispatcher_status_option_id']) : null,
      orderStatusOptionId: _parseInt(json['order_status_option_id']),
      createdAt: _parseString(json['created_at'], ''),
      updatedAt: _parseString(json['updated_at'], ''),
      dispatchTrakingUrl: json['dispatch_traking_url'],
      orderPreTime: _parseInt(json['order_pre_time']),
      userToVendorTime: _parseInt(json['user_to_vendor_time']),
      rejectReason: json['reject_reason'],
      serviceFeePercentageAmount: _parseString(json['service_fee_percentage_amount'], '0.00'),
      cancelledBy: json['cancelled_by'] != null ? _parseString(json['cancelled_by']) : null,
      lalamoveTrackingUrl: json['lalamove_tracking_url'],
      shippingDeliveryType: _parseString(json['shipping_delivery_type'], 'D'),
      courierId: _parseString(json['courier_id'], '0'),
      shipOrderId: json['ship_order_id'],
      shipShipmentId: json['ship_shipment_id'],
      shipAwbId: json['ship_awb_id'],
      totalContainerCharges: _parseString(json['total_container_charges'], '0.0000'),
      acceptedBy: json['accepted_by'] != null ? json['accepted_by'].toString() : null,
      driverId: json['driver_id'] != null ? _parseInt(json['driver_id']) : null,
      scheduledDateTime: json['scheduled_date_time'],
      scheduleSlot: json['schedule_slot'],
      isRestricted: _parseInt(json['is_restricted']),
      totalMarkupPrice: _parseString(json['total_markup_price'], '0.00'),
      fixedFee: json['fixed_fee'],
      additionalPrice: _parseString(json['additional_price'], '0.0000'),
      fixedServiceChargeAmount: _parseString(json['fixed_service_charge_amount'], '0.00'),
      tollAmount: _parseString(json['toll_amount'], '0.00'),
      returnReasonId: json['return_reason_id'] != null ? _parseInt(json['return_reason_id']) : null,
      isExchangedOrReturned: _parseInt(json['is_exchanged_or_returned']),
      exchangeOrderVendorId: json['exchange_order_vendor_id'] != null ? _parseInt(json['exchange_order_vendor_id']) : null,
      deliveryResponse: json['delivery_response'],
      subscriptionDiscountAdmin: _parseString(json['subscription_discount_admin'], '0.00'),
      subscriptionDiscountVendor: _parseString(json['subscription_discount_vendor'], '0.00'),
      bidDiscount: _parseInt(json['bid_discount']),
      subscriptionInvoicesVendorId: _parseInt(json['subscription_invoices_vendor_id']),
      extraTime: json['extra_time'],
      roadieTrackingUrl: json['roadie_tracking_url'],
      waitingTime: _parseString(json['waiting_time'], '0.00'),
      waitingPrice: _parseString(json['waiting_price'], '0.00'),
      labelId: json['label_id'],
      labelPdf: json['label_pdf'],
      userName: _parseString(json['user_name'], ''),
      userImage: json['user_image'],
      dateTime: _parseString(json['date_time'], ''),
      paymentOptionTitle: _parseString(json['payment_option_title'], ''),
      orderNumber: _parseString(json['order_number'], ''),
      schedulePickup: _parseString(json['schedule_pickup'], ''),
      scheduledSlot: json['scheduled_slot'],
      scheduleDropoff: _parseString(json['schedule_dropoff'], ''),
      dropoffScheduledSlot: json['dropoff_scheduled_slot'],
      isPostpay: _parseInt(json['is_postpay']),
      type: json['type'] != null ? json['type'].toString() : '',
      isEdited: _parseInt(json['is_edited']),
      isEditable: _parseInt(json['is_editable']),
      orderStatus: json['order_status'],
      isLongTerm: _parseInt(json['is_long_term']),
      luxuryOptionName: _parseString(json['luxury_option_name'], ''),
      productDetails: json['product_details'] != null ? List<Map<String, dynamic>>.from(json['product_details']) : null,
      itemCount: _parseInt(json['item_count']),
      returnRequestStatus: _parseInt(json['return_request_status']),
      returnable: _parseInt(json['returnable']),
      replaceable: _parseInt(json['replaceable']),
      products: json['products'] != null ? List<Map<String, dynamic>>.from(json['products']) : null,
      vendor: json['vendor'],
      exchangedOfOrder: json['exchanged_of_order'],
      exchangedToOrder: json['exchanged_to_order'],
      cancelRequest: json['cancel_request'],
    );
    } catch (e, stackTrace) {
      debugPrint('ERROR parsing OrderResponseModel: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Convert this response model to the simplified OrderModel
  OrderModel toOrderModel() {
    // Extract status from order_status if available
    String statusName = 'Unknown';
    if (orderStatus != null && orderStatus!['current_status'] != null) {
      statusName = orderStatus!['current_status']['title'] ?? 'Unknown';
    }
    
    // Debug logging
    debugPrint('=== Converting OrderResponseModel to OrderModel ===');
    debugPrint('ID: $id (${id.runtimeType})');
    debugPrint('User ID: $userId (${userId.runtimeType})');
    debugPrint('Status ID: $orderStatusOptionId (${orderStatusOptionId.runtimeType})');
    debugPrint('Status Name: $statusName (${statusName.runtimeType})');
    debugPrint('Dispatch Tracking URL: $dispatchTrakingUrl');
    debugPrint('Payable Amount: $payableAmount (${payableAmount.runtimeType})');
    debugPrint('Payment Option Title: $paymentOptionTitle (${paymentOptionTitle.runtimeType})');
    debugPrint('Shipping Delivery Type: $shippingDeliveryType (${shippingDeliveryType.runtimeType})');
    debugPrint('Type: $type (${type.runtimeType})');
    debugPrint('===================================================');

    // Parse vendor
    OrderVendorModel? vendorModel;
    if (vendor != null) {
      vendorModel = OrderVendorModel.fromJson(vendor!);
    }

    // Parse products
    List<OrderProductModel>? productModels;
    if (products != null) {
      productModels = products!
          .map((p) => OrderProductModel.fromJson(p))
          .toList();
    }

    // Create a vendor detail model to include dispatch tracking URL
    List<OrderVendorDetailModel>? vendorDetails;
    if (vendorModel != null) {
      vendorDetails = [
        OrderVendorDetailModel(
          id: id,
          vendorId: vendorId,
          vendorName: vendorModel.name,
          logo: vendorModel.logo,
          dispatchTrakingUrl: dispatchTrakingUrl, // Include the tracking URL here
          dispatcherStatusOptionId: dispatcherStatusOptionId,
          vendorDispatcherStatus: null,
          vendorDispatcherStatusCount: 6,
          dispatcherStatusIcons: null,
          orderStatus: null,
          products: productModels,
          allStatus: null,
          driverId: driverId,
          vendor: vendorModel,
          agentLocation: null,
          tasks: null,
          eta: null,
          discountAmount: _parseDouble(discountAmount),
          deliveryFee: _parseDouble(deliveryFee),
          payableAmount: _parseDouble(payableAmount),
        ),
      ];
    }

    return OrderModel(
      id: id,
      orderId: orderId,
      vendorId: vendorId,
      userId: userId,
      addressId: null, // Not provided in this response structure
      statusId: orderStatusOptionId,
      status: statusName,
      totalAmount: _parseDouble(payableAmount),
      paymentStatus: null, // Not provided in this response
      paymentMethod: paymentOptionTitle,
      deliveryType: shippingDeliveryType,
      scheduledDate: scheduledDateTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
      products: productModels,
      vendor: vendorModel,
      address: null, // Not provided in this response structure
      orderNumber: orderNumber,
      vendors: vendorDetails, // Include the vendor details with tracking URL
    );
  }
}