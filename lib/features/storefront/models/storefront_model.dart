class StorefrontModel {
  final String id;
  final String slug;
  final String name;
  final String? logoUrl;
  final String currency; // ISO 4217 Currency Code (e.g. KWD, SAR, USD)
  final String? timezone;
  final Map<String, dynamic> settings;

  const StorefrontModel({
    required this.id,
    required this.slug,
    required this.name,
    this.logoUrl,
    required this.currency,
    this.timezone,
    this.settings = const {},
  });

  static final RegExp _isoCurrencyRegex = RegExp(r'^[A-Z]{3}$');
  static const Set<String> _supportedIsoCurrencies = {'KWD', 'SAR', 'USD', 'EUR', 'GBP', 'AED', 'QAR', 'BHD', 'OMR', 'EGP'};

  factory StorefrontModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['id'] is! String) {
      throw const FormatException('Storefront response missing required "id" field');
    }
    final id = json['id'].toString().trim();
    if (id.isEmpty) {
      throw const FormatException('Storefront response contains empty "id" field');
    }

    if (json['slug'] == null || json['slug'] is! String) {
      throw const FormatException('Storefront response missing required "slug" field');
    }
    final slug = json['slug'].toString().trim();
    if (slug.isEmpty) {
      throw const FormatException('Storefront response contains empty "slug" field');
    }

    if (json['name'] == null || json['name'] is! String) {
      throw const FormatException('Storefront response missing required "name" field');
    }
    final name = json['name'].toString().trim();
    if (name.isEmpty) {
      throw const FormatException('Storefront response contains empty "name" field');
    }

    if (json['currency'] == null || json['currency'] is! String) {
      throw const FormatException('Storefront response missing required ISO "currency" field');
    }
    final rawCurrency = json['currency'].toString().trim().toUpperCase();
    if (!_isoCurrencyRegex.hasMatch(rawCurrency) || !_supportedIsoCurrencies.contains(rawCurrency)) {
      throw const FormatException('Storefront response contains invalid or unsupported ISO 4217 currency code');
    }

    return StorefrontModel(
      id: id,
      slug: slug,
      name: name,
      logoUrl: json['logoUrl']?.toString().trim(),
      currency: rawCurrency,
      timezone: json['timezone']?.toString().trim(),
      settings: json['settings'] is Map<String, dynamic>
          ? json['settings'] as Map<String, dynamic>
          : const {},
    );
  }

  /// Helper to convert ISO 4217 currency codes to presentation symbols
  String get currencySymbol {
    switch (currency) {
      case 'KWD':
        return 'KWD';
      case 'SAR':
        return 'SAR';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }
}
