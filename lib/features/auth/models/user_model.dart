class UserModel {
  final int? id;
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
  final Map<String, dynamic>? additionalData;

  UserModel({
    this.id,
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
    this.additionalData,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      dialCode: json['dial_code'],
      countryCode: json['country_code'],
      authToken: json['auth_token'],
      image: json['image'],
      isEmailVerified: json['is_email_verified'] == 1,
      isPhoneVerified: json['is_phone_verified'] == 1,
      referralCode: json['referral_code'],
      deviceType: json['device_type'],
      deviceToken: json['device_token'],
      additionalData: json,
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
    Map<String, dynamic>? additionalData,
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
      additionalData: additionalData ?? this.additionalData,
    );
  }
}