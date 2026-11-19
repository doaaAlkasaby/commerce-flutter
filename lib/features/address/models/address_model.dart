class AddressModel {
  final String id;
  final String? label;
  final String firstName;
  final String lastName;
  final String? company;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String? postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final bool isDefaultShipping;
  final bool isDefaultBilling;

  static String normalizeCountryCode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'KW';
    final upper = raw.trim().toUpperCase();
    if (upper == 'KUWAIT' || upper == 'KWT' || upper == 'الكويت') return 'KW';
    if (upper == 'SAUDI ARABIA' ||
        upper == 'SAU' ||
        upper == 'KSA' ||
        upper == 'السعودية' ||
        upper == 'المملكة العربية السعودية')
      return 'SA';
    if (upper == 'UNITED ARAB EMIRATES' ||
        upper == 'UAE' ||
        upper == 'ARE' ||
        upper == 'الإمارات' ||
        upper == 'الإمارات العربية المتحدة')
      return 'AE';
    if (upper == 'EGYPT' || upper == 'EGY' || upper == 'مصر') return 'EG';
    if (upper.length == 2) return upper;
    return upper;
  }

  // Backwards compatibility getters
  String get title => label != null && label!.isNotEmpty ? label! : 'HOME';
  String get fullName => '$firstName $lastName'.trim();
  String get streetAddress => addressLine1;
  String get phoneNumber => phone ?? '';
  String get countryCode => country;
  bool get isDefault => isDefaultShipping;

  const AddressModel({
    required this.id,
    this.label,
    required this.firstName,
    required this.lastName,
    this.company,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    this.postalCode,
    required this.country,
    this.latitude,
    this.longitude,
    this.phone,
    this.isDefaultShipping = false,
    this.isDefaultBilling = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? json['title']?.toString(),
      firstName:
          json['firstName']?.toString() ??
          json['fullName']?.toString().split(' ').first ??
          'Customer',
      lastName:
          json['lastName']?.toString() ??
          (((json['fullName']?.toString().split(' ').length ?? 0) > 1)
              ? json['fullName']!.toString().split(' ').sublist(1).join(' ')
              : 'User'),
      company: json['company']?.toString(),
      addressLine1:
          json['addressLine1']?.toString() ??
          json['streetAddress']?.toString() ??
          '',
      addressLine2: json['addressLine2']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString(),
      postalCode: json['postalCode']?.toString(),
      country: normalizeCountryCode(
        json['countryCode']?.toString() ?? json['country']?.toString(),
      ),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      phone: json['phone']?.toString() ?? json['phoneNumber']?.toString(),
      isDefaultShipping:
          json['isDefaultShipping'] ?? json['isDefault'] ?? false,
      isDefaultBilling: json['isDefaultBilling'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (label != null && label!.isNotEmpty) 'label': label,
      'firstName': firstName,
      'lastName': lastName,
      if (company != null && company!.isNotEmpty) 'company': company,
      'addressLine1': addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty)
        'addressLine2': addressLine2,
      'city': city,
      if (state != null && state!.isNotEmpty) 'state': state,
      if (postalCode != null && postalCode!.isNotEmpty)
        'postalCode': postalCode,
      'country': country,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'isDefaultShipping': isDefaultShipping,
      'isDefaultBilling': isDefaultBilling,
    };
  }

  AddressModel copyWith({
    String? id,
    String? label,
    String? firstName,
    String? lastName,
    String? company,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? phone,
    bool? isDefaultShipping,
    bool? isDefaultBilling,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      company: company ?? this.company,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      isDefaultShipping: isDefaultShipping ?? this.isDefaultShipping,
      isDefaultBilling: isDefaultBilling ?? this.isDefaultBilling,
    );
  }
}
