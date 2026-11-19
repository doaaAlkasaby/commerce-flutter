import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/notifications/data/notifications_repository.dart';
import 'package:ecommerce/features/notifications/models/notification_model.dart';

part 'notifications_provider.g.dart';

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return NotificationsRepository(dio);
}

class PaginatedNotificationsState {
  final List<NotificationModel> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final int unreadCount;
  final bool isLoadingMore;
  final String? loadMoreError;
  final Set<String> pendingNotificationIds;

  const PaginatedNotificationsState({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.unreadCount,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.pendingNotificationIds = const {},
  });

  bool get hasMore => page < totalPages;
  bool isPending(String id) => pendingNotificationIds.contains(id);

  PaginatedNotificationsState copyWith({
    List<NotificationModel>? items,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    int? unreadCount,
    bool? isLoadingMore,
    String? loadMoreError,
    Set<String>? pendingNotificationIds,
  }) {
    return PaginatedNotificationsState(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError,
      pendingNotificationIds:
          pendingNotificationIds ?? this.pendingNotificationIds,
    );
  }
}

@riverpod
class NotificationController extends _$NotificationController {
  int _requestRevision = 0;

  @override
  Future<PaginatedNotificationsState> build() async {
    _requestRevision++;
    final currentRev = _requestRevision;

    final userAsync = ref.watch(currentUserProvider);
    final token = ref.watch(authTokenProvider);
    final user = userAsync.value;

    if (userAsync.isLoading || user == null || token == null || token.isEmpty) {
      return const PaginatedNotificationsState(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 1,
        unreadCount: 0,
      );
    }

    final requestUserId = user.id;
    final repository = ref.watch(notificationsRepositoryProvider);
    final result = await repository.getPaginatedNotifications(
      page: 1,
      limit: 20,
    );

    if (!ref.mounted) {
      return const PaginatedNotificationsState(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 1,
        unreadCount: 0,
      );
    }

    final currentUserId = ref.read(currentUserProvider).value?.id;
    if (_requestRevision != currentRev ||
        ref.read(authTokenProvider) != token ||
        currentUserId != requestUserId) {
      return const PaginatedNotificationsState(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 1,
        unreadCount: 0,
      );
    }

    return PaginatedNotificationsState(
      items: result.items,
      page: result.page,
      limit: result.limit,
      total: result.total,
      totalPages: result.totalPages,
      unreadCount: result.unreadCount,
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
    final token = ref.read(authTokenProvider);
    final user = ref.read(currentUserProvider).value;
    if (token == null || user == null) return;

    final requestUserId = user.id;

    state = AsyncValue.data(
      currentState.copyWith(isLoadingMore: true, loadMoreError: null),
    );

    try {
      final nextPage = currentState.page + 1;
      final repository = ref.read(notificationsRepositoryProvider);
      final result = await repository.getPaginatedNotifications(
        page: nextPage,
        limit: currentState.limit,
      );

      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;
      if (_requestRevision != currentRev ||
          ref.read(authTokenProvider) != token ||
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
          unreadCount: result.unreadCount,
          isLoadingMore: false,
          loadMoreError: null,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;
      if (_requestRevision != currentRev ||
          ref.read(authTokenProvider) != token ||
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

  Future<void> markAsRead(String id) async {
    final currentState = state.value;
    if (currentState == null || currentState.isPending(id)) return;

    final token = ref.read(authTokenProvider);
    final user = ref.read(currentUserProvider).value;
    if (token == null || user == null) return;

    final index = currentState.items.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = currentState.items[index];
    if (item.isRead) return; // Ignore if already read

    final currentRev = _requestRevision;
    final requestUserId = user.id;

    final updatedItems = List<NotificationModel>.from(currentState.items);
    updatedItems[index] = item.copyWith(isRead: true);
    final newUnreadCount = max(0, currentState.unreadCount - 1);
    final updatedPending = Set<String>.from(currentState.pendingNotificationIds)
      ..add(id);

    state = AsyncValue.data(
      currentState.copyWith(
        items: updatedItems,
        unreadCount: newUnreadCount,
        pendingNotificationIds: updatedPending,
      ),
    );

    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.markAsRead(id);

      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;
      if (_requestRevision != currentRev ||
          ref.read(authTokenProvider) != token ||
          currentUserId != requestUserId) {
        return;
      }

      final finalPending = Set<String>.from(
        state.value?.pendingNotificationIds ?? {},
      )..remove(id);
      state = AsyncValue.data(
        state.value!.copyWith(pendingNotificationIds: finalPending),
      );
    } catch (e) {
      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;
      if (_requestRevision != currentRev ||
          ref.read(authTokenProvider) != token ||
          currentUserId != requestUserId) {
        return;
      }

      // Rollback item and count using latest state
      final latestState = state.value;
      final rollbackItems = List<NotificationModel>.from(
        latestState?.items ?? [],
      );
      final rollbackIndex = rollbackItems.indexWhere((i) => i.id == id);
      if (rollbackIndex != -1) {
        rollbackItems[rollbackIndex] = item;
      }

      final finalPending = Set<String>.from(
        latestState?.pendingNotificationIds ?? {},
      )..remove(id);
      final rollbackUnreadCount = item.isRead
          ? (latestState?.unreadCount ?? currentState.unreadCount)
          : (latestState != null
                ? latestState.unreadCount + 1
                : currentState.unreadCount);

      state = AsyncValue.data(
        (latestState ?? currentState).copyWith(
          items: rollbackItems,
          unreadCount: rollbackUnreadCount,
          pendingNotificationIds: finalPending,
        ),
      );

      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    final currentState = state.value;
    if (currentState == null) return;

    final token = ref.read(authTokenProvider);
    final user = ref.read(currentUserProvider).value;
    if (token == null || user == null) return;

    final currentRev = _requestRevision;
    final requestUserId = user.id;

    final updatedItems = currentState.items
        .map((i) => i.copyWith(isRead: true))
        .toList();

    state = AsyncValue.data(
      currentState.copyWith(items: updatedItems, unreadCount: 0),
    );

    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.markAllAsRead();

      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;
      if (_requestRevision != currentRev ||
          ref.read(authTokenProvider) != token ||
          currentUserId != requestUserId) {
        return;
      }
    } catch (e) {
      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;
      if (_requestRevision != currentRev ||
          ref.read(authTokenProvider) != token ||
          currentUserId != requestUserId) {
        return;
      }

      // Rollback
      state = AsyncValue.data(currentState);
      rethrow;
    }
  }

  Future<void> deleteNotification(String id) async {
    final currentState = state.value;
    if (currentState == null || currentState.isPending(id)) return;

    final token = ref.read(authTokenProvider);
    final user = ref.read(currentUserProvider).value;
    if (token == null || user == null) return;

    final index = currentState.items.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = currentState.items[index];
    final currentRev = _requestRevision;
    final requestUserId = user.id;

    final updatedItems = List<NotificationModel>.from(currentState.items)
      ..removeAt(index);
    final newUnreadCount = item.isRead
        ? currentState.unreadCount
        : max(0, currentState.unreadCount - 1);
    final updatedPending = Set<String>.from(currentState.pendingNotificationIds)
      ..add(id);

    state = AsyncValue.data(
      currentState.copyWith(
        items: updatedItems,
        unreadCount: newUnreadCount,
        pendingNotificationIds: updatedPending,
      ),
    );

    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.deleteNotification(id);

      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;
      if (_requestRevision != currentRev ||
          ref.read(authTokenProvider) != token ||
          currentUserId != requestUserId) {
        return;
      }

      final finalPending = Set<String>.from(
        state.value?.pendingNotificationIds ?? {},
      )..remove(id);
      state = AsyncValue.data(
        state.value!.copyWith(pendingNotificationIds: finalPending),
      );
    } catch (e) {
      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;
      if (_requestRevision != currentRev ||
          ref.read(authTokenProvider) != token ||
          currentUserId != requestUserId) {
        return;
      }

      // Rollback
      final latestState = state.value;
      final finalPending = Set<String>.from(
        latestState?.pendingNotificationIds ?? {},
      )..remove(id);

      state = AsyncValue.data(
        currentState.copyWith(pendingNotificationIds: finalPending),
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    _requestRevision++;
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
int unreadNotificationCount(Ref ref) {
  final notifState = ref.watch(notificationControllerProvider).value;
  return notifState?.unreadCount ?? 0;
}
