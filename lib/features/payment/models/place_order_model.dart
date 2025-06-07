class PlaceOrderRequest {
  final int selectedAddressId;
  final int paymentOptionId;
  final String? paymentOptionCode;
  final double? tip;
  final String? deliveryInstructions;
  final String? orderNote;
  final String? scheduleType;
  final DateTime? scheduledDateTime;
  final String? cardNumber;
  final String? cardHolderName;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cvv;
  final String? transactionId;

  PlaceOrderRequest({
    required this.selectedAddressId,
    required this.paymentOptionId,
    this.paymentOptionCode,
    this.tip,
    this.deliveryInstructions,
    this.orderNote,
    this.scheduleType,
    this.scheduledDateTime,
    this.cardNumber,
    this.cardHolderName,
    this.expiryMonth,
    this.expiryYear,
    this.cvv,
    this.transactionId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'address_id': selectedAddressId,
      'payment_option_id': paymentOptionId,
      'order_type': 'delivery', // Default to delivery
      'tip_amount': tip ?? 0,
      'currency_id': 1, // Add currency_id - matches the header currency value
    };

    // Add payment option code if provided
    if (paymentOptionCode != null) {
      data['payment_option'] = paymentOptionCode;
    }

    if (deliveryInstructions?.isNotEmpty == true) {
      data['instructions'] = deliveryInstructions;
      data['comment_for_pickup_driver'] = deliveryInstructions; // Keep for backward compatibility
    }

    if (orderNote?.isNotEmpty == true) {
      data['comment_for_vendor'] = orderNote;
    }

    if (scheduleType != null && scheduleType != 'now') {
      data['schedule_type'] = scheduleType;
      if (scheduledDateTime != null) {
        data['scheduled_date_time'] = scheduledDateTime!.toIso8601String();
      }
    }

    // Add card details if present (for tokenized payments)
    if (cardNumber != null) {
      data['card_number'] = cardNumber;
      data['card_holder_name'] = cardHolderName;
      data['expiry_month'] = expiryMonth;
      data['expiry_year'] = expiryYear;
      data['cvv'] = cvv;
    }

    // Add transaction ID for online payments
    if (transactionId != null) {
      data['transaction_id'] = transactionId;
    }

    return data;
  }
}

class PlaceOrderResponse {
  final String? status;
  final String? message;
  final OrderData? data;
  final bool requiresPayment;
  final String? paymentUrl;

  PlaceOrderResponse({
    this.status,
    this.message,
    this.data,
    this.requiresPayment = false,
    this.paymentUrl,
  });

  factory PlaceOrderResponse.fromJson(Map<String, dynamic> json) {
    // Check if payment is required
    bool requiresPayment = false;
    String? paymentUrl;
    
    if (json['data'] != null && json['data'] is Map) {
      requiresPayment = json['data']['payment_required'] == true ||
                       json['data']['payment_url'] != null;
      paymentUrl = json['data']['payment_url'];
    }

    return PlaceOrderResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? OrderData.fromJson(json['data']) : null,
      requiresPayment: requiresPayment,
      paymentUrl: paymentUrl,
    );
  }

  bool get isSuccess => status == 'Success' || status == '200' || status == '201';
}

class OrderData {
  final int? userId;
  final String? orderNumber;
  final int? addressId;
  final int? paymentOptionId;
  final int? id;
  final double? totalAmount;
  final double? totalDiscount;
  final double? taxableAmount;
  final double? totalDeliveryFee;
  final double? loyaltyPointsUsed;
  final double? loyaltyAmountSaved;
  final double? payableAmount;
  final double? loyaltyPointsEarned;
  final int? loyaltyMembershipId;
  final String? createdAt;
  final String? updatedAt;

  OrderData({
    this.userId,
    this.orderNumber,
    this.addressId,
    this.paymentOptionId,
    this.id,
    this.totalAmount,
    this.totalDiscount,
    this.taxableAmount,
    this.totalDeliveryFee,
    this.loyaltyPointsUsed,
    this.loyaltyAmountSaved,
    this.payableAmount,
    this.loyaltyPointsEarned,
    this.loyaltyMembershipId,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return OrderData(
      userId: json['user_id'],
      orderNumber: json['order_number'],
      addressId: json['address_id'],
      paymentOptionId: json['payment_option_id'],
      id: json['id'],
      totalAmount: parseDouble(json['total_amount']),
      totalDiscount: parseDouble(json['total_discount']),
      taxableAmount: parseDouble(json['taxable_amount']),
      totalDeliveryFee: parseDouble(json['total_delivery_fee']),
      loyaltyPointsUsed: parseDouble(json['loyalty_points_used']),
      loyaltyAmountSaved: parseDouble(json['loyalty_amount_saved']),
      payableAmount: parseDouble(json['payable_amount']),
      loyaltyPointsEarned: parseDouble(json['loyalty_points_earned']),
      loyaltyMembershipId: json['loyalty_membership_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'order_number': orderNumber,
      'address_id': addressId,
      'payment_option_id': paymentOptionId,
      'id': id,
      'total_amount': totalAmount,
      'total_discount': totalDiscount,
      'taxable_amount': taxableAmount,
      'total_delivery_fee': totalDeliveryFee,
      'loyalty_points_used': loyaltyPointsUsed,
      'loyalty_amount_saved': loyaltyAmountSaved,
      'payable_amount': payableAmount,
      'loyalty_points_earned': loyaltyPointsEarned,
      'loyalty_membership_id': loyaltyMembershipId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class OrderInfo {
  final int? id;
  final String? orderNumber;
  final double? payableAmount;
  final String? createdAt;

  OrderInfo({
    this.id,
    this.orderNumber,
    this.payableAmount,
    this.createdAt,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return OrderInfo(
      id: json['id'],
      orderNumber: json['order_number'],
      payableAmount: parseDouble(json['payable_amount']),
      createdAt: json['created_at'],
    );
  }
}