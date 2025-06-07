class OfferModel {
  final int? id;
  final String name;
  final String? description;
  final String? shortDescription;
  final String? promoCode;
  final String? discountType;
  final double? discountValue;
  final String? validFrom;
  final String? validTo;
  final double? minimumOrderValue;
  final bool isActive;

  OfferModel({
    this.id,
    required this.name,
    this.description,
    this.shortDescription,
    this.promoCode,
    this.discountType,
    this.discountValue,
    this.validFrom,
    this.validTo,
    this.minimumOrderValue,
    this.isActive = true,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'],
      name: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? json['desc'],
      shortDescription: json['short_desc'] ?? json['short_description'],
      promoCode: json['promo_code'] ?? json['code'] ?? json['name'],
      discountType: json['discount_type'] ?? json['type'] ?? json['promo_type_title'],
      discountValue: _parseDouble(json['discount_value'] ?? json['discount'] ?? json['amount']),
      validFrom: json['valid_from'] ?? json['start_date'],
      validTo: json['valid_to'] ?? json['end_date'],
      minimumOrderValue: _parseDouble(json['minimum_order_value'] ?? json['min_order']),
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['status'] == 'active',
    );
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'short_desc': shortDescription,
      'promo_code': promoCode,
      'discount_type': discountType,
      'discount_value': discountValue,
      'valid_from': validFrom,
      'valid_to': validTo,
      'minimum_order_value': minimumOrderValue,
      'is_active': isActive,
    };
  }
}