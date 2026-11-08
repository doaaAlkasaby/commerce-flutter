class AppSettingsModel {
  final List<int> androidBuild;
  final List<int> iosBuild;
  final bool forceUpdate;
  final String currencyAr;
  final String currencyEn;
  final List<String> features;

  const AppSettingsModel({
    required this.androidBuild,
    required this.iosBuild,
    required this.forceUpdate,
    required this.currencyAr,
    required this.currencyEn,
    required this.features,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      androidBuild:
          (json['android_build'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      iosBuild:
          (json['ios_build'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      forceUpdate: json['forceUpdate'] ?? false,
      currencyAr: json['currency_ar']?.toString() ?? '',
      currencyEn: json['currency_en']?.toString() ?? '',
      features:
          (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
