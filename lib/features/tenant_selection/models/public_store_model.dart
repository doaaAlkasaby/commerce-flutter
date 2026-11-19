class PublicStoreModel {
  final String id;
  final String slug;
  final String name;
  final String? logoUrl;
  final String? coverImageUrl;
  final String currency;

  const PublicStoreModel({
    required this.id,
    required this.slug,
    required this.name,
    this.logoUrl,
    this.coverImageUrl,
    required this.currency,
  });

  factory PublicStoreModel.fromJson(Map<String, dynamic> json) {
    return PublicStoreModel(
      id: json['id']?.toString().trim() ?? '',
      slug: json['slug']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      logoUrl: json['logoUrl']?.toString().trim(),
      coverImageUrl: json['coverImageUrl']?.toString().trim(),
      currency: json['currency']?.toString().trim().toUpperCase() ?? 'KWD',
    );
  }

  String get currencySymbol {
    switch (currency) {
      case 'KWD':
        return 'KWD';
      case 'SAR':
        return 'SAR';
      case 'AED':
        return 'AED';
      case 'EGP':
        return 'EGP';
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
