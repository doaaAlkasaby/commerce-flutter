import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/favorites/data/favorites_repository.dart';

part 'favorites_provider.g.dart';

@Riverpod(keepAlive: true)
FavoritesRepository favoritesRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return FavoritesRepository(dio);
}

class WishlistStateData {
  final String wishlistId;
  final List<WishlistItemModel> items;
  final Set<String> favoriteProductIds;
  final Set<String> pendingProductIds;

  const WishlistStateData({
    required this.wishlistId,
    required this.items,
    required this.favoriteProductIds,
    this.pendingProductIds = const {},
  });

  bool isFavorite(String productId) => favoriteProductIds.contains(productId);
  bool isPending(String productId) => pendingProductIds.contains(productId);

  WishlistStateData copyWith({
    String? wishlistId,
    List<WishlistItemModel>? items,
    Set<String>? favoriteProductIds,
    Set<String>? pendingProductIds,
  }) {
    return WishlistStateData(
      wishlistId: wishlistId ?? this.wishlistId,
      items: items ?? this.items,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      pendingProductIds: pendingProductIds ?? this.pendingProductIds,
    );
  }
}

@riverpod
class WishlistController extends _$WishlistController {
  int _requestRevision = 0;

  @override
  Future<WishlistStateData> build() async {
    _requestRevision++;
    final currentRev = _requestRevision;

    final userAsync = ref.watch(currentUserProvider);
    final token = ref.watch(authTokenProvider);
    final requestTenantSlug = ref.watch(selectedTenantSlugProvider);
    final user = userAsync.value;

    if (userAsync.isLoading || user == null || token == null || token.isEmpty) {
      return const WishlistStateData(
        wishlistId: '',
        items: [],
        favoriteProductIds: {},
      );
    }

    final requestUserId = user.id;
    final repository = ref.watch(favoritesRepositoryProvider);
    final wishlist = await repository.getWishlist();

    if (!ref.mounted) {
      return const WishlistStateData(
        wishlistId: '',
        items: [],
        favoriteProductIds: {},
      );
    }

    final currentUserId = ref.read(currentUserProvider).value?.id;

    if (_requestRevision != currentRev ||
        ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
        ref.read(authTokenProvider) != token ||
        currentUserId != requestUserId) {
      return const WishlistStateData(
        wishlistId: '',
        items: [],
        favoriteProductIds: {},
      );
    }

    final favoriteIds = wishlist.items.map((i) => i.product.id).toSet();

    return WishlistStateData(
      wishlistId: wishlist.id,
      items: wishlist.items,
      favoriteProductIds: favoriteIds,
    );
  }

  Future<void> toggleFavorite(String productId) async {
    final token = ref.read(authTokenProvider);
    final user = ref.read(currentUserProvider).value;
    if (token == null || token.isEmpty || user == null) return;

    final currentState = state.value;
    if (currentState == null || currentState.isPending(productId)) return;

    final currentRev = _requestRevision;
    final requestTenantSlug = ref.read(selectedTenantSlugProvider);
    final requestUserId = user.id;

    final isCurrentlyFavorite = currentState.isFavorite(productId);

    // Optimistic toggle
    final updatedFavorites = Set<String>.from(currentState.favoriteProductIds);
    if (isCurrentlyFavorite) {
      updatedFavorites.remove(productId);
    } else {
      updatedFavorites.add(productId);
    }

    final updatedPending = Set<String>.from(currentState.pendingProductIds)
      ..add(productId);

    state = AsyncValue.data(
      currentState.copyWith(
        favoriteProductIds: updatedFavorites,
        pendingProductIds: updatedPending,
      ),
    );

    try {
      final repository = ref.read(favoritesRepositoryProvider);
      if (isCurrentlyFavorite) {
        await repository.removeFromWishlist(productId);
      } else {
        await repository.addToWishlist(productId);
      }

      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;

      if (_requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          ref.read(authTokenProvider) != token ||
          currentUserId != requestUserId) {
        return;
      }

      // Re-fetch wishlist items to keep full list synchronized
      final freshWishlist = await repository.getWishlist();

      if (!ref.mounted) return;

      final latestUserId = ref.read(currentUserProvider).value?.id;

      if (_requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          ref.read(authTokenProvider) != token ||
          latestUserId != requestUserId) {
        return;
      }

      final freshIds = freshWishlist.items.map((i) => i.product.id).toSet();
      final latestState = state.value;
      final finalPending = Set<String>.from(
        latestState?.pendingProductIds ?? {},
      )..remove(productId);

      // Deterministic concurrent mutation reconciliation:
      // Preserve optimistic favorite status of all OTHER pending products!
      final mergedFavorites = Set<String>.from(freshIds);
      if (latestState != null) {
        for (final pendingId in finalPending) {
          if (latestState.isFavorite(pendingId)) {
            mergedFavorites.add(pendingId);
          } else {
            mergedFavorites.remove(pendingId);
          }
        }
      }

      state = AsyncValue.data(
        WishlistStateData(
          wishlistId: freshWishlist.id,
          items: freshWishlist.items,
          favoriteProductIds: mergedFavorites,
          pendingProductIds: finalPending,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;

      final currentUserId = ref.read(currentUserProvider).value?.id;

      if (_requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          ref.read(authTokenProvider) != token ||
          currentUserId != requestUserId) {
        return;
      }

      // Rollback only the affected product ID
      final rollbackFavorites = Set<String>.from(
        state.value?.favoriteProductIds ?? {},
      );
      if (isCurrentlyFavorite) {
        rollbackFavorites.add(productId);
      } else {
        rollbackFavorites.remove(productId);
      }

      final finalPending = Set<String>.from(
        state.value?.pendingProductIds ?? {},
      )..remove(productId);

      state = AsyncValue.data(
        currentState.copyWith(
          favoriteProductIds: rollbackFavorites,
          pendingProductIds: finalPending,
        ),
      );

      rethrow;
    }
  }

  bool isFavorite(String productId) {
    return state.value?.isFavorite(productId) ?? false;
  }

  Future<void> refresh() async {
    _requestRevision++;
    ref.invalidateSelf();
    await future;
  }
}
