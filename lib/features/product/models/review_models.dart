class ProductReviewUserModel {
  final String id;
  final String name;

  const ProductReviewUserModel({required this.id, required this.name});

  factory ProductReviewUserModel.fromJson(Map<String, dynamic> json) {
    return ProductReviewUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Parent',
    );
  }
}

class ProductReviewModel {
  final String id;
  final String productId;
  final ProductReviewUserModel user;
  final int rating;
  final String? title;
  final String? comment;
  final bool isApproved;
  final String createdAt;
  final String? updatedAt;

  const ProductReviewModel({
    required this.id,
    required this.productId,
    required this.user,
    required this.rating,
    this.title,
    this.comment,
    required this.isApproved,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    final ratingNum = json['rating'] as num?;
    if (ratingNum == null) {
      throw const FormatException('Missing required review rating field');
    }
    final createdAtStr = json['createdAt']?.toString();
    if (createdAtStr == null || createdAtStr.isEmpty) {
      throw const FormatException('Missing required review createdAt field');
    }

    return ProductReviewModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      user: ProductReviewUserModel.fromJson(
        json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : {},
      ),
      rating: ratingNum.toInt(),
      title: json['title']?.toString(),
      comment: json['comment']?.toString(),
      isApproved: json['isApproved'] as bool? ?? true,
      createdAt: createdAtStr,
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class ProductRatingSummaryModel {
  final double average;
  final int count;
  final Map<int, int> distribution;

  const ProductRatingSummaryModel({
    required this.average,
    required this.count,
    required this.distribution,
  });

  factory ProductRatingSummaryModel.fromJson(Map<String, dynamic> json) {
    final distMap = <int, int>{};
    if (json['distribution'] is Map) {
      final rawDist = json['distribution'] as Map;
      rawDist.forEach((key, value) {
        final k = int.tryParse(key.toString());
        final v = (value as num?)?.toInt() ?? 0;
        if (k != null) distMap[k] = v;
      });
    }
    return ProductRatingSummaryModel(
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      distribution: distMap,
    );
  }
}

class PaginatedReviewsResultModel {
  final List<ProductReviewModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedReviewsResultModel({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedReviewsResultModel.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List? ?? [])
        .map((e) => ProductReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedReviewsResultModel(
      items: list,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
