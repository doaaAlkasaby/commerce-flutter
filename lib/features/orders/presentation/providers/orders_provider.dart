import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import '../../data/orders_repository.dart';
import '../../models/order_model.dart';

part 'orders_provider.g.dart';

class PaginatedOrdersState {
  final List<OrderModel> items;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final String? loadMoreError;

  const PaginatedOrdersState({
    required this.items,
    required this.page,
    required this.totalPages,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  bool get hasMore => page < totalPages;

  PaginatedOrdersState copyWith({
    List<OrderModel>? items,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    String? loadMoreError,
  }) {
    return PaginatedOrdersState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

@Riverpod(keepAlive: true)
OrdersRepository ordersRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return OrdersRepository(dio);
}

@riverpod
class MyOrdersController extends _$MyOrdersController {
  int _requestRevision = 0;

  @override
  Future<PaginatedOrdersState> build() async {
    _requestRevision++;
    final currentRev = _requestRevision;

    final userAsync = ref.watch(currentUserProvider);
    final token = ref.watch(authTokenProvider);
    final requestTenantSlug = ref.watch(selectedTenantSlugProvider);
    final user = userAsync.value;

    // Suppress HTTP requests while currentUserProvider is loading or unauthenticated
    if (userAsync.isLoading || user == null || token == null || token.isEmpty) {
      return const PaginatedOrdersState(items: [], page: 1, totalPages: 1);
    }

    final requestUserId = user.id;
    final repository = ref.watch(ordersRepositoryProvider);
    final filter = ref.watch(orderFilterProvider);

    final res = await repository.getMyOrders(
      page: 1,
      limit: 20,
      status: filter != 'All' ? filter : null,
    );

    if (!ref.mounted) {
      return const PaginatedOrdersState(items: [], page: 1, totalPages: 1);
    }

    final currentUserId = ref.read(currentUserProvider).value?.id;
    if (_requestRevision != currentRev ||
        ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
        ref.read(authTokenProvider) != token ||
        currentUserId != requestUserId) {
      return const PaginatedOrdersState(items: [], page: 1, totalPages: 1);
    }

    return PaginatedOrdersState(
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

    final currentRev = _requestRevision;
    final requestTenantSlug = ref.read(selectedTenantSlugProvider);
    final requestToken = ref.read(authTokenProvider);
    final requestUserId = ref.read(currentUserProvider).value?.id;

    state = AsyncValue.data(
      currentState.copyWith(isLoadingMore: true, loadMoreError: null),
    );

    try {
      final repository = ref.read(ordersRepositoryProvider);
      final filter = ref.read(orderFilterProvider);
      final nextPage = currentState.page + 1;

      final res = await repository.getMyOrders(
        page: nextPage,
        limit: 20,
        status: filter != 'All' ? filter : null,
      );

      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;
      if (_requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          ref.read(authTokenProvider) != requestToken ||
          currentUserId != requestUserId) {
        return;
      }

      final existingIds = currentState.items.map((i) => i.id).toSet();
      final newUniqueItems = res.items
          .where((i) => !existingIds.contains(i.id))
          .toList();

      state = AsyncValue.data(
        currentState.copyWith(
          items: [...currentState.items, ...newUniqueItems],
          page: res.pagination.page,
          totalPages: res.pagination.totalPages,
          isLoadingMore: false,
          loadMoreError: null,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;
      if (_requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          ref.read(authTokenProvider) != requestToken ||
          currentUserId != requestUserId) {
        return;
      }

      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          loadMoreError: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() async {
    _requestRevision++;
    ref.invalidateSelf();
    await future;
  }
}

final myOrdersProvider = myOrdersControllerProvider;

@riverpod
Future<OrderModel?> orderDetails(Ref ref, String orderId) async {
  final userAsync = ref.watch(currentUserProvider);
  final token = ref.watch(authTokenProvider);
  final requestTenantSlug = ref.watch(selectedTenantSlugProvider);
  final user = userAsync.value;

  if (userAsync.isLoading || user == null || token == null || token.isEmpty) {
    return null;
  }

  final requestUserId = user.id;
  final repository = ref.watch(ordersRepositoryProvider);
  final order = await repository.getOrderById(orderId);

  if (!ref.mounted) return null;

  final currentUserId = ref.read(currentUserProvider).value?.id;
  if (ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
      ref.read(authTokenProvider) != token ||
      currentUserId != requestUserId) {
    return null;
  }

  return order;
}

@Riverpod(keepAlive: true)
class OrderFilterNotifier extends _$OrderFilterNotifier {
  @override
  String build() => 'All';

  void setFilter(String filter) {
    state = filter;
  }
}
