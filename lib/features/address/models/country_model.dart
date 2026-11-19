class CountryModel {
  final String code;
  final String name;
  final String currencyCode;

  bool get isValidIso =>
      code.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(code);

  const CountryModel({
    required this.code,
    required this.name,
    required this.currencyCode,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      code: (json['code']?.toString() ?? '').trim().toUpperCase(),
      name: json['name']?.toString() ?? '',
      currencyCode: json['currencyCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'name': name, 'currencyCode': currencyCode};
  }
}
