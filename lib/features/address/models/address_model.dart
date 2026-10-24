class AddressModel {
  final String id;
  final String title;
  final String fullName;
  final String streetAddress;
  final String city;
  final String postalCode;
  final String phoneNumber;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.title,
    required this.fullName,
    required this.streetAddress,
    required this.city,
    required this.postalCode,
    required this.phoneNumber,
    this.isDefault = false,
  });

  AddressModel copyWith({
    String? title,
    String? fullName,
    String? streetAddress,
    String? city,
    String? postalCode,
    String? phoneNumber,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id,
      title: title ?? this.title,
      fullName: fullName ?? this.fullName,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
