import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import '../../data/special_orders_repository.dart';
import '../../models/confirmed_special_order_model.dart';
import '../../models/special_order_request_model.dart';

part 'special_orders_provider.g.dart';

@Riverpod(keepAlive: true)
SpecialOrdersRepository specialOrdersRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return SpecialOrdersRepository(dio);
}

class PaginatedRequestsState {
  final List<SpecialOrderRequestModel> items;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final String? loadMoreError;

  const PaginatedRequestsState({
    required this.items,
    required this.page,
    required this.totalPages,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  bool get hasMore => page < totalPages;

  PaginatedRequestsState copyWith({
    List<SpecialOrderRequestModel>? items,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    String? loadMoreError,
  }) {
    return PaginatedRequestsState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

class PaginatedConfirmedOrdersState {
  final List<ConfirmedSpecialOrderModel> items;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final String? loadMoreError;

  const PaginatedConfirmedOrdersState({
    required this.items,
    required this.page,
    required this.totalPages,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  bool get hasMore => page < totalPages;

  PaginatedConfirmedOrdersState copyWith({
    List<ConfirmedSpecialOrderModel>? items,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    String? loadMoreError,
  }) {
    return PaginatedConfirmedOrdersState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

@riverpod
class MySpecialOrdersRequestsController
    extends _$MySpecialOrdersRequestsController {
  int _requestRevision = 0;

  @override
  Future<PaginatedRequestsState> build() async {
    _requestRevision++;
    final currentRev = _requestRevision;

    final userAsync = ref.watch(currentUserProvider);
    final token = ref.watch(authTokenProvider);
    final requestTenantSlug = ref.watch(selectedTenantSlugProvider);
    final user = userAsync.value;

    if (userAsync.isLoading || user == null || token == null || token.isEmpty) {
      return const PaginatedRequestsState(items: [], page: 1, totalPages: 1);
    }

    final requestUserId = user.id;
    final repository = ref.watch(specialOrdersRepositoryProvider);

    final res = await repository.getMyRequests(page: 1, limit: 20);

    if (!ref.mounted) {
      return const PaginatedRequestsState(items: [], page: 1, totalPages: 1);
    }

    final currentUserId = ref.read(currentUserProvider).value?.id;
    if (_requestRevision != currentRev ||
        ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
        ref.read(authTokenProvider) != token ||
        currentUserId != requestUserId) {
      return const PaginatedRequestsState(items: [], page: 1, totalPages: 1);
    }

    return PaginatedRequestsState(
      items: res.items,
      page: res.pagination.page,
      totalPages: res.pagination.totalPages,
    );
  }

  Future<void> loadNextPage() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final repository = ref.read(specialOrdersRepositoryProvider);
      final res = await repository.getMyRequests(
        page: currentState.page + 1,
        limit: 20,
      );

      if (!ref.mounted) return;

      final existingIds = currentState.items.map((e) => e.id).toSet();
      final newItems =
          res.items.where((e) => !existingIds.contains(e.id)).toList();

      state = AsyncValue.data(
        currentState.copyWith(
          items: [...currentState.items, ...newItems],
          page: res.pagination.page,
          totalPages: res.pagination.totalPages,
          isLoadingMore: false,
          loadMoreError: null,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          loadMoreError: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
class MyConfirmedSpecialOrdersController
    extends _$MyConfirmedSpecialOrdersController {
  int _requestRevision = 0;

  @override
  Future<PaginatedConfirmedOrdersState> build() async {
    _requestRevision++;
    final currentRev = _requestRevision;

    final userAsync = ref.watch(currentUserProvider);
    final token = ref.watch(authTokenProvider);
    final requestTenantSlug = ref.watch(selectedTenantSlugProvider);
    final user = userAsync.value;

    if (userAsync.isLoading || user == null || token == null || token.isEmpty) {
      return const PaginatedConfirmedOrdersState(items: [], page: 1, totalPages: 1);
    }

    final requestUserId = user.id;
    final repository = ref.watch(specialOrdersRepositoryProvider);

    final res = await repository.getMyConfirmedOrders(page: 1, limit: 20);

    if (!ref.mounted) {
      return const PaginatedConfirmedOrdersState(items: [], page: 1, totalPages: 1);
    }

    final currentUserId = ref.read(currentUserProvider).value?.id;
    if (_requestRevision != currentRev ||
        ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
        ref.read(authTokenProvider) != token ||
        currentUserId != requestUserId) {
      return const PaginatedConfirmedOrdersState(items: [], page: 1, totalPages: 1);
    }

    return PaginatedConfirmedOrdersState(
      items: res.items,
      page: res.pagination.page,
      totalPages: res.pagination.totalPages,
    );
  }

  Future<void> loadNextPage() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final repository = ref.read(specialOrdersRepositoryProvider);
      final res = await repository.getMyConfirmedOrders(
        page: currentState.page + 1,
        limit: 20,
      );

      if (!ref.mounted) return;

      final existingIds = currentState.items.map((e) => e.id).toSet();
      final newItems =
          res.items.where((e) => !existingIds.contains(e.id)).toList();

      state = AsyncValue.data(
        currentState.copyWith(
          items: [...currentState.items, ...newItems],
          page: res.pagination.page,
          totalPages: res.pagination.totalPages,
          isLoadingMore: false,
          loadMoreError: null,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          loadMoreError: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
Future<SpecialOrderRequestModel?> specialOrderRequestDetail(
  Ref ref,
  String id,
) async {
  final repository = ref.watch(specialOrdersRepositoryProvider);
  return repository.getRequestById(id);
}

@riverpod
Future<ConfirmedSpecialOrderModel?> confirmedSpecialOrderDetail(
  Ref ref,
  String id,
) async {
  final repository = ref.watch(specialOrdersRepositoryProvider);
  return repository.getConfirmedOrderById(id);
}
