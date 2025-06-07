class PaymentMethod {
  final int id;
  final String title;
  final String? credentials;
  final String? code;
  final int? offSite;
  final int status;
  final int? isInstantBooking;

  PaymentMethod({
    required this.id,
    required this.title,
    this.credentials,
    this.code,
    this.offSite,
    required this.status,
    this.isInstantBooking,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      title: json['title_lng'] ?? json['title'] ?? '',
      credentials: json['credentials'],
      code: json['code'],
      offSite: json['off_site'],
      status: json['status'] ?? 1, // Default to 1 (active) if not provided
      isInstantBooking: json['is_instant_booking'],
    );
  }

  bool get isOffSite => offSite == 1;
  bool get isActive => status == 1;
  bool get isCashOnDelivery => code?.toLowerCase() == 'cod' || title.toLowerCase().contains('cash');
  bool get isCard => code?.toLowerCase().contains('stripe') == true || 
                     title.toLowerCase().contains('card') ||
                     title.toLowerCase().contains('stripe');
}