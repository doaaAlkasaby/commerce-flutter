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

  factory StorefrontModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final slug = json['slug']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    final rawCurrency = (json['currency']?.toString() ?? json['currencySymbol']?.toString())?.trim() ?? '';

    if (id.isEmpty) {
      throw const FormatException('Storefront response missing required "id" field');
    }
    if (slug.isEmpty) {
      throw const FormatException('Storefront response missing required "slug" field');
    }
    if (name.isEmpty) {
      throw const FormatException('Storefront response missing required "name" field');
    }
    if (rawCurrency.isEmpty) {
      throw const FormatException('Storefront response missing required ISO "currency" field');
    }

    return StorefrontModel(
      id: id,
      slug: slug,
      name: name,
      logoUrl: json['logoUrl']?.toString().trim(),
      currency: rawCurrency.toUpperCase(),
      timezone: json['timezone']?.toString().trim(),
      settings: json['settings'] is Map<String, dynamic>
          ? json['settings'] as Map<String, dynamic>
          : const {},
    );
  }

  /// Helper to convert ISO 4217 currency codes to presentation symbols where applicable
  String get currencySymbol {
    switch (currency.toUpperCase()) {
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
