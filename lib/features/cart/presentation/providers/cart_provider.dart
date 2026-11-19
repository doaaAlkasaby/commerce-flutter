import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import '../../data/cart_repository.dart';
import '../../models/cart_model.dart';

part 'cart_provider.g.dart';

@Riverpod(keepAlive: true)
CartRepository cartRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return CartRepository(dio);
}

@Riverpod(keepAlive: true)
class CartNotifier extends _$CartNotifier {
  @override
  Future<CartModel> build() async {
    final token = ref.watch(authTokenProvider);
    if (token == null || token.isEmpty) {
      return const CartModel.empty();
    }

    final repo = ref.watch(cartRepositoryProvider);
    return repo.getCart();
  }

  Future<void> refreshCart() async {
    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      state = const AsyncValue.data(CartModel.empty());
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(cartRepositoryProvider).getCart(),
    );
  }

  Future<void> addItem(String variantId, int quantity) async {
    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      throw StateError('Authentication required');
    }

    final repo = ref.read(cartRepositoryProvider);
    try {
      final updatedCart = await repo.addToCart(variantId, quantity);
      state = AsyncValue.data(updatedCart);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuantity(String variantId, int quantity) async {
    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      throw StateError('Authentication required');
    }

    final repo = ref.read(cartRepositoryProvider);
    try {
      final updatedCart = await repo.updateItemQuantity(variantId, quantity);
      state = AsyncValue.data(updatedCart);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteItem(String variantId) async {
    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      throw StateError('Authentication required');
    }

    final repo = ref.read(cartRepositoryProvider);
    try {
      final updatedCart = await repo.removeItem(variantId);
      state = AsyncValue.data(updatedCart);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCart() async {
    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      state = const AsyncValue.data(CartModel.empty());
      return;
    }

    final repo = ref.read(cartRepositoryProvider);
    try {
      final updatedCart = await repo.clearCart();
      state = AsyncValue.data(updatedCart);
    } catch (e) {
      rethrow;
    }
  }
}
