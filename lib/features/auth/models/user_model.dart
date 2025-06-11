class UserModel {
  final int? id;
  final String? profileImage;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? dialCode;
  final String? countryCode;
  final String? authToken;
  final String? image;
  final bool? isEmailVerified;
  final bool? isPhoneVerified;
  final String? referralCode;
  final String? deviceType;
  final String? deviceToken;
  final Map<String, dynamic>? verifyDetails;
  final Map<String, dynamic>? clientPreference;
  final Map<String, dynamic>? additionalData;
  final bool? phoneNumberRequired;

  UserModel({
    this.id,
    this.profileImage,
    this.name,
    this.email,
    this.phoneNumber,
    this.dialCode,
    this.countryCode,
    this.authToken,
    this.image,
    this.isEmailVerified,
    this.isPhoneVerified,
    this.referralCode,
    this.deviceType,
    this.deviceToken,
    this.verifyDetails,
    this.clientPreference,
    this.additionalData,
    this.phoneNumberRequired,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse verify_details
    final verifyDetailsRaw = json['verify_details'];
    Map<String, dynamic>? verifyDetails;
    if (verifyDetailsRaw != null) {
      if (verifyDetailsRaw is Map<String, dynamic>) {
        verifyDetails = verifyDetailsRaw;
      }
    }

    return UserModel(
      id: json['id'],
      profileImage: json['profileImage'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      dialCode: json['dial_code'],
      countryCode: json['country_code'] ?? json['cca2'],
      authToken: json['auth_token'],
      image: json['image'],
      isEmailVerified: verifyDetails?['is_email_verified'] == 1 ||
          json['is_email_verified'] == 1,
      isPhoneVerified: verifyDetails?['is_phone_verified'] == 1 ||
          json['is_phone_verified'] == 1,
      referralCode:
          json['referral_code'] ?? json['refferal_code'], // Note: API has typo
      deviceType: json['device_type'],
      deviceToken: json['device_token'],
      verifyDetails: verifyDetails,
      clientPreference: json['client_preference'],
      additionalData: json,
      phoneNumberRequired: json['phone_number_required'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'dial_code': dialCode,
      'country_code': countryCode,
      'auth_token': authToken,
      'image': image,
      'is_email_verified': isEmailVerified == true ? 1 : 0,
      'is_phone_verified': isPhoneVerified == true ? 1 : 0,
      'referral_code': referralCode,
      'device_type': deviceType,
      'device_token': deviceToken,
      if (verifyDetails != null) 'verify_details': verifyDetails,
      if (clientPreference != null) 'client_preference': clientPreference,
      if (phoneNumberRequired != null)
        'phone_number_required': phoneNumberRequired! ? 1 : 0,
      if (additionalData != null) ...additionalData!,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? dialCode,
    String? countryCode,
    String? authToken,
    String? image,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? referralCode,
    String? deviceType,
    String? deviceToken,
    Map<String, dynamic>? verifyDetails,
    Map<String, dynamic>? clientPreference,
    Map<String, dynamic>? additionalData,
    bool? phoneNumberRequired,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dialCode: dialCode ?? this.dialCode,
      countryCode: countryCode ?? this.countryCode,
      authToken: authToken ?? this.authToken,
      image: image ?? this.image,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      referralCode: referralCode ?? this.referralCode,
      deviceType: deviceType ?? this.deviceType,
      deviceToken: deviceToken ?? this.deviceToken,
      verifyDetails: verifyDetails ?? this.verifyDetails,
      clientPreference: clientPreference ?? this.clientPreference,
      additionalData: additionalData ?? this.additionalData,
      phoneNumberRequired: phoneNumberRequired ?? this.phoneNumberRequired,
    );
  }

  // Helper methods to check verification requirements
  bool get needsPhoneVerification {
    final requiresVerification = clientPreference?['verify_phone'] == 1;
    final isVerified = isPhoneVerified == true;
    return requiresVerification && !isVerified;
  }

  bool get needsEmailVerification {
    final requiresVerification = clientPreference?['verify_email'] == 1;
    final isVerified = isEmailVerified == true;
    return requiresVerification && !isVerified;
  }

  bool get needsAnyVerification =>
      needsPhoneVerification || needsEmailVerification;
}
