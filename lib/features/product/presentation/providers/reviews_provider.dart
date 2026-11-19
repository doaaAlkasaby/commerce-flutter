import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/product/data/product_repository.dart';
import 'package:ecommerce/features/product/models/review_models.dart';

part 'reviews_provider.g.dart';

class PaginatedReviewsStateData {
  final List<ProductReviewModel> items;
  final ProductRatingSummaryModel? summary;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool isLoadingMore;
  final String? loadMoreError;
  final bool isSubmitting;

  const PaginatedReviewsStateData({
    required this.items,
    this.summary,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.isSubmitting = false,
  });

  bool get hasMore => page < totalPages;

  PaginatedReviewsStateData copyWith({
    List<ProductReviewModel>? items,
    ProductRatingSummaryModel? summary,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    bool? isLoadingMore,
    String? loadMoreError,
    bool? isSubmitting,
  }) {
    return PaginatedReviewsStateData(
      items: items ?? this.items,
      summary: summary ?? this.summary,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

@riverpod
class ProductReviewsController extends _$ProductReviewsController {
  int _requestRevision = 0;

  @override
  Future<PaginatedReviewsStateData> build(String productId) async {
    _requestRevision++;
    final currentRev = _requestRevision;

    final requestTenantSlug = ref.watch(selectedTenantSlugProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final requestUserId = user?.id;

    final repository = ProductRepository(ref.watch(dioClientProvider));

    final results = await Future.wait([
      repository.getPaginatedProductReviews(productId, page: 1, limit: 20),
      repository.getProductRatingSummary(productId),
    ]);

    if (!ref.mounted) {
      return const PaginatedReviewsStateData(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 1,
      );
    }

    final currentUserId = ref.read(currentUserProvider).value?.id;

    if (_requestRevision != currentRev ||
        ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
        currentUserId != requestUserId) {
      return const PaginatedReviewsStateData(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 1,
      );
    }

    final reviewsResult = results[0] as PaginatedReviewsResultModel;
    final summaryResult = results[1] as ProductRatingSummaryModel;

    return PaginatedReviewsStateData(
      items: reviewsResult.items,
      summary: summaryResult,
      page: reviewsResult.page,
      limit: reviewsResult.limit,
      total: reviewsResult.total,
      totalPages: reviewsResult.totalPages,
    );
  }

  Future<void> loadNextPage() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    final currentRev = _requestRevision;
    final requestTenantSlug = ref.read(selectedTenantSlugProvider);
    final requestUserId = ref.read(currentUserProvider).value?.id;

    state = AsyncValue.data(
      currentState.copyWith(isLoadingMore: true, loadMoreError: null),
    );

    try {
      final nextPage = currentState.page + 1;
      final repository = ProductRepository(ref.read(dioClientProvider));
      final result = await repository.getPaginatedProductReviews(
        productId,
        page: nextPage,
        limit: currentState.limit,
      );

      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;

      if (_requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          currentUserId != requestUserId) {
        return;
      }

      final latestState = state.value;
      if (latestState == null) return;

      final existingIds = latestState.items.map((i) => i.id).toSet();
      final uniqueNewItems = result.items
          .where((i) => !existingIds.contains(i.id))
          .toList();

      state = AsyncValue.data(
        latestState.copyWith(
          items: [...latestState.items, ...uniqueNewItems],
          page: result.page,
          total: result.total,
          totalPages: result.totalPages,
          isLoadingMore: false,
          loadMoreError: null,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;

      if (_requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          currentUserId != requestUserId) {
        return;
      }

      final latestState = state.value;
      if (latestState != null) {
        state = AsyncValue.data(
          latestState.copyWith(
            isLoadingMore: false,
            loadMoreError: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> submitReview({
    required int rating,
    String? title,
    String? comment,
  }) async {
    final currentState = state.value;
    if (currentState == null || currentState.isSubmitting) return;

    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) return;

    state = AsyncValue.data(currentState.copyWith(isSubmitting: true));

    try {
      final repository = ProductRepository(ref.read(dioClientProvider));
      await repository.createProductReview(
        productId,
        rating: rating,
        title: title,
        comment: comment,
      );

      _requestRevision++;
      ref.invalidateSelf();
      await future;
    } catch (e) {
      if (ref.mounted && state.value != null) {
        state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      }
      rethrow;
    }
  }

  Future<void> updateReview(
    String reviewId, {
    int? rating,
    String? title,
    String? comment,
  }) async {
    final currentState = state.value;
    if (currentState == null || currentState.isSubmitting) return;

    state = AsyncValue.data(currentState.copyWith(isSubmitting: true));

    try {
      final repository = ProductRepository(ref.read(dioClientProvider));
      await repository.updateProductReview(
        productId,
        reviewId,
        rating: rating,
        title: title,
        comment: comment,
      );

      _requestRevision++;
      ref.invalidateSelf();
      await future;
    } catch (e) {
      if (ref.mounted && state.value != null) {
        state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      }
      rethrow;
    }
  }

  Future<void> deleteReview(String reviewId) async {
    final currentState = state.value;
    if (currentState == null || currentState.isSubmitting) return;

    state = AsyncValue.data(currentState.copyWith(isSubmitting: true));

    try {
      final repository = ProductRepository(ref.read(dioClientProvider));
      await repository.deleteProductReview(productId, reviewId);

      _requestRevision++;
      ref.invalidateSelf();
      await future;
    } catch (e) {
      if (ref.mounted && state.value != null) {
        state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    _requestRevision++;
    ref.invalidateSelf();
    await future;
  }
}
